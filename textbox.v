// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import strings

enum SelectionDirection {
	nil = 0
	left_to_right
	right_to_left
}

const (
	placeholder_cfg = gx.TextCfg{
		color: gx.gray
		size: gg.default_font_size
		align: gx.align_left
	}
	text_border_color = gx.rgb(177, 177, 177)
	text_inner_border_color = gx.rgb(240, 240, 240)
	text_border_accentuated_color = gx.rgb(255, 0, 0)
	textbox_padding = 5
	// selection_color = gx.rgb(226, 233, 241)
	selection_color = gx.rgb(186, 214, 251)
)

type KeyDownFn fn(voidptr, voidptr, u32)

type KeyUpFn fn(voidptr, voidptr, u32)

[ref_only]
pub struct TextBox {
pub mut:
	height             int
	width              int
	x                  int
	y                  int
	parent             Layout
	is_focused         bool
	// gg &gg.GG
	ui                 &UI
	//text               string
	text               &string = voidptr(0)
	max_len            int
	is_multi           bool
	placeholder        string
	cursor_pos         int
	is_numeric         bool
	is_password        bool
	sel_start          int
	sel_end            int
	last_x             int
	read_only          bool
	borderless         bool
	on_key_down        KeyDownFn=KeyDownFn(0)
	on_key_up          KeyUpFn=KeyUpFn(0)
	dragging           bool
	sel_direction      SelectionDirection
	border_accentuated bool
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
	width              int
	height             int=22
	min                int
	max                int
	val                int
	placeholder        string
	max_len            int
	is_numeric         bool
	is_password        bool
	read_only          bool
	is_multi           bool
	text               &string = voidptr(0)
	is_focused         bool
	borderless         bool
	on_key_down        KeyDownFn
	on_key_up          KeyUpFn
	on_change voidptr
	on_return voidptr


	border_accentuated bool=false
}

fn (mut tb TextBox) init(parent Layout) {
	tb.parent = parent
	ui := parent.get_ui()
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
		width: if c.width < 30 { 30 } else { c.width }
		// sel_start: 0

		placeholder: c.placeholder
		// TODO is_focused: !c.parent.has_textbox // focus on the first textbox in the window by default

		is_numeric: c.is_numeric
		is_password: c.is_password
		max_len: c.max_len
		read_only: c.read_only
		borderless: c.borderless
		on_key_down: c.on_key_down
		on_key_up: c.on_key_up
		border_accentuated: c.border_accentuated
		ui: 0
		text:c.text
		is_focused: c.is_focused
	}
	if c.text == 0 {
		panic('textbox.text binding is not set')
	}
	return tb
}

fn draw_inner_border(border_accentuated bool, gg &gg.Context, x, y, width, height int) {
	if !border_accentuated {
		gg.draw_empty_rect(x, y, width, height, text_border_color)
		// TODO this should be +-1, not 0.5, a bug in gg/opengl
		gg.draw_empty_rect(0.5 + f32(x), 0.5 + f32(y), width - 1, height - 1, text_inner_border_color) // inner lighter border
	}
	else {
		gg.draw_empty_rect(x, y, width, height, text_border_accentuated_color)
		gg.draw_empty_rect(1.5 + f32(x), 1.5 + f32(y), width - 3, height - 3, text_border_accentuated_color) // inner lighter border
	}
}

fn (mut b TextBox) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (mut b TextBox) size() (int,int) {
	return b.width,b.height
}

fn (mut b TextBox) propose_size(w, h int) (int,int) {
	return b.width,b.height
}

