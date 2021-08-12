module ui

import gx

// position (cursor_pos, sel_start, sel_end) set in the runes world
struct TextView {
pub mut:
	text       &string
	cursor_pos int
	sel_start  int
	sel_end    int
	// synchronised lines for the text (or maybe a part)
	tlv TextLinesView
	// textbox
	tb &TextBox // needed for textwidth and for is_wordwrap
}

// Structure to help for drawing text line by line and cursor update between lines
// Insertion and deletion would be made directly on TextView.text field and then synchronized
// on textlines except for cursor vertical motion
struct TextLinesView {
pub mut:
	lines        []string
	cursor_pos_i int
	cursor_pos_j int
	sel_start_j  int
	sel_start_i  int
	sel_end_i    int
	sel_end_j    int
}

pub fn (mut tv TextView) init(tb &TextBox) {
	tv.tb = tb
	tv.text = tb.text // delegate text from tb
	tv.update_lines()
	tv.cancel_selection()
	tv.sync_text_pos()
}

pub fn (tv &TextView) size() (int, int) {
	mut w, h := 0, textbox_padding_y * 2 + tv.tb.line_height * tv.tlv.lines.len
	for line in tv.tlv.lines {
		lw := text_width(tv.tb, line)
		if lw > w {
			w = lw
		}
	}
	w += textbox_padding_x * 2
	return w, h
}

pub fn (tv &TextView) info() {
	println('cursor: $tv.cursor_pos -> ($tv.tlv.cursor_pos_i, $tv.tlv.cursor_pos_j)')
	println('sel: ($tv.sel_start, $tv.sel_end) -> ($tv.tlv.sel_start_i, $tv.tlv.sel_start_j, $tv.tlv.sel_end_i, $tv.tlv.sel_end_j)')
}

pub fn (mut tv TextView) is_wordwrap() bool {
	return tv.tb.is_wordwrap
}

pub fn (mut tv TextView) set_wordwrap(state bool) {
	tv.tb.is_wordwrap = state
	tv.sync_text_pos()
	tv.update_lines()
	tv.sync_text_lines()
}

pub fn (mut tv TextView) switch_wordwrap() {
	tv.set_wordwrap(!tv.tb.is_wordwrap)
}

fn (tv &TextView) line(j int) string {
	mut jj := j
	if jj < 0 {
		jj = 0
	} else if jj == tv.tlv.lines.len {
		jj = tv.tlv.lines.len - 1
	}
	return tv.tlv.lines[jj]
}

fn (tv &TextView) current_line() string {
	return tv.tlv.lines[tv.tlv.cursor_pos_j]
}

fn (tv &TextView) sel_start_line() string {
	return tv.tlv.lines[tv.tlv.sel_start_j]
}

fn (tv &TextView) sel_end_line() string {
	return tv.tlv.lines[tv.tlv.sel_end_j]
}

fn (tv &TextView) is_sel_active() bool {
	// println("tv sel active: $tv.sel_end")
	return tv.tb.is_focused && tv.sel_end >= 0
}

fn (mut tv TextView) sync_text_pos() {
	tv.cursor_pos = tv.text_pos_at(tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j)
	if tv.tlv.sel_end_j == -1 {
		tv.sel_start = -1
		tv.sel_end = -1
	} else {
		tv.sel_start = tv.text_pos_at(tv.tlv.sel_start_i, tv.tlv.sel_start_j)
		tv.sel_end = tv.text_pos_at(tv.tlv.sel_end_i, tv.tlv.sel_end_j)
	}
}

fn (mut tv TextView) sync_text_lines() {
	tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j = tv.text_line_at(tv.cursor_pos)
	if tv.sel_end == -1 {
		tv.tlv.sel_start_i, tv.tlv.sel_start_j = -1, -1
		tv.tlv.sel_end_i, tv.tlv.sel_end_j = -1, -1
	} else {
		tv.tlv.sel_start_i, tv.tlv.sel_start_j = tv.text_line_at(tv.sel_start)
		tv.tlv.sel_end_i, tv.tlv.sel_end_j = tv.text_line_at(tv.sel_end)
	}
}

