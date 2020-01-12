// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import freetype

const (
	button_bg_color = gx.rgb(28, 28, 28)
	button_border_color = gx.rgb(200, 200, 200)
	btn_text_cfg = gx.TextCfg{
		// color: gx.white
		color: gx.rgb(38, 38, 38)
		size: freetype.DEFAULT_FONT_SIZE
		align: gx.ALIGN_LEFT
	}
	button_horizontal_padding = 26
)

enum ButtonState {
	normal
	pressed
}

type ButtonClickFn fn(voidptr)

struct ButtonConfig {
	x       int
	y       int
	parent  &Window
	text    string
	onclick ButtonClickFn
	height  int=20
}

struct Button {
pub mut:
	idx        int
	state      ButtonState
	height     int
	width      int
	x          int
	y          int
	parent     &Window
	is_focused bool
	ctx        &UI
	onclick    ButtonClickFn
	text       string
}

pub fn new_button(c ButtonConfig) &Button {
	mut b := &Button{
		height: c.height
		x: c.x
		y: c.y
		parent: c.parent
		idx: c.parent.children.len
		text: c.text
		onclick: c.onclick
		ctx: c.parent.ctx
	}
	b.width = b.ctx.ft.text_width(c.text) + button_horizontal_padding
	b.parent.children << b
	return b
}

fn (b mut Button) draw() {
	// b.ctx.gg.draw_empty_rect(b.x, b.y, b.width, b.height, gx.Black)
	text_width := b.ctx.ft.text_width(b.text) + button_horizontal_padding
	bg_color := if b.state == .normal { gx.white } else { progress_bar_background_color } // gx.gray }
	b.ctx.gg.draw_rect(b.x, b.y, text_width, b.height, bg_color) // gx.white)
	b.ctx.gg.draw_empty_rect(b.x, b.y, text_width, b.height, button_border_color)
	b.ctx.ft.draw_text(b.x + button_horizontal_padding / 2, b.y + 3, b.text, btn_text_cfg)
}

fn (b &Button) key_down(e KeyEvent) {}

fn (t &Button) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b mut Button) click(e MouseEvent) {
	if e.action == 1 {
		b.state = .pressed
	}
	else if e.action == 0 {
		b.state = .normal
		a := b.onclick
		a(b.parent.user_ptr)
	}
}

fn (b mut Button) focus() {
	b.is_focused = true
}

fn (b mut Button) unfocus() {
	b.is_focused = false
}

fn (b &Button) idx() int {
	return b.idx
}

fn (t &Button) is_focused() bool {
	return t.is_focused
}