fn (mut t TextBox) draw() {
	text:=*(t.text)
	t.ui.gg.draw_rect(t.x, t.y, t.width, t.height, gx.white)
	if !t.borderless {
		draw_inner_border(t.border_accentuated, t.ui.gg, t.x, t.y, t.width, t.height)
	}
	width := if text.len == 0 { 0 } else { t.ui.gg.text_width(text) }
	text_y := t.y + 4 // TODO off by 1px
	mut skip_idx := 0
	// Placeholder
	if text == '' && t.placeholder != '' {
		t.ui.gg.draw_text(t.x + textbox_padding, text_y, t.placeholder, placeholder_cfg)
	}
	// Text
	else {
		// Selection box
		// if t.sel_start != 0 {
		ustr := text.ustring()
		if t.sel_start < t.sel_end && t.sel_start < ustr.len {
			left := ustr.left(t.sel_start)
			right := ustr.right(t.sel_end)
			sel_width := width - t.ui.gg.text_width(right) - t.ui.gg.text_width(left)
			x := t.ui.gg.text_width(left) + t.x + textbox_padding
			t.ui.gg.draw_rect(x, t.y + 3, sel_width, t.height - 6, selection_color)
			/*
			sel_width := t.ui.gg.text_width(right) + 1
			 */

		}
		// The text doesn't fit, find the largest substring we can draw
		if width > t.width {
			for i := text.len - 1; i >= 0; i-- {
				if i >= text.len {
					continue
				}
				if t.ui.gg.text_width(text[i..]) > t.width {
					skip_idx = i + 3
					break
				}
			}
			t.ui.gg.draw_text_def(t.x + textbox_padding, text_y, text[skip_idx..])
		}
		else {
			if t.is_password {
				/*
				for i in 0..t.text.len {
					// TODO drawing multiple circles is broken
					//t.ui.gg.draw_image(t.x + 5 + i * 12, t.y + 5, 8, 8, t.ui.circle_image)
				}
				*/
				t.ui.gg.draw_text_def(t.x + textbox_padding, text_y, strings.repeat(`*`, text.len))
			}
			else {
				t.ui.gg.draw_text_def(t.x + textbox_padding, text_y, text)
			}
		}
	}
	// Draw the cursor
	if t.is_focused && !t.read_only && t.ui.show_cursor && t.sel_start == 0 && t.sel_end == 0 {
		// no cursor in sel mode
		mut cursor_x := t.x + textbox_padding
		if t.is_password {
			cursor_x += t.ui.gg.text_width(strings.repeat(`*`, t.cursor_pos))
		}
		else if skip_idx > 0 {
			cursor_x += t.ui.gg.text_width(text[skip_idx..])
		}
		else if text.len > 0 {
			// left := t.text[..t.cursor_pos]
			left := text.ustring().left(t.cursor_pos)
			cursor_x += t.ui.gg.text_width(left)
		}
		if text.len == 0 {
			cursor_x = t.x + textbox_padding
		}
		// t.ui.gg.draw_line(cursor_x, t.y+2, cursor_x, t.y-2+t.height-1)//, gx.Black)
		t.ui.gg.draw_rect(cursor_x, t.y + 3, 1, t.height - 6, gx.black) // , gx.Black)
	}
}

fn tb_key_up(mut t TextBox, e &KeyEvent, window &Window) {
	if !t.is_focused {
		return
	}
	if t.on_key_up != voidptr(0) {
		t.on_key_up(window.state, t, e.codepoint)
	}
}