fn (mut tv TextView) update_lines() {
	if tv.is_wordwrap() {
		tv.word_wrap_text()
	} else {
		tv.tlv.lines = (*tv.text).split('\n')
	}
	// println(tv.tlv.lines)
	tv.sync_text_lines()
	if tv.tb.has_scrollview {
		scrollview_update(tv.tb)
	}
}

fn (mut tv TextView) draw_textlines() {
	tv.draw_selection()
	mut y := tv.tb.y + textbox_padding_y
	// println("draw_textlines: $tb.tv.tlv.lines")
	for line in tv.tlv.lines {
		draw_text(tv.tb, tv.tb.x + textbox_padding_x, y, line)
		y += tv.tb.line_height
	}
	// draw cursor
	if tv.tb.is_focused && !tv.tb.read_only && tv.tb.ui.show_cursor && !tv.is_sel_active() {
		tv.tb.ui.gg.draw_rect(tv.cursor_x(), tv.cursor_y(), 1, tv.tb.line_height, gx.black) // , gx.Black)
	}
}

fn (mut tv TextView) draw_selection() {
	if !tv.is_sel_active() {
		// println("return draw_sel")
		return
	}
	if tv.tlv.sel_start_j == tv.tlv.sel_end_j {
		sel_from, sel_width := text_xminmax_from_pos(tv.tb, tv.sel_start_line(), tv.tlv.sel_start_i,
			tv.tlv.sel_end_i)
		tv.tb.ui.gg.draw_rect(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y + textbox_padding_y +
			tv.tlv.sel_start_j * tv.tb.line_height, sel_width, tv.tb.line_height, selection_color)
	} else {
		start_i, end_i, start_j, end_j := tv.ordered_lines_selection()
		mut ustr := tv.line(start_j)
		mut sel_from, mut sel_width := text_xminmax_from_pos(tv.tb, ustr, start_i, ustr.len)
		tv.tb.ui.gg.draw_rect(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y + textbox_padding_y +
			start_j * tv.tb.line_height, sel_width, tv.tb.line_height, selection_color)
		if end_j - start_j > 1 {
			for j in (start_j + 1) .. end_j {
				ustr = tv.line(j)
				sel_from, sel_width = text_xminmax_from_pos(tv.tb, ustr, 0, ustr.runes().len)
				tv.tb.ui.gg.draw_rect(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y +
					textbox_padding_y + j * tv.tb.line_height, sel_width, tv.tb.line_height,
					selection_color)
			}
		}
		ustr = tv.line(end_j)
		sel_from, sel_width = text_xminmax_from_pos(tv.tb, ustr, 0, end_i)
		tv.tb.ui.gg.draw_rect(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y + textbox_padding_y +
			end_j * tv.tb.line_height, sel_width, tv.tb.line_height, selection_color)
	}
}

fn (mut tv TextView) insert(s string) {
	mut ustr := tv.text.runes()
	ustr.insert(tv.cursor_pos, s.runes())
	unsafe {
		*tv.text = ustr.string()
	}
	tv.update_lines()
}

fn (mut tv TextView) delete_cur_char() {
	mut ustr := tv.text.runes()
	ustr.delete(tv.cursor_pos)
	unsafe {
		*tv.text = ustr.string()
	}
}

fn (mut tv TextView) delete_prev_char() {
	if tv.cursor_pos == 0 {
		return
	}
	mut ustr := tv.text.runes()
	tv.cursor_pos--
	ustr.delete(tv.cursor_pos)
	unsafe {
		*tv.text = ustr.string()
	}
	tv.update_lines()
}

fn (mut tv TextView) delete_selection() {
	if tv.sel_start > tv.sel_end {
		tv.sel_start, tv.sel_end = tv.sel_end, tv.sel_start
	}
	mut ustr := tv.text.runes()
	ustr.delete_many(tv.sel_start, tv.sel_end - tv.sel_start)
	tv.cursor_pos = tv.sel_start
	tv.sel_end = -1
	unsafe {
		*tv.text = ustr.string()
	}
	tv.update_lines()
}

