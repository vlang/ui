// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import freetype
import strings

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

pub struct TextBox {
pub mut:
	idx         int
	height      int
	width       int
	x           int
	y           int
	parent      &ui.Window
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
	read_only   bool
	borderless  bool
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
	x           int
	y           int
	width       int
	height      int=22
	min         int
	max         int
	val         int
	parent      &ui.Window
	placeholder string
	max_len     int
	is_numeric  bool
	is_password bool
	read_only   bool
	is_multi    bool
	text        string
	borderless  bool
}

// pub fn new_textbox(parent mut Window, rect Rect, placeholder string) &TextBox {
pub fn new_textbox(c TextBoxConfig) &TextBox {
	// println('new textbox')
	// isinit = true
	mut txt := &TextBox{
		height: c.height
		width: if c.width < 30  { 30 } else { c.width }
		x: c.x
		y: c.y
		//sel_start: 0
		parent: c.parent
		placeholder: c.placeholder
		ui: c.parent.ui
		idx: c.parent.children.len
		is_focused: !c.parent.has_textbox // focus on the first textbox in the window by default

		is_numeric: c.is_numeric
		is_password: c.is_password
		max_len: c.max_len
		read_only: c.read_only
		text: c.text
		borderless: c.borderless
	}
	txt.parent.has_textbox = true
	txt.parent.children << txt
	// return widget
	return txt
}

fn draw_inner_border(gg &gg.GG, x, y, width, height int) {
	gg.draw_empty_rect(x, y, width, height, text_border_color)
	// TODO this should be +-1, not 0.5, a bug in gg/opengl
	gg.draw_empty_rect(0.5 + x, 0.5 + y, width - 1, height - 1, text_inner_border_color) // inner lighter border
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
	if t.text == '' {
		if t.placeholder != '' {
			t.ui.ft.draw_text(t.x + textbox_padding, text_y, t.placeholder, placeholder_cfg)
		}
	}
	// Text
	else {
		// Selection box
		//if t.sel_start != 0 {
		ustr := t.text.ustring()
		if t.sel_start < t.sel_end && t.sel_start < ustr.len {
			left := ustr.left(t.sel_start)
			right := ustr.right(t.sel_start)
			x := t.ui.ft.text_width(ustr.left(t.sel_start)) + t.x + textbox_padding
			sel_width := t.ui.ft.text_width(right) + 1
			t.ui.gg.draw_rect(x, t.y + 3, sel_width, t.height-6, selection_color)
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

fn (t mut TextBox) key_down(e KeyEvent) {
	if !t.is_focused {
		println('textbox.key_down on an unfocused textbox, this should never happen')
		return
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
					t.text = u.left(t.sel_start) + u.right(t.sel_end+1)
					t.cursor_pos = t.sel_start
					t.sel_start = 0
					t.sel_end = 0
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
			t.ui.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
			t.cursor_pos--
			if t.cursor_pos <= 0 {
				t.cursor_pos = 0
			}
		}
		.right {
			t.ui.show_cursor = true
			t.cursor_pos++
			if t.cursor_pos > t.text.len {
				t.cursor_pos = t.text.len
			}
		}
		.key_a {
			if e.mods == .super {
				t.sel_start = 0
				t.sel_end = t.text.ustring().len - 1
			}
		}
		.key_v {
			if e.mods == .super {
				t.insert(t.ui.clipboard.paste())
			}
		}
		.tab {
			t.ui.show_cursor = true
			if t.parent.just_tabbed {
				t.parent.just_tabbed = false
				return
			}
			// println('TAB $t.idx')
			if e.mods == .shift {
				t.parent.focus_previous()
			}
			else {
				t.parent.focus_next()
			}
		}
		else {}
	}
}

fn (t &TextBox) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (t mut TextBox) click(e MouseEvent) {
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
	t.parent.unfocus_all()
	t.is_focused = true
}

fn (t &TextBox) idx() int {
	return t.idx
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
