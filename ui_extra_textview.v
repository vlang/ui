module ui

import gx
// import time
// import encoding.utf8

// position (cursor_pos, sel_start, sel_end) set in the runes world
struct TextView {
pub mut:
	text       &string
	cursor_pos int
	sel_start  int
	sel_end    int
	// text style
	line_height int
	// synchronised lines for the text (or maybe a part)
	tlv TextLinesView
	// textbox
	tb &TextBox // needed for textwidth and for is_wordwrap
}

// Structure to help for drawing text line by line and cursor update between lines
// Insertion and deletion would be made directly on TextView.text field and then synchronized
// on textlines except for cursor vertical motion

/*
In the process to make lines only dealing with visible lines:
- if <from> is the line starting the visibility and <to> the line ending the visibility
- if lines := (*tv.text).split("\n")
- then:
	tvl.lines[0] = lines[..from_j].join("\n")
	tvl.lines[1..(to - from)] = lines[from .. (to + 1)]
	tvl.lines[to - from] = lines[(to + 1) ..]
*/
struct TextLinesView {
pub mut:
	lines                 []string
	from_i                []int
	to_i                  []int
	from_j                int
	to_j                  int
	refresh_visible_lines bool
	cursor_pos_i          int
	cursor_pos_j          int
	sel_start_j           int
	sel_start_i           int
	sel_end_i             int
	sel_end_j             int
}

pub fn (mut tv TextView) init(tb &TextBox) {
	tv.tb = tb
	tv.text = tb.text // delegate text from tb
	tv.update_line_height()
	// println('line height: $tv.line_height')
	tv.refresh_visible_lines()
	tv.update_lines()
	tv.cancel_selection()
	tv.sync_text_pos()
}

