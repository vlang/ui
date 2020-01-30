// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import freetype
import strings

enum SelectionDirection {
	nil = 0
	left_to_right
	right_to_left
}

const (
	placeholder_cfg = gx.TextCfg{
		color: gx.gray
		size: freetype.default_font_size
		align: gx.ALIGN_LEFT
	}
	text_border_color = gx.rgb(177, 177, 177)
	text_inner_border_color = gx.rgb(240, 240, 240)
	textbox_padding = 5
	//selection_color = gx.rgb(226, 233, 241)
	selection_color = gx.rgb(186, 214, 251)
)

type KeyDownFn fn(voidptr, voidptr, u32)
type KeyUpFn fn(voidptr, voidptr, u32)

pub struct TextBox {
pub mut:
	
	height      int
	width       int
	x           int
	y           int
	parent ILayouter
	is_focused  bool
	// gg &gg.GG
	ui          &UI
	text        string
	max_len     int
	is_multi    bool
	placeholder string
	cursor_pos  int
	is_numeric  bool
	is_password bool
	sel_start   int
	sel_end     int
	last_x		int
	read_only   bool
	borderless  bool
	on_key_down KeyDownFn = KeyDownFn(0)
	on_key_up KeyUpFn = KeyUpFn(0)
	dragging	bool
	sel_direction SelectionDirection
}

/*
struct Rect {
	x      int
	y      int
	width  int
	height int
}
*/

pub struct TextBoxConfig {
	width       int
	height      int=22
	min         int
	max         int
	val         int
	placeholder string
	max_len     int
	is_numeric  bool
	is_password bool
	read_only   bool
	is_multi    bool
	text        string
	borderless  bool
	on_key_down KeyDownFn
	on_key_up   KeyUpFn
	ref			&TextBox
}

fn (tb mut TextBox)init(p &ILayouter) {
	parent := *p
	tb.parent = parent
	ui :=  parent.get_ui()
	tb.ui = ui
	// return widget
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, tb_click, tb)
	subscriber.subscribe_method(events.on_key_down, tb_key_down, tb)
	subscriber.subscribe_method(events.on_key_up, tb_key_up, tb)
	subscriber.subscribe_method(events.on_mouse_move, tb_mouse_move, tb)
}

pub fn textbox(c TextBoxConfig) &TextBox {
	tb := &TextBox{
		height: c.height
		width: if c.width < 30  { 30 } else { c.width }
		//sel_start: 0
		placeholder: c.placeholder
		//TODO is_focused: !c.parent.has_textbox // focus on the first textbox in the window by default
		is_numeric: c.is_numeric
		is_password: c.is_password
		max_len: c.max_len
		read_only: c.read_only
		text: c.text
		borderless: c.borderless
		on_key_down: c.on_key_down
		on_key_up: c.on_key_up
	}
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *tb
		return &ref
	}
	return tb
}

fn draw_inner_border(gg &gg.GG, x, y, width, height int) {
	gg.draw_empty_rect(x, y, width, height, text_border_color)
	// TODO this should be +-1, not 0.5, a bug in gg/opengl
	gg.draw_empty_rect(0.5 + x, 0.5 + y, width - 1, height - 1, text_inner_border_color) // inner lighter border
}

fn (b mut TextBox) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut TextBox) set_size(w, h int) {
	b.width = w
}

fn (b mut TextBox) propose_size(w, h int) (int, int) {
	return b.width, b.height
}

