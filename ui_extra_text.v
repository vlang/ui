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

fn word_wrapped_text(s string, max_line_length int) []string {
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
	id     string
	active bool
	side   Side = .top
	ui     &UI  = 0
}

pub fn start_tooltip(mut w Widget, id string, msg string, wui &UI) {
	mut win := wui.window
	win.tooltip.id = id
	if !win.tooltip.active { // only once
		// println("start tooltip $win.tooltip.id: $msg")
		if win.tooltip.ui == 0 {
			win.tooltip.ui = wui
		}

		win.tooltip.lines = word_wrapped_text(msg, 70)
		win.tooltip.width, win.tooltip.height = text_lines_size(win.tooltip.lines, wui)

		win.tooltip.width += 2 * ui.tooltip_margin
		win.tooltip.height += 2 * ui.tooltip_margin

		set_text_color(mut win.tooltip, gx.red)
		set_text_style(mut win.tooltip, true, true, false)

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
		win.ui.gg.draw_rect(win.tooltip.x, win.tooltip.y, win.tooltip.width, win.tooltip.height,
			gx.yellow)
		draw_text_lines(win.tooltip, win.tooltip.x + ui.tooltip_margin, win.tooltip.y,
			win.tooltip.lines)
	}
}


//=== Basic Message Box ===/

fn message_dialog_add(mut win Window) {
	mut lay := column({
		id: "_msg_dlg_col"
		alignment: .center
		margin: Margin{5, 5, 5, 5}
	}, [
		label(id: "_msg_dlg_lab",text: ' Hello World'),  
		button(id: "_msg_dlg_btn", text: 'OK', onclick: message_dialog_click),
	])
	win.children << lay
	lay.set_visible(false)
}

fn message_dialog_click(app voidptr, b &Button) {
	mut win := b.ui.window
	win.stack("_msg_dlg_col").set_visible(false)
}

fn message_dialog_run(s string, mut win Window) {
	win.stack("_msg_dlg_col").set_visible(true)
}


