module ui

import gx

// Initially inside ui_linux_c.v
fn word_wrap_to_lines(s string, max_line_length int) []string {
	words := s.split(' ')
	mut line := []string{}
	mut line_len := 0
	mut text_lines := []string{}
	for word in words {
		if line_len + word.len < max_line_length {
			line << word
			line_len += word.len + 1
			continue
		} else {
			text_lines << line.join(' ')
			line = []
			line_len = 0
		}
	}
	if line_len > 0 {
		text_lines << line.join(' ')
	}
	return text_lines
}

fn word_wrap_text_to_lines(s string, max_line_length int) []string {
	lines := s.split('\n')
	mut word_wrapped_lines := []string{}
	for line in lines {
		word_wrapped_lines << word_wrap_to_lines(line, max_line_length)
	}
	return word_wrapped_lines
}

fn text_lines_size(lines []string, ui &UI) (int, int) {
	mut width, mut height := 0, 0
	mut tw, mut th := 0, 0
	for line in lines {
		tw, th = ui.gg.text_size(line)
		// println("tt line: $line -> ($tw, $th)")
		if tw > width {
			width = tw
		}
		height += th
	}
	return width, height
}

//=== Tooltip ===//

// 1) From now, consider that widgets having tooltip are always on top and without intersecting other widgets.
// As a first try, this makes sense for visible widgets.
// Rmk: if we introduce hover event, this would be to consider.
// 2) It is assumed that there is only one tooltip drawn at the same time
// Rmk: popups are a bit different.
// 3) This is also devoted to simple widgets needing a quick system of help.

const (
	tooltip_margin = 5
)

struct TextLines {
mut:
	lines     []string
	x         int
	y         int
	width     int
	height    int
	text_cfg  gx.TextCfg
	text_size f64
}

struct Tooltip {
	TextLines
mut:
	id       string
	active   bool
	color    gx.Color = gx.black
	bg_color gx.Color = gx.Color{255, 220, 127, 220}
	side     Side     = .top
	ui       &UI      = 0
}

[unsafe]
pub fn (t &Tooltip) free() {
	unsafe {
		for line in t.lines {
			line.free()
		}
		t.lines.free()
		t.id.free()
	}
	$if free ? {
		println('\tTooltip -> freed')
	}
}

pub fn start_tooltip(mut w Widget, id string, msg string, wui &UI) {
	mut win := wui.window
	win.tooltip.id = id
	if !win.tooltip.active { // only once
		// println("start tooltip $win.tooltip.id: $msg")
		if win.tooltip.ui == 0 {
			win.tooltip.ui = wui
		}

		win.tooltip.lines = word_wrap_text_to_lines(msg, 70)
		win.tooltip.width, win.tooltip.height = text_lines_size(win.tooltip.lines, wui)

		win.tooltip.width += 2 * ui.tooltip_margin
		win.tooltip.height += 2 * ui.tooltip_margin

		set_text_cfg_color(mut win.tooltip, win.tooltip.color)
		set_text_cfg_style(mut win.tooltip, true, true, false)

		win.tooltip.active = true
		width, _ := w.size()
		match win.tooltip.side {
			// TODO: the other sides
			.top {
				win.tooltip.x = w.x + w.offset_x + width / 2 - win.tooltip.width / 2
				win.tooltip.y = w.y + w.offset_y - win.tooltip.height - ui.tooltip_margin
			}
			else {}
		}
	}
}

fn stop_tooltip(w Widget, id string, wui &UI) {
	mut win := wui.window
	if win.tooltip.active && win.tooltip.id == id {
		// println("tooltip stop $win.tooltip.id")
		win.tooltip.active = false
	}
}

fn draw_tooltip(win Window) {
	if win.tooltip.active {
		// TODO:  add triangle to connect the rectangle
		// win.ui.gg.draw_rect(win.tooltip.x, win.tooltip.y, win.tooltip.width, win.tooltip.height,
		// gx.yellow)
		win.ui.gg.draw_rounded_rect(win.tooltip.x, win.tooltip.y, win.tooltip.width, win.tooltip.height,
			.3, win.tooltip.bg_color)
		draw_text_lines(win.tooltip, win.tooltip.x + ui.tooltip_margin, win.tooltip.y,
			win.tooltip.lines)
	}
}

//=== Basic Message Dialog ===/
// Before sokol deals with multiple window (soon)

fn (mut win Window) add_message_dialog() {
	mut dlg := column({
		id: '_msg_dlg_col'
		alignment: .center
		widths: compact
		heights: compact
		spacing: 10
		margin: Margin{5, 5, 5, 5}
		bg_color: gx.Color{140, 210, 240, 100}
		bg_radius: .3
	}, [
		label(id: '_msg_dlg_lab', text: ' Hello World'),
		button(id: '_msg_dlg_btn', text: 'OK', width: 100, radius: .3, onclick: message_dialog_click),
	])
	win.children << dlg
	dlg.set_visible(false)
}

fn message_dialog_click(app voidptr, b &Button) {
	mut dlg := b.ui.window.stack('_msg_dlg_col')
	dlg.set_visible(false)
}

pub fn (win &Window) message(s string) {
	if win.native_message {
		message_box(s)
	} else {
		mut dlg := win.stack('_msg_dlg_col')
		mut msg := win.label('_msg_dlg_lab')
		msg.set_text(s)
		mut tw, mut th := text_lines_size(s.split('\n'), win.ui)
		msg.propose_size(tw, th)
		if tw < 200 {
			tw = 200
		}
		th += 50
		println("msg: ($tw, $th) $s")
		dlg.propose_size(tw, th)
		ww, wh := win.size()
		dlg.set_pos(ww / 2 - tw / 2, wh / 2 - th / 2)
		dlg.update_layout()
		dlg.set_visible(true)
	}
}

/*
// Playing with Styled Text

struct TextChunk {
	text  string
	start int
	stop  int
	cfg   gx.TextCfg
}

pub struct TextContext {
	chunks []TextChunk
	colors map[string]gx.Color
	styles map[string]gx.TextCfg
}

struct TextView {
	x       int
	y       int
	width   int
	height  int
	context &TextContext
}


* default: {style: "", size: 10, color: black}

* start:

	- style: normal "", italic {i], bold {b], underline {u]
	- size: uint8 (ex: {12])
	- color: r,g,b,a or hexa (0x00000000) string lowercase (ex: {red])
	- font-family: string capitalized

- combined: {...|...|...]

end:

- idem with closing [...} or [...|...|...}
- empty [} means last opened


current:

custom style: blurr

stack of style operations:

{b] {t] [b} [t}
*/