fn (t mut TextBox) draw() {
	t.ui.gg.draw_rect(t.x, t.y, t.width, t.height, gx.white)
	if !t.borderless {
		draw_inner_border(t.ui.gg, t.x, t.y, t.width, t.height)
	}
	width := if t.text.len == 0 { 0 } else { t.ui.ft.text_width(t.text) }
	text_y := t.y + 4 // TODO off by 1px
	mut skip_idx := 0
	// Placeholder
	if t.text == '' && t.placeholder != '' {
		t.ui.ft.draw_text(t.x + textbox_padding, text_y, t.placeholder, placeholder_cfg)
	}
	// Text
	else {
		// Selection box
		//if t.sel_start != 0 {
		ustr := t.text.ustring()
		if t.sel_start < t.sel_end && t.sel_start < ustr.len {
			left := ustr.left(t.sel_start)
			right := ustr.right(t.sel_end)
			sel_width := width - t.ui.ft.text_width(right) - t.ui.ft.text_width(left)
			x := t.ui.ft.text_width(left) + t.x + textbox_padding
			t.ui.gg.draw_rect(x, t.y + 3, sel_width, t.height-6, selection_color)
		/* 	
			sel_width := t.ui.ft.text_width(right) + 1
			 */
		}

		// The text doesn't fit, find the largest substring we can draw
		if width > t.width {
			for i := t.text.len - 1; i >= 0; i-- {
				if i >= t.text.len {
					continue
				}
				if t.ui.ft.text_width(t.text[i..]) > t.width {
					skip_idx = i + 3
					break
				}
			}
			t.ui.ft.draw_text_def(t.x + textbox_padding, text_y, t.text[skip_idx..])
		}
		else {
			if t.is_password {
				/*
				for i in 0..t.text.len {
					// TODO drawing multiple circles is broken
					//t.ui.gg.draw_image(t.x + 5 + i * 12, t.y + 5, 8, 8, t.ui.circle_image)
				}
				*/
				t.ui.ft.draw_text_def(t.x + textbox_padding, text_y, strings.repeat(`*`, t.text.len))
			}
			else {
				t.ui.ft.draw_text_def(t.x + textbox_padding, text_y, t.text)
			}
		}
	}
	// Draw the cursor
	if t.is_focused && !t.read_only && t.ui.show_cursor && t.sel_start == 0 && t.sel_end == 0 { // no cursor in sel mode
		mut cursor_x := t.x + textbox_padding
		if t.is_password {
			cursor_x += t.ui.ft.text_width(strings.repeat(`*`, t.cursor_pos))
		}
		else if skip_idx > 0 {
			cursor_x += t.ui.ft.text_width(t.text[skip_idx..])
		}
		else if t.text.len > 0 {
			//left := t.text[..t.cursor_pos]
			left := t.text.ustring().left(t.cursor_pos)
			cursor_x += t.ui.ft.text_width(left)
		}
		// t.ui.gg.draw_line(cursor_x, t.y+2, cursor_x, t.y-2+t.height-1)//, gx.Black)
		t.ui.gg.draw_rect(cursor_x, t.y + 3, 1, t.height - 6, gx.Black) // , gx.Black)
	}
}
fn tb_key_up(t mut TextBox, e &KeyEvent, window &ui.Window ) {
	if !t.is_focused {
		return
	}
	if t.on_key_up != 0 {
		t.on_key_up(window.user_ptr, t, e.codepoint)
	}
}

