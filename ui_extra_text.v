module ui

import gx

const (
	word_wrap_id = '\n'
)

pub fn text_x_from_pos<T>(w &T, text string, x int) int {
	ustr := text.runes()
	if x > ustr.len {
		// println('warning: text_x_from_pos $x > $ustr.len')
		x = ustr.len
	}
	left := ustr[..x].string()
	return text_width(w, left)
}

pub fn text_xminmax_from_pos<T>(w &T, text string, x1 int, x2 int) (int, int) {
	ustr := text.runes()
	mut x_min, mut x_max := if x1 < x2 { x1, x2 } else { x2, x1 }
	if x_max > ustr.len {
		// println('warning: text_xminmax_from_pos $x_max > $ustr.len')
		x_max = ustr.len
	}
	if x_min < 0 {
		// println('warning: text_xminmax_from_pos $x_min < 0')
		x_min = 0
	}
	// println("xminmax: ${ustr.len} $x_min $x_max")
	left := ustr[..x_min].string()
	right := ustr[x_max..].string()
	ww, lw, rw := text_width(w, text), text_width(w, left), text_width(w, right)
	return lw, ww - lw - rw
}

pub fn text_pos_from_x<T>(w &T, text string, x int) int {
	if x <= 0 {
		return 0
	}
	mut prev_width := 0
	ustr := text.runes()
	for i in 0 .. ustr.len {
		width := text_width(w, ustr[..i].string())
		width2 := if i < ustr.len { text_width(w, ustr[..(i + 1)].string()) } else { width }
		if (prev_width + width) / 2 <= x && x <= (width + width2) / 2 {
			return i
		}
		prev_width = width
	}
	return ustr.len
}

fn word_wrap_to_line_by_width<T>(w &T, s string, max_line_width int) ([]string, []int) {
	words := s.split(' ')
	mut line := ''
	mut line_width := 0
	mut text_lines := []string{}
	mut word_wrap, mut cpt := []int{}, 0
	for i, word in words {
		if i == 0 { // at least the first
			line = word
			line_width = text_width(w, word)
		} else {
			word_width := text_width(w, ' ' + word)
			if line_width + word_width < max_line_width {
				line += ' ' + word
				line_width += word_width
			} else {
				text_lines << line
				word_wrap << cpt
				line = word
				line_width = word_width
				cpt++
			}
		}
	}
	if line_width > 0 {
		text_lines << line
		word_wrap << cpt
	}
	return text_lines, word_wrap
}

fn word_wrap_text_to_lines_by_width<T>(w &T, s string, max_line_width int) ([]string, []int) {
	lines := s.split('\n')
	mut word_wrapped_lines, mut word_wrap_ind := []string{}, []int{}
	for line in lines {
		ww_lines, ww_ind := word_wrap_to_line_by_width(w, line, max_line_width)
		word_wrapped_lines << ww_lines
		word_wrap_ind << ww_ind
	}
	// println('tl: $word_wrapped_lines ww: $word_wrap_ind')
	return word_wrapped_lines, word_wrap_ind
}

fn word_wrap_join(lines []string, ind []int) string {
	mut res := ''
	// println("lines: $lines, ind: $ind")
	for i, line in lines {
		sp := if i == 0 {
			''
		} else if ind[i] > 0 {
			' '
		} else {
			'\n'
		}
		res += sp + line
	}
	// println("res: $res")
	return res
}

// get text position from row i and column j
pub fn text_lines_pos_at(lines []string, i int, j int) int {
	mut pos := 0
	for k in 0 .. j {
		pos += lines[k].runes().len + 1 // +1 for \n or space
	}
	pos += i
	// println('text_lines_pos_at: ($i, $j) -> $pos ')
	return pos
}

// get row and column from text position
pub fn text_lines_row_column_at(lines []string, pos int) (int, int) {
	if pos == 0 {
		return 0, 0
	}
	mut j := 0
	mut total_len, mut ustr_len := 0, 0
	for line in lines {
		ustr_len = line.runes().len + 1
		total_len += ustr_len
		if pos > total_len {
			j++
		} else {
			total_len -= ustr_len
			break
		}
	}
	// println('text_lines_row_column_at: $pos -> ($pos - $total_len, $j)')
	return pos - total_len, j
}