fn (mut tv TextView) start_selection(x int, y int) {
	// println('start selection: ($x, $y)')
	if y <= 0 {
		tv.tlv.cursor_pos_j = 0
	} else {
		tv.tlv.cursor_pos_j = y / tv.tb.line_height
		if tv.tlv.cursor_pos_j > tv.tlv.lines.len - 1 {
			tv.tlv.cursor_pos_j = tv.tlv.lines.len - 1
		}
	}
	tv.tlv.cursor_pos_i = text_pos_from_x(tv.tb, tv.current_line(), x)
	if tv.tb.dragging {
		tv.tlv.sel_start_i, tv.tlv.sel_start_j = tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j
	}
	tv.sync_text_pos()
	// tv.info()
}

fn (mut tv TextView) end_selection(x int, y int) {
	// println('end selection: ($x, $y)')
	if y <= 0 {
		tv.tlv.sel_end_j = 0
	} else {
		tv.tlv.sel_end_j = y / tv.tb.line_height
		if tv.tlv.sel_end_j > tv.tlv.lines.len - 1 {
			tv.tlv.sel_end_j = tv.tlv.lines.len - 1
		}
	}
	tv.tlv.sel_end_i = text_pos_from_x(tv.tb, tv.tlv.lines[tv.tlv.sel_end_j], x)
	tv.sync_text_pos()
	// println('$tv.sel_end ($tv.tlv.sel_end_i,$tv.tlv.sel_end_j)')
}

pub fn (mut tv TextView) extend_selection(x int, y int) {
	if y <= 0 {
		tv.tlv.cursor_pos_j = 0
	} else {
		tv.tlv.cursor_pos_j = y / tv.tb.line_height
		if tv.tlv.cursor_pos_j > tv.tlv.lines.len - 1 {
			tv.tlv.cursor_pos_j = tv.tlv.lines.len - 1
		}
	}
	tv.tlv.cursor_pos_i = text_pos_from_x(tv.tb, tv.current_line(), x)
	tv.sync_text_pos()
	if tv.tb.twosided_sel { // extend from both sides
		// tv.sel_start and tv.sel_end can and have to be sorted
		tv.sel_start, tv.sel_end = tv.ordered_pos_selection()
		if tv.cursor_pos < tv.sel_start {
			tv.sel_start = tv.cursor_pos
		} else if tv.cursor_pos > tv.sel_end {
			tv.sel_end = tv.cursor_pos
		}
	} else {
		tv.sel_end = tv.cursor_pos
	}
	tv.sync_text_lines()
}

pub fn (mut tv TextView) cancel_selection() {
	tv.sel_start = -1
	tv.sel_end = -1
	tv.sync_text_lines()
}

fn (mut tv TextView) move_cursor(side Side) {
	match side {
		.left {
			tv.cursor_pos--
			if tv.cursor_pos < 0 {
				tv.cursor_pos = 0
			}
			tv.sync_text_lines()
		}
		.right {
			tv.cursor_pos++
			ustr := tv.text.runes()
			if tv.cursor_pos > ustr.len {
				tv.cursor_pos = ustr.len
			}
			tv.sync_text_lines()
		}
		.top {
			tv.tlv.cursor_pos_j--
			if tv.tlv.cursor_pos_j < 0 {
				tv.tlv.cursor_pos_j = 0
			}
			ustr := tv.current_line().runes()
			if tv.tlv.cursor_pos_i >= ustr.len {
				tv.tlv.cursor_pos_i = ustr.len - 1
			}
			tv.sync_text_pos()
		}
		.bottom {
			tv.tlv.cursor_pos_j++
			if tv.tlv.cursor_pos_j >= tv.tlv.lines.len {
				tv.tlv.cursor_pos_j = tv.tlv.lines.len - 1
			}
			ustr := tv.current_line().runes()
			if tv.tlv.cursor_pos_i > ustr.len {
				tv.tlv.cursor_pos_i = ustr.len
			}
			tv.sync_text_pos()
		}
	}
}