fn tb_key_down(t mut TextBox, e &KeyEvent, window &ui.Window ) {
	if !t.is_focused {
		//println('textbox.key_down on an unfocused textbox, this should never happen')
		return
	}
	if t.on_key_down != 0 {
		t.on_key_down(window.user_ptr, t, e.codepoint)
	}
	if e.codepoint != 0 {
		if t.read_only {
			return
		}
		if t.max_len > 0 && t.text.len >= t.max_len {
			return
		}
		s := utf32_to_str(e.codepoint)
		if t.is_numeric && (s.len > 1 || !s[0].is_digit()) {
			return
		}
		t.insert(s)
		//t.text += s
		//t.cursor_pos ++//= utf8_char_len(s[0])// s.len
		return
	}
	//println(e.key)
	// println('mods=$e.mods')
	match e.key {
		.backspace {
			t.ui.show_cursor = true
			if t.text != '' {
				if t.cursor_pos == 0 {
					return
				}
				u := t.text.ustring()
				// Delete the entire selection
				if t.sel_start < t.sel_end {
					t.text = u.left(t.sel_start) + u.right(t.sel_end)
					t.cursor_pos = t.sel_start
					t.sel_start = 0
					t.sel_end = 0
				} else if e.mods in [.super, .ctrl] {
					// Delete until previous whitespace
					mut i := t.cursor_pos
					for {
						if i > 0 {
							i--
						}
						if t.text[i].is_white() || i == 0 {
							t.text = u.left(i) + u.right(t.cursor_pos)
							break
						}
					}
					t.cursor_pos = i
				} else {
					// Delete just one character
					t.text = u.left(t.cursor_pos - 1) + u.right(t.cursor_pos)
					t.cursor_pos--
				}
				//u.free() // TODO remove
				//t.text = t.text[..t.cursor_pos - 1] + t.text[t.cursor_pos..]
			}
		}
		.delete {
			t.ui.show_cursor = true
			if t.cursor_pos == t.text.len || t.text == '' {
				return
			}
			u := t.text.ustring()
			t.text = u.left(t.cursor_pos) + u.right(t.cursor_pos+1)
			//t.text = t.text[..t.cursor_pos] + t.text[t.cursor_pos + 1..]
			//u.free() // TODO remove
		}
		.left {
			if t.sel(e.mods, e.key) {
				return
			}
			if t.sel_end > 0 {
				t.cursor_pos = t.sel_start + 1
			}
			t.sel_start = 0
			t.sel_end = 0
			t.ui.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
			t.cursor_pos--
			if t.cursor_pos <= 0 {
				t.cursor_pos = 0
			}
		}
		.right {
			if t.sel(e.mods, e.key) {
				return
			}
			if t.sel_start > 0 {
				t.cursor_pos = t.sel_end - 1
			}
			t.sel_end = 0
			t.sel_start = 0
			t.ui.show_cursor = true
			t.cursor_pos++
			if t.cursor_pos > t.text.len {
				t.cursor_pos = t.text.len
			}
		}
		.key_a {
			if e.mods in [.super, .ctrl] {
				t.sel_start = 0
				t.sel_end = t.text.ustring().len - 1
			}
		}
		.key_v {
			if e.mods in [.super, .ctrl] {
				t.insert(t.ui.clipboard.paste())
			}
		}
		.tab {
			t.ui.show_cursor = true
			/*TODO if t.parent.just_tabbed {
				t.parent.just_tabbed = false
				return
			} */
			// println('TAB $t.idx')
			/* if e.mods == .shift {
				t.parent.focus_previous()
			}
			else {
				t.parent.focus_next()
			} */
		}
		else {}
	}
}
fn (t mut TextBox) set_sel(sel_start, sel_end int, key Key) {
	if t.sel_direction == .right_to_left {
		t.sel_start = sel_start
		t.sel_end = sel_end
	} else {
		t.sel_start = sel_end
		t.sel_end = sel_start
	}
}

fn (t mut TextBox) sel(mods KeyMod, key Key) bool {
	mut sel_start := if t.sel_direction == .right_to_left {t.sel_start} else {t.sel_end}
	mut sel_end := if t.sel_direction == .right_to_left {t.sel_end} else {t.sel_start}
	
	if mods == .shift + .ctrl {
		mut i := t.cursor_pos
		if sel_start > 0 {
			i = if key == .left { sel_start - 1 } else { sel_start + 1}
		} else if sel_start == 0 && sel_end > 0 {
			i = 0
		} else {
			t.sel_direction = if key == .left { SelectionDirection.right_to_left } else { SelectionDirection.left_to_right }
		}
		sel_end = t.cursor_pos
		for {
			if key == .left && i > 0 {
				i--
			} else if key == .right && i < t.text.len {
				i++
			}
			 if i == 0 {
				sel_start = 0
				break
			} else if i == t.text.len {
				sel_start = t.text.len
				break
			} else if t.text[i].is_white() {
				sel_start = if t.sel_direction == .right_to_left { i + 1 } else {i}
				break
			}
		}
		t.set_sel(sel_start, sel_end, key)
		return true
	}
	if mods == .shift {
		if (t.sel_direction == .right_to_left && sel_start == 0 && sel_end > 0) || (t.sel_direction == .left_to_right && sel_end == t.text.len ) {return true}
		if sel_start <= 0 {
			sel_end = t.cursor_pos
			sel_start = if key == .left { t.cursor_pos - 1 } else {t.cursor_pos + 1}
			t.sel_direction = if key == .left { SelectionDirection.right_to_left } else { SelectionDirection.left_to_right }
		} else {
			sel_start = if key == .left { sel_start - 1 } else { sel_start + 1}
		}
		t.set_sel(sel_start, sel_end, key)
		return true
	}
	return false
}

