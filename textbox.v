// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import glfw
import time
import freetype
import strings
import clipboard

const (
	placeholder_cfg = gx.TextCfg{
		color: gx.gray
		size: freetype.DEFAULT_FONT_SIZE
		align: gx.ALIGN_LEFT
	}
	default_window_color = gx.rgb(236, 236, 236)
	text_border_color = gx.rgb(177, 177, 177)
	text_inner_border_color = gx.rgb(240, 240, 240)
	textbox_padding = 5
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
	ctx         &UI
	text        string
	max_len     int
	is_multi    bool
	placeholder string
	cursor_pos  int
	is_numeric  bool
	is_password bool
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
}

// pub fn new_textbox(parent mut Window, rect Rect, placeholder string) &TextBox {
pub fn new_textbox(c TextBoxConfig) &TextBox {
	// println('new textbox')
	// isinit = true
	mut txt := &TextBox{
		height: c.height
		width: c.width
		x: c.x
		y: c.y
		parent: c.parent
		placeholder: c.placeholder
		ctx: c.parent.ctx
		idx: c.parent.children.len
		is_focused: !c.parent.has_textbox // focus on the first textbox in the window by default

		is_numeric: c.is_numeric
		is_password: c.is_password
		max_len: c.max_len
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
	t.ctx.gg.draw_rect(t.x, t.y, t.width, t.height, gx.white)
	draw_inner_border(t.ctx.gg, t.x, t.y, t.width, t.height)
	width := if t.text.len == 0 { 0 } else { t.ctx.ft.text_width(t.text) }
	text_y := t.y + 4 // TODO off by 1px
	mut skip_idx := 0
	// Placeholder
	if t.text == '' {
		if t.placeholder != '' {
			t.ctx.ft.draw_text(t.x + textbox_padding, text_y, t.placeholder, placeholder_cfg)
		}
	}
	// Text
	else {
		if width > t.width {
			// The text doesn't fit, find the largest substring we can draw
			for i := t.text.len - 1; i >= 0; i-- {
				if t.ctx.ft.text_width(t.text[i..]) > t.width {
					skip_idx = i + 3
					break
				}
			}
			t.ctx.ft.draw_text_def(t.x + textbox_padding, text_y, t.text[skip_idx..])
		}
		else {
			if t.is_password {
				/*
				for i in 0..t.text.len {
					// TODO drawing multiple circles is broken
					//t.ctx.gg.draw_image(t.x + 5 + i * 12, t.y + 5, 8, 8, t.ctx.circle_image)
				}
				*/
				t.ctx.ft.draw_text_def(t.x + textbox_padding, text_y, strings.repeat(`*`, t.text.len))
			}
			else {
				t.ctx.ft.draw_text_def(t.x + textbox_padding, text_y, t.text)
			}
		}
	}
	// Draw the cursor
	if t.is_focused && t.ctx.show_cursor {
		mut cursor_x := t.x + textbox_padding
		if t.is_password {
			cursor_x += t.ctx.ft.text_width(strings.repeat(`*`, t.text.len))
		}
		else if skip_idx > 0 {
			cursor_x += t.ctx.ft.text_width(t.text[skip_idx..])
		}
		else if t.text.len > 0 {
			cursor_x += t.ctx.ft.text_width(t.text[..t.cursor_pos])
		}
		// t.ctx.gg.draw_line(cursor_x, t.y+2, cursor_x, t.y-2+t.height-1)//, gx.Black)
		t.ctx.gg.draw_rect(cursor_x, t.y + 3, 1, t.height - 6, gx.Black) // , gx.Black)
	}
}

fn (t mut TextBox) key_down(e KeyEvent) {
	if !t.is_focused {
		println('textbox.key_down on an unfocused textbox, this should never happen')
		return
	}
	if e.codepoint != 0 {
		if t.max_len > 0 && t.text.len >= t.max_len {
			return
		}
		s := utf32_to_str(e.codepoint)
		if t.is_numeric && (s.len > 1 || !s[0].is_digit()) {
			return
		}
		t.text += s
		t.cursor_pos += s.len
		return
	}
	//println(e.key)
	// println('mods=$e.mods')
	match e.key {
		.backspace {
			t.ctx.show_cursor = true
			if t.text != '' {
				if t.cursor_pos == 0 {
					return
				}
				t.text = t.text[..t.cursor_pos - 1] + t.text[t.cursor_pos..]
				t.cursor_pos--
			}
		}
		.delete {
			t.ctx.show_cursor = true
			if t.cursor_pos == t.text.len || t.text == '' {
				return
			}
			t.text = t.text[..t.cursor_pos] + t.text[t.cursor_pos + 1..]
		}
		.left {
			t.ctx.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
			t.cursor_pos--
			if t.cursor_pos <= 0 {
				t.cursor_pos = 0
			}
		}
		.right {
			t.ctx.show_cursor = true
			t.cursor_pos++
			if t.cursor_pos > t.text.len {
				t.cursor_pos = t.text.len
			}
		}
		.key_v {
			if e.mods == .super {
				t.insert(t.ctx.clipboard.paste())
			}
		}
		.tab {
			t.ctx.show_cursor = true
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
	t.ctx.show_cursor = true
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
	for i in 1 .. t.text.len {
		width := t.ctx.ft.text_width(t.text[..i])
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
}

fn (t mut TextBox) update() {
	t.cursor_pos = t.text.len
}

pub fn (t mut TextBox) set_text(s string) {
	t.text = s
	t.update()
}

pub fn (t mut TextBox) insert(s string) {
	old_len := t.text.len
	t.text = t.text[..t.cursor_pos] + s + t.text[t.cursor_pos..]
	if t.max_len > 0 {
		t.text = t.text.limit(t.max_len)
	}
	t.cursor_pos += t.text.len - old_len
}