fn (mut tv TextView) key_down(e &KeyEvent) {
	// println('key down $e')
	s := utf32_to_str(e.codepoint)
	// println('tv key_down $e <$e.key> ${int(e.codepoint)} <$s>')
	// wui := tv.tb.ui
	// println('${wui.gg.pressed_keys_edge[int(Key.left_control)]}')
	if int(e.codepoint) !in [0, 9, 13, 27, 127] && e.mods !in [.ctrl, .super] {
		// println("insert multi ${int(e.codepoint)}")
		if tv.is_sel_active() {
			tv.delete_selection()
		}
		tv.insert(s)
		tv.cursor_pos++
		tv.sync_text_lines()
	} else if e.mods in [.ctrl, .super] {
		match s {
			'a' {
				tv.sel_start = 0
				tv.sel_end = tv.text.runes().len
				tv.sync_text_lines()
				tv.tb.ui.show_cursor = false
				return
			}
			'c' {
				if tv.is_sel_active() {
					ustr := tv.text.runes()
					sel_start, sel_end := tv.ordered_pos_selection()
					tv.tb.ui.clipboard.copy(ustr[sel_start..sel_end].string())
				}
			}
			'v' {
				tv.insert(tv.tb.ui.clipboard.paste())
			}
			'x' {
				if tv.is_sel_active() {
					ustr := tv.text.runes()
					sel_start, sel_end := tv.ordered_pos_selection()
					tv.tb.ui.clipboard.copy(ustr[sel_start..sel_end].string())
					tv.delete_selection()
				}
			}
			'-' {
				tv.tb.text_size -= 2
				if tv.tb.text_size < 8 {
					tv.tb.text_size = 8
				}
				mut tb := tv.tb
				update_text_size(mut tb)
				tv.tb.update_line_height()
				tv.update_lines()
			}
			'=', '+' {
				tv.tb.text_size += 2
				if tv.tb.text_size > 48 {
					tv.tb.text_size = 48
				}
				mut tb := tv.tb
				update_text_size(mut tb)
				tv.tb.update_line_height()
				tv.update_lines()
			}
			else {}
		}
	}
	// println(e.key)
	// println('mods=$e.mods')
	defer {
		if tv.tb.on_change != TextBoxChangeFn(0) {
			if e.key == .backspace {
				tv.tb.on_change(*tv.text, tv.tb.ui.window.state)
			}
		}
	}
	// println("tb key_down $e.key ${int(e.codepoint)}")
	match e.key {
		.enter {
			tv.insert('\n')
			tv.cursor_pos++
			tv.sync_text_lines()
			tv.cursor_adjust_after_newline()
		}
		.backspace {
			tv.tb.ui.show_cursor = true
			// println('backspace cursor_pos=($tv.tlv.cursor_pos_i, $tv.tlv.cursor_pos_j) len=${(*tv.text).len} \n <${*tv.text}>')
			if *tv.text == '' {
				return
			}
			// Delete the entire selection
			if tv.is_sel_active() {
				tv.delete_selection()
			} else if e.mods in [.super, .ctrl] {
				// Delete until previous whitespace
				// mut i := tv.tlv.cursor_pos_i
				// for {
				// 	if i > 0 {
				// 		i--
				// 	}
				// 	if text[i].is_space() || i == 0 {
				// 		// unsafe { *tb.text = u[..i) + u.right(tb.cursor_pos_i]}
				// 		break
				// 	}
				// }
				// tb.cursor_pos_i = i
			} else {
				// Delete just one character
				tv.delete_prev_char()
			}
		}
		.delete {
			tv.tb.ui.show_cursor = true
			tv.delete_cur_char()
		}
		.left {
			tv.cancel_selection()
			tv.tb.ui.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
			tv.move_cursor(.left)
		}
		.right {
			tv.cancel_selection()
			tv.tb.ui.show_cursor = true
			tv.move_cursor(.right)
		}
		.up {
			tv.cancel_selection()
			tv.tb.ui.show_cursor = true
			tv.move_cursor(.top)
		}
		.down {
			tv.cancel_selection()
			tv.tb.ui.show_cursor = true
			tv.move_cursor(.bottom)
		}
		.escape {
			tv.cancel_selection()
			tv.tb.ui.show_cursor = true
		}
		.tab {
			println('tab')
		}
		else {}
	}
}