// Initially inside ui_linux_c.v
fn word_wrap_to_lines(s string, max_line_length int) []string {
	words := s.split(' ')
	mut line := []string{}
	mut line_len := 0
	mut text_lines := []string{}
	for word in words {
		word_len := word.runes().len
		if line_len + word_len < max_line_length {
			line << word
			line_len += word_len + 1
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
	side     Side     = .right
	ui       &UI      = 0
}

struct TooltipMessage {
	text string
	side Side = .right
}

[unsafe]
pub fn (t &Tooltip) free() {
	unsafe {
		for line in t.lines {
			line.free()
		}
		t.lines.free()
		// t.id.free()
	}
	$if free ? {
		println('\tTooltip -> freed')
	}
}

[unsafe]
pub fn (t &TooltipMessage) free() {
	unsafe {
		t.text.free()
		// t.id.free()
	}
	$if free ? {
		println('\tTooltipMessage -> freed')
	}
}

pub fn start_tooltip(mut w Widget, id string, msg TooltipMessage, wui &UI) {
	mut win := wui.window
	win.tooltip.id = id
	if !win.tooltip.active { // only once
		// println("start tooltip $win.tooltip.id: $msg")
		if win.tooltip.ui == 0 {
			win.tooltip.ui = wui
		}

		win.tooltip.lines = word_wrap_text_to_lines(msg.text, 70)
		win.tooltip.width, win.tooltip.height = text_lines_size(win.tooltip.lines, wui)

		win.tooltip.width += 2 * ui.tooltip_margin
		win.tooltip.height += 2 * ui.tooltip_margin

		set_text_cfg_color(mut win.tooltip, win.tooltip.color)
		set_text_cfg_style(mut win.tooltip, true, true, false)

		win.tooltip.active = true
		width, height := w.size()
		match msg.side {
			// TODO: the other sides
			.top {
				win.tooltip.x = w.x + w.offset_x + width / 2 - win.tooltip.width / 2
				win.tooltip.y = w.y + w.offset_y - win.tooltip.height - ui.tooltip_margin
			}
			.right {
				win.tooltip.x = w.x + w.offset_x + width + ui.tooltip_margin
				win.tooltip.y = w.y + w.offset_y + height / 2 - win.tooltip.height / 2
			}
			else {}
		}
	}
}

fn stop_tooltip(id string, wui &UI) {
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

pub fn (mut w Window) append_tooltip(child Widget, tooltip TooltipMessage) {
	w.widgets_tooltip << child
	w.tooltips << tooltip
}

pub fn (w &Window) update_tooltip(e &MouseMoveEvent) {
	for i, mut child in w.widgets_tooltip {
		id := widget_id(*child)
		if !child.hidden {
			if child.point_inside(e.x, e.y) {
				start_tooltip(mut child, id, w.tooltips[i], w.ui)
			} else {
				stop_tooltip(id, w.ui)
			}
			if w.dragger.activated {
				stop_tooltip(id, w.ui)
			}
		}
	}
}

//=== Basic Message Dialog ===/
// Before sokol deals with multiple window (soon)

fn (mut win Window) add_message_dialog() {
	mut dlg := column(
		id: '_msg_dlg_col'
		alignment: .center
		widths: compact
		heights: compact
		spacing: 10
		margin: Margin{5, 5, 5, 5}
		bg_color: gx.Color{140, 210, 240, 100}
		bg_radius: .3
		children: [
			label(id: '_msg_dlg_lab', text: ' Hello World'),
			button(
				id: '_msg_dlg_btn'
				text: 'OK'
				width: 100
				radius: .3
				onclick: message_dialog_click
			),
		]
	)
	dlg.is_root_layout = false
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
		// println("msg: ($tw, $th) $s")
		dlg.propose_size(tw, th)
		ww, wh := win.size()
		dlg.set_pos(ww / 2 - tw / 2, wh / 2 - th / 2)
		dlg.set_visible(true)
		dlg.update_layout()
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
