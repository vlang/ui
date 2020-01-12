// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import freetype

const (
	check_mark_size = 14
	cb_border_color = gx.rgb(76, 145, 244)
	cb_image = u32(0)
)

/*
enum CheckBoxState {
	normal
	check
}
*/

type CheckBoxClickFn fn()

pub struct CheckBox {
pub mut:
	idx        int
	//state      CheckBoxState
	height     int
	width      int
	x          int
	y          int
	parent     &ui.Window
	is_focused bool
	is_checked bool
	ctx        &UI
	onclick    CheckBoxClickFn
	text       string
}

struct CheckBoxConfig {
	x       int
	y       int
	parent  &ui.Window
	text    string
	onclick CheckBoxClickFn
	is_checked bool
}

pub fn new_checkbox(c CheckBoxConfig) &CheckBox {
	mut cb := &CheckBox{
		height: 20
		x: c.x
		y: c.y
		parent: c.parent
		ctx: c.parent.ctx
		idx: c.parent.children.len
		text: c.text
		onclick: c.onclick
		is_checked: c.is_checked
	}
	cb.width = cb.ctx.ft.text_width(c.text) + check_mark_size
	cb.parent.children << cb
	return cb
}

fn (b mut CheckBox) draw() {
	b.ctx.gg.draw_rect(b.x, b.y, check_mark_size, check_mark_size, gx.white) // progress_bar_color)
	// b.ctx.gg.draw_empty_rect(b.x, b.y, check_mark_size, check_mark_size, cb_border_color)
	draw_inner_border(b.ctx.gg, b.x, b.y, check_mark_size, check_mark_size)
	// Draw X (TODO draw a check mark instead)
	if b.is_checked {
		/*
		x0 := b.x +2
		y0 := b.y +2
		b.ctx.gg.draw_line_c(x0, y0, x0+check_mark_size -4, y0 + check_mark_size-4, gx.black)
		b.ctx.gg.draw_line_c(0.5+x0, y0, -3.5 +x0+check_mark_size , y0 + check_mark_size-4, gx.black)
		//
		y1 := b.y + check_mark_size - 2
		b.ctx.gg.draw_line_c(x0, y1, x0+check_mark_size -4, y0, gx.black)
		b.ctx.gg.draw_line_c(0.5+x0, y1, -3.5+x0+check_mark_size, y0, gx.black)
		*/
		b.ctx.gg.draw_image(b.x + 3, b.y + 3, 8, 8, b.ctx.cb_image)
	}
	// Text
	b.ctx.ft.draw_text(b.x + check_mark_size + 5, b.y, b.text, btn_text_cfg)
}

fn (b &CheckBox) key_down(e KeyEvent) {}

fn (t &CheckBox) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b mut CheckBox) click(e MouseEvent) {
	if e.action == 0 {
		b.is_checked = !b.is_checked
	}
}

fn (b mut CheckBox) focus() {
	b.is_focused = true
}

fn (b mut CheckBox) unfocus() {
	b.is_focused = false
}

fn (b &CheckBox) idx() int {
	return b.idx
}

fn (t &CheckBox) is_focused() bool {
	return t.is_focused
}