fn (tv &TextView) cursor_y() int {
	return tv.tb.y + textbox_padding_y + tv.tlv.cursor_pos_j * tv.tb.line_height
}

fn (tv &TextView) cursor_x() int {
	ustr := tv.current_line().runes()
	mut cursor_x := tv.tb.x + textbox_padding_x
	if ustr.len > 0 {
		left := ustr[..tv.tlv.cursor_pos_i].string()
		cursor_x += text_width(tv.tb, left)
	}
	return cursor_x
}

fn (tv &TextView) cursor_xy() (int, int) {
	return tv.cursor_x(), tv.cursor_y()
}

fn (mut tv TextView) cursor_adjust_after_newline() {
	if tv.tb.has_scrollview {
		if tv.tb.scrollview.active_y
			&& !tv.tb.scrollview.point_inside(tv.cursor_x(), tv.cursor_y() + tv.tb.line_height, .view) {
			tv.tb.scrollview.inc(tv.tb.line_height, .btn_y)
		}
	}
}

fn (mut tv TextView) word_wrap_text() {
	lines := (*tv.text).split('\n')
	mut word_wrapped_lines := []string{}
	for line in lines {
		ww_lines := tv.word_wrap_line(line)
		word_wrapped_lines << ww_lines
	}
	// println('tl: $lines \n $word_wrapped_lines.len $word_wrapped_lines')
	tv.tlv.lines = word_wrapped_lines
}

fn (tv &TextView) word_wrap_line(s string) []string {
	if s == '' {
		return ['']
	}
	words := s.split(' ')
	max_line_width := tv.tb.width
	mut line := ''
	mut line_width := 0
	mut text_lines := []string{}
	for i, word in words {
		if i == 0 { // at least the first
			line = word
			line_width = text_width(tv.tb, word)
		} else {
			word_width := text_width(tv.tb, ' ' + word)
			if line_width + word_width < max_line_width {
				line += ' ' + word
				line_width += word_width
			} else {
				text_lines << line
				line = word
				line_width = word_width
			}
		}
	}
	if line_width > 0 {
		text_lines << line
	}
	return text_lines
}

// get text position from row i and column j
pub fn (tv &TextView) text_pos_at(i int, j int) int {
	mut pos := 0
	lines := tv.tlv.lines
	for k in 0 .. j {
		pos += lines[k].runes().len + 1 // +1 for \n or space
	}
	pos += i
	// println('text_lines_pos_at: ($i, $j) -> $pos ')
	return pos
}

// get row and column from text position
pub fn (tv &TextView) text_line_at(pos int) (int, int) {
	if pos == 0 {
		return 0, 0
	}
	lines := tv.tlv.lines
	mut i, mut j := 0, 0
	mut total_len, mut ustr_len := 0, 0
	for line in lines {
		ustr_len = line.runes().len + 1 // +1 is the return last char
		total_len += ustr_len
		if pos > total_len {
			j++
		} else {
			total_len -= ustr_len
			break
		}
	}
	i = pos - total_len
	if i > tv.line(j).runes().len {
		// IMPORTANT: go to the beginning of the next line
		j++
		i = 0
	}
	// println('text_lines_row_column_at: $pos -> ($i, $j)')
	return i, j
}

fn (tv &TextView) ordered_pos_selection() (int, int) {
	return if tv.sel_start < tv.sel_end {
		tv.sel_start, tv.sel_end
	} else {
		tv.sel_end, tv.sel_start
	}
}

fn (tv &TextView) ordered_lines_selection() (int, int, int, int) {
	return if tv.tlv.sel_start_j < tv.tlv.sel_end_j {
		tv.tlv.sel_start_i, tv.tlv.sel_end_i, tv.tlv.sel_start_j, tv.tlv.sel_end_j
	} else {
		tv.tlv.sel_end_i, tv.tlv.sel_start_i, tv.tlv.sel_end_j, tv.tlv.sel_start_j
	}
}