fn (t &TextBox) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn tb_mouse_move(t mut TextBox, e &MouseEvent) {
	if !t.point_inside(e.x, e.y) {return}
	
	if t.dragging {
		x := e.x - t.x - textbox_padding
		reverse := x - t.last_x < 0

		if t.sel_start <= 0 {
			t.sel_start = t.cursor_pos
		}

		t.last_x = x
		mut prev_width := 0
		ustr := t.text.ustring()
		for i in 1 .. ustr.len {
			width := t.ui.ft.text_width(ustr.left(i))
			if prev_width <= x && x <= width {
				if i < t.sel_start && t.sel_end < t.sel_start {
					t.sel_end = t.sel_start
					t.sel_start = i
					return
				}
				if reverse {
					t.sel_start = i
				} else {
					t.sel_end = i
				}
				return
			}
			prev_width = width
		}
		if reverse {
			t.sel_start = 0
		} else {
			t.sel_end = t.text.len
		}
	}
}

fn tb_click(t mut TextBox, e &MouseEvent) {
	if !t.point_inside(e.x, e.y) {
		t.dragging = false
		return
	}
	if !t.dragging && e.action == 1 {
		t.sel_start = 0
		t.sel_end = 0
	}
	t.dragging = e.action == 1
	t.ui.show_cursor = true
	t.focus()
	if t.text == '' {
		return
	}
	// Calculate cursor position from x
	x := e.x - t.x - textbox_padding
	if x <= 0 {
		t.cursor_pos = 0
		return
	}
	mut prev_width := 0
	ustr := t.text.ustring()
	for i in 1 .. ustr.len {
		//width := t.ui.ft.text_width(t.text[..i])
		width := t.ui.ft.text_width(ustr.left(i))
		if prev_width <= x && x <= width {
			t.cursor_pos = i
			return
		}
		prev_width = width
	}
	t.cursor_pos = t.text.len
}

pub fn (t mut TextBox) focus() {
	if t.is_focused {return}
	parent := t.parent
	parent.unfocus_all()
	t.is_focused = true
}

fn (t &TextBox) is_focused() bool {
	return t.is_focused
}

fn (t mut TextBox) unfocus() {
	t.is_focused = false
	t.sel_start = 0
	t.sel_end = 0
}

fn (t mut TextBox) update() {
	t.cursor_pos = t.text.ustring().len
}

pub fn (t mut TextBox) hide() {

}

pub fn (t mut TextBox) set_text(s string) {
	t.text = s
	t.update()
}

pub fn (t mut TextBox) on_change(func voidptr) {
	t.text = t.text
}

pub fn (t mut TextBox) on_return(func voidptr) {
	t.text = t.text
}

pub fn (t mut TextBox) insert(s string) {
	mut ustr := t.text.ustring()
	old_len := ustr.len
	// Remove the selection
	if t.sel_start < t.sel_end {
		t.text = ustr.left(t.sel_start) + s + ustr.right(t.sel_end + 1)
	} else {
		// Insert one character
		//t.text = t.text[..t.cursor_pos] + s + t.text[t.cursor_pos..]
		t.text = ustr.left(t.cursor_pos) + s + ustr.right(t.cursor_pos)
		ustr = t.text.ustring()
		// The string is too long
		if t.max_len > 0  && ustr.len >= t.max_len {
			//t.text = t.text.limit(t.max_len)
			t.text = ustr.left(t.max_len)
			ustr = t.text.ustring()
		}
	}
	//t.cursor_pos += t.text.len - old_len
	t.cursor_pos += ustr.len - old_len
	t.sel_start = 0
	t.sel_end = 0
}