fn tb_key_down(mut t TextBox, e &KeyEvent, window &Window) {
	text := *t.text
	if !t.is_focused {
		// println('textbox.key_down on an unfocused textbox, this should never happen')
		return
	}
	if t.on_key_down != voidptr(0) {
		t.on_key_down(window.state, t, e.codepoint)
	}
	if e.codepoint != 0 {
		if t.read_only {
			return
		}
		if t.max_len > 0 && text.len >= t.max_len {
			return
		}
		s := utf32_to_str(e.codepoint)
		// if (t.is_numeric && (s.len > 1 || !s[0].is_digit()  ) {
		if t.is_numeric && (s.len > 1 || (!s[0].is_digit() && ((s[0] != `-`) || ((text.len > 0) && (t.cursor_pos > 0))))) {
			return
		}
		t.insert(s)
		// t.text += s
		// t.cursor_pos ++//= utf8_char_len(s[0])// s.le-112
		return
	}
	// println(e.key)
	// println('mods=$e.mods')
	match e.key {
		.backspace {
			t.ui.show_cursor = true
			if text != '' {
				if t.cursor_pos == 0 {
					return
				}
				//u := text.ustring()
				// Delete the entire selection
				if t.sel_start < t.sel_end {
					unsafe {
					//*t.text = u.left(t.sel_start) + u.right(t.sel_end)
					}
					t.cursor_pos = t.sel_start
					t.sel_start = 0
					t.sel_end = 0
				}
				else if e.mods in [.super, .ctrl] {
					// Delete until previous whitespace
					mut i := t.cursor_pos
					for {
						if i > 0 {
							i--
						}
						if text[i].is_space() || i == 0 {
							unsafe {
							//*t.text = u.left(i) + u.right(t.cursor_pos)
							}
							break
						}
					}
					t.cursor_pos = i
				}
				else {
					// Delete just one character
					unsafe {
					//*t.text = u.left(t.cursor_pos - 1) + u.right(t.cursor_pos)
					}
					t.cursor_pos--
				}
				// u.free() // TODO remove
				// t.text = t.text[..t.cursor_pos - 1] + t.text[t.cursor_pos..]
			}
		}
		.delete {
			t.ui.show_cursor = true
			if t.cursor_pos == text.len || text == '' {
				return
			}
			u := text.ustring()
			unsafe {
			*t.text = u.left(t.cursor_pos) + u.right(t.cursor_pos + 1)
			}
			// t.text = t.text[..t.cursor_pos] + t.text[t.cursor_pos + 1..]
			// u.free() // TODO remove
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
			if t.cursor_pos > text.len {
				t.cursor_pos = text.len
			}
		}
		.a {
			if e.mods in [.super, .ctrl] {
				t.sel_start = 0
				t.sel_end = text.ustring().len - 1
			}
		}
		.v {
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

fn (mut t TextBox) set_sel(sel_start, sel_end int, key Key) {
	if t.sel_direction == .right_to_left {
		t.sel_start = sel_start
		t.sel_end = sel_end
	}
	else {
		t.sel_start = sel_end
		t.sel_end = sel_start
	}
}

fn (mut t TextBox) sel(mods KeyMod, key Key) bool {
	mut sel_start := if t.sel_direction == .right_to_left { t.sel_start } else { t.sel_end }
	mut sel_end := if t.sel_direction == .right_to_left { t.sel_end } else { t.sel_start }
	text := *t.text
	if mods == int(KeyMod.shift) + int(KeyMod.ctrl) {
		mut i := t.cursor_pos
		if sel_start > 0 {
			i = if key == .left { sel_start - 1 } else { sel_start + 1 }
		}
		else if sel_start == 0 && sel_end > 0 {
			i = 0
		}
		else {
			t.sel_direction = if key == .left { SelectionDirection.right_to_left } else { SelectionDirection.left_to_right }
		}
		sel_end = t.cursor_pos
		for {
			if key == .left && i > 0 {
				i--
			}
			else if key == .right && i < t.text.len {
				i++
			}
			if i == 0 {
				sel_start = 0
				break
			}
			else if i == text.len {
				sel_start = t.text.len
				break
			}
			else if text[i].is_space() {
				sel_start = if t.sel_direction == .right_to_left { i + 1 } else { i }
				break
			}
		}
		t.set_sel(sel_start, sel_end, key)
		return true
	}
	if mods == .shift {
		if (t.sel_direction == .right_to_left && sel_start == 0 && sel_end > 0) || (t.sel_direction == .left_to_right && sel_end == t.text.len) {
			return true
		}
		if sel_start <= 0 {
			sel_end = t.cursor_pos
			sel_start = if key == .left { t.cursor_pos - 1 } else { t.cursor_pos + 1 }
			t.sel_direction = if key == .left { SelectionDirection.right_to_left } else { SelectionDirection.left_to_right }
		}
		else {
			sel_start = if key == .left { sel_start - 1 } else { sel_start + 1 }
		}
		t.set_sel(sel_start, sel_end, key)
		return true
	}
	return false
}

fn (t &TextBox) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn tb_mouse_move(mut t TextBox, e &MouseEvent, zzz voidptr) {
	if !t.point_inside(e.x, e.y) {
		return
	}
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
			width := t.ui.gg.text_width(ustr.left(i))
			if prev_width <= x && x <= width {
				if i < t.sel_start && t.sel_end < t.sel_start {
					t.sel_end = t.sel_start
					t.sel_start = i
					return
				}
				if reverse {
					t.sel_start = i
				}
				else {
					t.sel_end = i
				}
				return
			}
			prev_width = width
		}
		if reverse {
			t.sel_start = 0
		}
		else {
			t.sel_end = t.text.len
		}
	}
}

fn tb_click(mut t TextBox, e &MouseEvent, zzz voidptr) {
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
	if *t.text == '' {
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
		// width := t.ui.gg.text_width(t.text[..i])
		width := t.ui.gg.text_width(ustr.left(i))
		if prev_width <= x && x <= width {
			t.cursor_pos = i
			return
		}
		prev_width = width
	}
	t.cursor_pos = t.text.len
}

pub fn (mut t TextBox) focus() {
	if t.is_focused {
		return
	}
	parent := t.parent
	parent.unfocus_all()
	t.is_focused = true
}

fn (t &TextBox) is_focused() bool {
	return t.is_focused
}

fn (mut t TextBox) unfocus() {
	t.is_focused = false
	t.sel_start = 0
	t.sel_end = 0
}

fn (mut t TextBox) update() {
	t.cursor_pos = t.text.ustring().len
}

pub fn (mut t TextBox) hide() {}

pub fn (mut t TextBox) set_text(s string) {
	//t.text = s
	//t.update()
}

pub fn (mut t TextBox) on_change(func voidptr) {
	//t.text = t.text
}

pub fn (mut t TextBox) on_return(func voidptr) {
	//t.text = t.text
}

pub fn (mut t TextBox) insert(s string) {
	mut ustr := t.text.ustring()
	old_len := ustr.len
	// Remove the selection
	if t.sel_start < t.sel_end {
		unsafe {
		*t.text = ustr.left(t.sel_start) + s + ustr.right(t.sel_end + 1)
		}
	}
	else {
		// Insert one character
		// t.text = t.text[..t.cursor_pos] + s + t.text[t.cursor_pos..]
		unsafe {
		*t.text = ustr.left(t.cursor_pos) + s + ustr.right(t.cursor_pos)
		}

		ustr = t.text.ustring()
		// The string is too long
		if t.max_len > 0 && ustr.len >= t.max_len {
			// t.text = t.text.limit(t.max_len)
			unsafe {
			*t.text = ustr.left(t.max_len)
			}
			ustr = t.text.ustring()
		}
	}
	// t.cursor_pos += t.text.len - old_len
	t.cursor_pos += ustr.len - old_len
	t.sel_start = 0
	t.sel_end = 0
}