pub fn (tv &TextView) size() (int, int) {
	tv.load_style()
	mut w, mut h := 0, textbox_padding_y * 2 + tv.line_height * tv.tlv.lines.len
	// println("size $tv.tb.id: $tv.tlv.lines $tv.tlv.lines.len $tv.tlv.to_j")
	for line in tv.tlv.lines[tv.tlv.from_j..(tv.tlv.to_j + 1)] {
		lw := tv.text_width(line)
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
	tv.refresh_visible_lines()
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
	// Make selection drawable in read-only mode too
	return (tv.tb.is_focused || tv.tb.read_only) && tv.tb.sel_active && tv.sel_end >= 0 // && tv.sel_start != tv.sel_end
}

fn (mut tv TextView) sync_text_pos() {
	tv.cursor_pos = tv.text_pos_at(tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j)
	if tv.tlv.sel_end_j == -1 {
		tv.sel_start = 0
		tv.sel_end = -1
	} else {
		tv.sel_start = tv.text_pos_at(tv.tlv.sel_start_i, tv.tlv.sel_start_j)
		tv.sel_end = tv.text_pos_at(tv.tlv.sel_end_i, tv.tlv.sel_end_j)
	}
}

fn (mut tv TextView) sync_text_lines() {
	tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j = tv.text_line_at(tv.cursor_pos)
	if tv.sel_end == -1 {
		tv.tlv.sel_start_i, tv.tlv.sel_start_j = 0, -1
		tv.tlv.sel_end_i, tv.tlv.sel_end_j = 0, -1
	} else {
		tv.tlv.sel_start_i, tv.tlv.sel_start_j = tv.text_line_at(tv.sel_start)
		tv.tlv.sel_end_i, tv.tlv.sel_end_j = tv.text_line_at(tv.sel_end)
	}
}

pub fn (mut tv TextView) visible_lines() {
	mut j1, mut j2 := 0, 0
	if tv.tb.has_scrollview {
		j1 = tv.tb.scrollview.offset_y / tv.line_height
		if j1 < 0 {
			j1 = 0
		}
	}

	if tv.tb.has_scrollview {
		j2 = (tv.tb.scrollview.offset_y + tv.tb.height) / tv.line_height
	} else {
		j2 = tv.tb.height / tv.line_height
	}
	jmax := tv.tlv.lines.len - 1
	// println("j1 $j1 $jmax")
	if j1 > jmax {
		j1 = jmax
	}
	// println("j2 $j2 $jmax")
	if j2 > jmax {
		j2 = jmax
	}
	tv.tlv.from_j, tv.tlv.to_j = j1, j2
	tv.update_all_visible_lines()
}

fn (mut tv TextView) refresh_visible_lines() {
	tv.tlv.refresh_visible_lines = true
}

fn (mut tv TextView) update_all_visible_lines() {
	if tv.tlv.refresh_visible_lines {
		// println("visible line ${time.now()}")
		tv.tlv.from_i.clear()
		tv.tlv.to_i.clear()
		for j in tv.tlv.from_j .. tv.tlv.to_j + 1 {
			tv.tlv.from_i << tv.text_pos_from_x(tv.tlv.lines[j], tv.tb.scrollview.offset_x)
			tv.tlv.to_i << tv.text_pos_from_x(tv.tlv.lines[j], tv.tb.scrollview.offset_x +
				tv.tb.width)
		}
		// refresh_visible_lines done
		tv.tlv.refresh_visible_lines = false
	}
}

pub fn (mut tv TextView) update_lines() {
	if tv.is_wordwrap() {
		tv.word_wrap_text()
	} else {
		tv.tlv.lines = (*tv.text).split('\n')
	}
	// TO BE DONE AFTER newly created tv.tlv.lines
	if tv.tb.has_scrollview {
		tv.visible_lines()
	}
	// println(tv.tlv.lines)
	tv.sync_text_lines()
	if tv.tb.has_scrollview {
		scrollview_update(tv.tb)
	}
}

fn (mut tv TextView) scroll_changed() {
	// println("textbox scroll changed ${time.now()}")
	tv.refresh_visible_lines()
	tv.update_lines()
}

fn (mut tv TextView) draw_textlines() {
	if tv.tb.is_sync {
		tv.refresh_visible_lines()
		tv.update_lines()
	}

	// draw selection
	tv.draw_selection()

	// draw only visible text lines
	tv.load_style()
	mut y := tv.tb.y + textbox_padding_y
	if tv.tb.has_scrollview {
		y += (tv.tlv.from_j) * tv.line_height
	}
	for i, line in tv.tlv.lines[tv.tlv.from_j..(tv.tlv.to_j + 1)] {
		tv.draw_visible_line(i, y, line)
		y += tv.line_height
	}

	// draw cursor
	if tv.tb.is_focused && !tv.tb.read_only && tv.tb.ui.show_cursor && !tv.is_sel_active() {
		tv.tb.ui.gg.draw_rect_filled(tv.cursor_x(), tv.cursor_y(), 1, tv.line_height,
			gx.black) // , gx.Black)
	}
}

pub fn (mut tv TextView) draw_visible_line(i int, y int, text string) {
	if i == tv.tlv.from_i.len {
		// println("draw_visible_line $i $tv.tlv.from_i.len")
		tv.refresh_visible_lines()
		tv.visible_lines()
	}
	imin, imax := tv.tlv.from_i[i], tv.tlv.to_i[i]
	ustr := text.runes()
	// println("draw visible $imin, $imax $ustr")
	tv.draw_text(tv.tb.x + textbox_padding_x + tv.text_width(ustr[0..imin].string()),
		y, ustr[imin..imax].string())
}

fn (mut tv TextView) draw_selection() {
	if !tv.is_sel_active() {
		// println("return draw_sel")
		return
	}

	if tv.tlv.sel_start_j == tv.tlv.sel_end_j {
		// if on the same line draw the selected background
		sel_from, sel_width := tv.text_xminmax_from_pos(tv.sel_start_line(), tv.tlv.sel_start_i,
			tv.tlv.sel_end_i)
		tv.tb.ui.gg.draw_rect_filled(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y +
			textbox_padding_y + tv.tlv.sel_start_j * tv.line_height, sel_width, tv.line_height,
			selection_color)
	} else {
		// otherwise draw all the selected lines one by one after sorting the position
		start_i, end_i, start_j, end_j := tv.ordered_lines_selection()
		// here the first line
		mut ustr := tv.line(start_j)
		mut sel_from, mut sel_width := tv.text_xminmax_from_pos(ustr, start_i, ustr.len)
		tv.tb.ui.gg.draw_rect_filled(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y +
			textbox_padding_y + start_j * tv.line_height, sel_width, tv.line_height, selection_color)
		// then all the intermediate lines
		if end_j - start_j > 1 {
			for j in (start_j + 1) .. end_j {
				ustr = tv.line(j)
				sel_from, sel_width = tv.text_xminmax_from_pos(ustr, 0, ustr.runes().len)
				tv.tb.ui.gg.draw_rect_filled(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y +
					textbox_padding_y + j * tv.line_height, sel_width, tv.line_height,
					selection_color)
			}
		}
		// and finally the last one
		ustr = tv.line(end_j)
		sel_from, sel_width = tv.text_xminmax_from_pos(ustr, 0, end_i)
		tv.tb.ui.gg.draw_rect_filled(tv.tb.x + textbox_padding_x + sel_from, tv.tb.y +
			textbox_padding_y + end_j * tv.line_height, sel_width, tv.line_height, selection_color)
	}
}

fn (mut tv TextView) insert(s string) {
	mut ustr := tv.text.runes()
	ustr.insert(tv.cursor_pos, s.runes())
	unsafe {
		*tv.text = ustr.string()
	}
	tv.refresh_visible_lines()
	tv.update_lines()
}

fn (mut tv TextView) delete_cur_char() {
	mut ustr := tv.text.runes()
	ustr.delete(tv.cursor_pos)
	unsafe {
		*tv.text = ustr.string()
	}
	tv.refresh_visible_lines()
	tv.update_lines()
}

fn (mut tv TextView) delete_prev_char() {
	if tv.cursor_pos <= 0 {
		tv.cursor_pos = 0
		return
	}
	mut ustr := tv.text.runes()
	tv.cursor_pos--
	ustr.delete(tv.cursor_pos)
	unsafe {
		*tv.text = ustr.string()
	}
	tv.refresh_visible_lines()
	tv.update_lines()
}

fn (mut tv TextView) delete_selection() {
	// tv.info()
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
	tv.refresh_visible_lines()
	tv.update_lines()
	mut tb := tv.tb
	// Only if scrollview become inactive, reset the scrollview
	scrollview_reset(mut tb)
	tv.cancel_selection()
}

fn (mut tv TextView) start_selection(x int, y int) {
	// println('start selection: ($x, $y)')
	if y <= 0 {
		tv.tlv.cursor_pos_j = 0
	} else {
		tv.tlv.cursor_pos_j = y / tv.line_height
		if tv.tlv.cursor_pos_j > tv.tlv.lines.len - 1 {
			tv.tlv.cursor_pos_j = tv.tlv.lines.len - 1
		}
	}
	tv.tlv.cursor_pos_i = tv.text_pos_from_x(tv.current_line(), x)
	if tv.tb.dragging {
		tv.tlv.sel_start_i, tv.tlv.sel_start_j = tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j
		// put sel_end at the sel_start position too to make selection active
		tv.tlv.sel_end_i, tv.tlv.sel_end_j = tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j
	}
	tv.sync_text_pos()
	tv.visible_lines()
	// tv.info()
}

fn (mut tv TextView) end_selection(x int, y int) {
	// println('end selection: ($x, $y)')
	if y <= 0 {
		tv.tlv.sel_end_j = 0
	} else {
		tv.tlv.sel_end_j = y / tv.line_height
		if tv.tlv.sel_end_j > tv.tlv.lines.len - 1 {
			tv.tlv.sel_end_j = tv.tlv.lines.len - 1
		}
	}
	tv.tlv.sel_end_i = tv.text_pos_from_x(tv.tlv.lines[tv.tlv.sel_end_j], x)
	tv.sync_text_pos()
	// tv.info()
	// println('$tv.sel_end ($tv.tlv.sel_end_i,$tv.tlv.sel_end_j)')
}

pub fn (mut tv TextView) extend_selection(x int, y int) {
	if y <= 0 {
		tv.tlv.cursor_pos_j = 0
	} else {
		tv.tlv.cursor_pos_j = y / tv.line_height
		if tv.tlv.cursor_pos_j > tv.tlv.lines.len - 1 {
			tv.tlv.cursor_pos_j = tv.tlv.lines.len - 1
		}
	}
	tv.tlv.cursor_pos_i = tv.text_pos_from_x(tv.current_line(), x)
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
	tv.sel_start = 0
	tv.sel_end = -1
	tv.tb.sel_active = false
	tv.sync_text_lines()
}

pub fn (mut tv TextView) move_cursor(side Side) {
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
			if ustr.len == 0 {
				tv.tlv.cursor_pos_i = 0
			} else if tv.tlv.cursor_pos_i >= ustr.len {
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

pub fn (mut tv TextView) cursor_allways_visible() {
	if !tv.tb.has_scrollview {
		return
	}
	// vertically
	if tv.tlv.cursor_pos_j <= tv.tlv.from_j {
		tv.scroll_y_to_cursor(false)
	} else if tv.tlv.cursor_pos_j >= tv.tlv.to_j {
		tv.scroll_y_to_cursor(true)
	}
	// horizontally
	ustr := tv.tlv.lines[tv.tlv.cursor_pos_j].runes()
	ulen := tv.text_width(ustr[..(tv.tlv.cursor_pos_i)].string())
	if ulen <= tv.tb.scrollview.offset_x {
		tv.scroll_x_to_cursor(false)
	} else if ulen >= tv.tb.scrollview.offset_x + tv.tb.width - scrollbar_size {
		tv.scroll_x_to_cursor(true)
	}
}

fn (mut tv TextView) key_char(e &KeyEvent) {
	// println('key char $e')
	s := utf32_to_str(e.codepoint)
	// println('tv key_down $e <$e.key> ${int(e.codepoint)} <$s>')
	// wui := tv.tb.ui
	// println('${wui.gg.pressed_keys_edge[int(Key.left_control)]}')
	if int(e.codepoint) !in [0, 9, 13, 27, 127] && e.mods !in [.ctrl, .super] {
		if tv.tb.read_only {
			return
		}
		// println("insert multi ${int(e.codepoint)}")
		if tv.is_sel_active() {
			tv.delete_selection()
		}
		Focusable(tv.tb).lock_focus()
		tv.insert(s)
		tv.cursor_pos++
		tv.sync_text_lines()
	} else if e.mods in [.ctrl, .super] {
		// WORKAROUND to deal with international keyboard
		// println('key_char:  <$s> <$e.mods> <${utf32_to_str(u32(e.key))}>')
		match s {
			'a' {
				tv.do_select_all()
			}
			'c' {
				tv.do_copy()
			}
			'v' {
				tv.do_paste()
			}
			'x' {
				tv.do_cut()
			}
			'-' {
				tv.do_zoom_down()
			}
			'=', '+' {
				tv.do_zoom_up()
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
	if tv.tb.read_only {
		return
	}
	tv.cursor_allways_visible()
}

fn (mut tv TextView) key_down(e &KeyEvent) {
	// println('tv key down $e')
	// println('key_down: $e.key mods=$e.mods')
	defer {
		if tv.tb.on_change != TextBoxChangeFn(0) {
			if e.key == .backspace {
				tv.tb.on_change(*tv.text, tv.tb.ui.window.state)
			}
		}
	}
	// println("tb key_down $e.key ${int(e.codepoint)}")
	if tv.tb.read_only {
		return
	}
	match e.key {
		.enter {
			// println('enter $tv.tb.id')
			tv.insert('\n')
			tv.cursor_pos++
			tv.sync_text_lines()
			tv.cursor_adjust_after_newline()
			tv.cursor_allways_visible()
		}
		.tab {
			// println("tab multi")
			if !tv.tb.ui.window.unlocked_focus() {
				if tv.is_sel_active() {
					tv.do_indent(e.mods == .shift)
				} else {
					tv.insert('  ')
					tv.cursor_pos += 2
				}
				tv.sync_text_lines()
				tv.cursor_adjust_after_newline()
				tv.cursor_allways_visible()
			}
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
			tv.cursor_allways_visible()
		}
		.delete {
			tv.tb.ui.show_cursor = true
			tv.delete_cur_char()
			tv.cursor_allways_visible()
		}
		.left, .right, .up, .down {
			dir := match e.key {
				.left { Side.left }
				.right { Side.right }
				.up { Side.top }
				else { Side.bottom }
			}
			if shift_key(e.mods) {
				if !tv.is_sel_active() {
					tv.tb.sel_active = true
					tv.sel_start = tv.cursor_pos
					tv.tb.ui.show_cursor = false
				}
				tv.move_cursor(dir)
				tv.sel_end = tv.cursor_pos
				tv.sync_text_lines()
			} else {
				tv.cancel_selection()
				tv.tb.ui.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
				tv.move_cursor(dir)
			}
			tv.cursor_allways_visible()
		}
		.escape {
			if tv.tb.ui.window.unlocked_focus() {
				// allow to use tab inside textbox
				Focusable(tv.tb).lock_focus()
			} else {
				if !tv.is_sel_active() {
					Focusable(tv.tb).unlock_focus()
				}
				tv.cancel_selection()
				tv.tb.ui.show_cursor = true
			}
		}
		else {}
	}
}

pub fn (mut tv TextView) do_indent(shift bool) {
	if tv.is_sel_active() {
		cursor_pos := tv.cursor_pos
		for j in tv.tlv.sel_start_j .. (tv.tlv.sel_end_j + 1) {
			tv.tlv.cursor_pos_i, tv.tlv.cursor_pos_j = 0, j
			tv.sync_text_pos()
			if shift {
				if tv.tlv.lines[j][..2] == '  ' {
					tv.sel_end -= 2
					tv.delete_cur_char()
					tv.delete_cur_char()
				}
			} else {
				tv.sel_end += 2
				tv.insert('  ')
			}
		}
		tv.cursor_pos = cursor_pos
		tv.sync_text_lines()
	}
}

pub fn (mut tv TextView) do_select_all() {
	if tv.tb.read_only && !tv.tb.is_selectable {
		return
	}
	tv.sel_start = 0
	tv.sel_end = tv.text.runes().len
	tv.sync_text_lines()
	tv.tb.ui.show_cursor = false
	tv.tb.sel_active = true
	return
}

pub fn (mut tv TextView) do_copy() {
	if tv.is_sel_active() {
		ustr := tv.text.runes()
		sel_start, sel_end := tv.ordered_pos_selection()
		tv.tb.ui.clipboard.copy(ustr[sel_start..sel_end].string())
	}
}

pub fn (mut tv TextView) do_paste() {
	if tv.tb.read_only {
		return
	}
	tv.insert(tv.tb.ui.clipboard.paste())
}

pub fn (mut tv TextView) do_cut() {
	if tv.tb.read_only {
		return
	}
	if tv.is_sel_active() {
		ustr := tv.text.runes()
		sel_start, sel_end := tv.ordered_pos_selection()
		tv.tb.ui.clipboard.copy(ustr[sel_start..sel_end].string())
		tv.delete_selection()
	}
}

pub fn (mut tv TextView) do_zoom_down() {
	if tv.tb.read_only && !tv.tb.is_selectable {
		return
	}
	mut text_size := DrawTextWidget(tv.tb).font_size()
	text_size -= 2
	if text_size < 8 {
		text_size = 8
	}
	tv.update_style(size: text_size)
	tv.update_line_height()
	tv.update_lines()
}

pub fn (mut tv TextView) do_zoom_up() {
	if tv.tb.read_only && !tv.tb.is_selectable {
		return
	}
	mut text_size := DrawTextWidget(tv.tb).font_size()
	text_size += 2
	if text_size > 48 {
		text_size = 48
	}
	tv.update_style(size: text_size)
	tv.update_line_height()
	tv.update_lines()
}

[params]
pub struct LogViewParams {
	nb_lines int = 5
}

pub fn (mut tv TextView) do_logview(cfg LogViewParams) {
	if !tv.tb.has_scrollview {
		println("Warning: use of task do_logview requires textbox to have 'scrollview: true'")
		return
	}
	if tv.tlv.to_j + cfg.nb_lines > tv.tlv.lines.len {
		tv.scroll_y_to_end()
	}
}

fn (tv &TextView) cursor_y() int {
	return tv.tb.y + textbox_padding_y + tv.tlv.cursor_pos_j * tv.line_height
}

fn (tv &TextView) cursor_x() int {
	ustr := tv.current_line().runes()
	mut cursor_x := tv.tb.x + textbox_padding_x
	if ustr.len > 0 {
		left := ustr[..tv.tlv.cursor_pos_i].string()
		cursor_x += tv.text_width(left)
	}
	return cursor_x
}

fn (tv &TextView) cursor_xy() (int, int) {
	return tv.cursor_x(), tv.cursor_y()
}

pub fn (mut tv TextView) cursor_adjust_after_newline() {
	if tv.tb.has_scrollview {
		if tv.tb.scrollview.active_y
			&& !tv.tb.scrollview.point_inside(tv.cursor_x(), tv.cursor_y() + tv.line_height, .view) {
			tv.tb.scrollview.inc(tv.line_height, .btn_y)
		}
	}
}

pub fn (mut tv TextView) scroll_x_to_cursor(end bool) {
	if tv.tb.scrollview.active_x {
		delta := if end { tv.tb.width - 2 * scrollbar_size } else { 0 }
		ustr := tv.tlv.lines[tv.tlv.cursor_pos_j].runes()
		ulen := tv.text_width(ustr[..tv.tlv.cursor_pos_i].string())
		tv.tb.scrollview.set(ulen - delta, .btn_x)
	}
}

pub fn (mut tv TextView) scroll_y_to_cursor(end bool) {
	if tv.tb.scrollview.active_y {
		delta := if end { tv.tb.height - tv.line_height / 2 - tv.line_height } else { 0 }
		tv.tb.scrollview.set(tv.tlv.cursor_pos_j * tv.line_height - delta, .btn_y)
	}
}

pub fn (mut tv TextView) scroll_y_to_end() {
	if tv.tb.scrollview.active_y {
		tv.tb.scrollview.set((tv.tlv.lines.len) * tv.line_height, .btn_y)
	}
}

fn (mut tv TextView) word_wrap_text() {
	lines := (*tv.text).split('\n')
	mut word_wrapped_lines := []string{}
	// println('word_wrap_text: $tv.tlv.from_j -> $tv.tlv.to_j')
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
			line_width = tv.text_width(word)
		} else {
			word_width := tv.text_width(' ' + word)
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
	jj := if j >= lines.len { lines.len } else { j }
	for k in 0 .. jj {
		pos += lines[k].runes().len + 1 // +1 for \n or space
	}
	pos += i
	// if pos < 0 {
	// 	pos = 0
	// } else if pos > tv.text.len - 1 {
	// 	pos = tv.text.len - 1
	// }
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

pub fn (tv &TextView) text_xminmax_from_pos(text string, x1 int, x2 int) (int, int) {
	tv.load_style()
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
	ww, lw, rw := tv.text_width(text), tv.text_width(left), tv.text_width(right)
	return lw, ww - lw - rw
}

pub fn (tv &TextView) text_pos_from_x(text string, x int) int {
	if x <= 0 {
		return 0
	}
	tv.load_style()
	mut prev_width := 0.0
	ustr := text.runes()
	mut width, mut width_cur := 0.0, 0.0
	for i in 0 .. ustr.len {
		width += width_cur
		// if width != tv.text_width(ustr[..i].string()) {
		// 	// println("widthhhh $i $width ${tv.text_width(ustr[..i].string())}")
		// }
		width_cur = tv.text_width_additive(ustr[i..(i + 1)].string())
		width2 := if i < ustr.len { width + width_cur } else { width }
		if (prev_width + width) / 2 <= x && x <= (width + width2) / 2 {
			return i
		}
		prev_width = width
	}
	return ustr.len
}

/*
THIS OLD VERSION LASTS VERY LONG
pub fn (tv &TextView) text_pos_from_x(text string, x int) int {
	if x <= 0 {
		return 0
	}
	tv.load_current_style()
	mut prev_width, mut tmp := 0, 0
	ustr := text.runes()
	for i in 0 .. ustr.len {
		width := tmp
		tmp = tv.text_width(ustr[..(i + 1)].string())
		width2 := if i < ustr.len { tmp } else { width }
		if (prev_width + width) / 2 <= x && x <= (width + width2) / 2 {
			return i
		}
		prev_width = width
	}
	return ustr.len
}
*/

// TextStyles
fn (tv &TextView) draw_text(x int, y int, text string) {
	DrawTextWidget(tv.tb).draw_text(x, y, text)
}

fn (tv &TextView) draw_styled_text(x int, y int, text string, ts TextStyleParams) {
	DrawTextWidget(tv.tb).draw_styled_text(x, y, text, ts)
}

fn (tv &TextView) text_width(text string) int {
	return DrawTextWidget(tv.tb).text_width(text)
}

// Added to have mostly additive text width function
fn (tv &TextView) text_width_additive(text string) f64 {
	return DrawTextWidget(tv.tb).text_width_additive(text)
}

fn (tv &TextView) text_height(text string) int {
	return DrawTextWidget(tv.tb).text_width(text)
}

fn (tv &TextView) text_size(text string) (int, int) {
	return DrawTextWidget(tv.tb).text_size(text)
}

fn (mut tv TextView) update_line_height() {
	tv.load_style()
	tv.line_height = int(f64(tv.text_height('W')) * 1.5)
}

fn (tv &TextView) update_style(ts TextStyleParams) {
	mut dtw := DrawTextWidget(tv.tb)
	dtw.update_style(ts)
}

// Not called automatically as it is in gg
fn (tv &TextView) load_style() {
	DrawTextWidget(tv.tb).load_style()
}

// that's weird text_width is not additive function
pub fn (tv &TextView) test_textwidth(text string) {
	ustr := text.runes()
	mut width := 0.0
	for i in 0 .. ustr.len {
		tmp := DrawTextWidget(tv.tb).text_width_additive(ustr[i..(i + 1)].string())
		width += tmp
		tmp2, _ := tv.text_size(ustr[..i + 1].string())
		println('$i) ${ustr[i..(i + 1)].string()} ($tmp) ${ustr[..i + 1].string()} ${width + 1.0} == $tmp2')
	}
}
