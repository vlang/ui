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
		size: freetype.default_font_size
		align: gx.ALIGN_LEFT
	}
	button_horizontal_padding = 26
	button_vertical_padding = 8
)

enum ButtonState {
	normal
	pressed
}

type ButtonClickFn fn(voidptr, voidptr)

pub struct ButtonConfig {
	x       int
	y       int
	parent  &ui.Window
	text    string
	onclick ButtonClickFn
	height  int = 20
	width   int
}

pub struct Button {
pub mut:
	idx        int
	state      ButtonState
	height     int
	width      int
	x          int
	y          int
	parent     &ui.Window
	is_focused bool
	ui         &UI
	onclick    ButtonClickFn
	text       string
}


pub fn new_button(c ButtonConfig) &Button {
	mut b := &Button{
		width: c.width
		height: c.height
		x: c.x
		y: c.y
		parent: c.parent
		idx: c.parent.children.len
		text: c.text
		onclick: c.onclick
		ui: c.parent.ui
	}
	b.width = if c.width == 0 { b.ui.ft.text_width(c.text) + button_horizontal_padding } else { c.width }
	b.height = if c.height == 0 { b.ui.ft.text_height(c.text) + button_vertical_padding } else { c.height }
	b.parent.children << b
	return b
}

fn (b mut Button) draw() {
	// b.ui.gg.draw_empty_rect(b.x, b.y, b.width, b.height, gx.Black)
	text_width, text_height := b.ui.ft.text_size(b.text)
	w2 := text_width /2
	h2 := text_height /2
	bcenter_x := b.x + b.width/2
	bcenter_y := b.y + b.height/2
	bg_color := if b.state == .normal { gx.white } else { progress_bar_background_color } // gx.gray }
	b.ui.gg.draw_rect(b.x, b.y, b.width, b.height, bg_color) // gx.white)
	b.ui.gg.draw_empty_rect(b.x, b.y, b.width, b.height, button_border_color)
	mut y := bcenter_y-h2-1
	//if b.ui.gg.scale == 2 {
	$if macos { // TODO
		y += 2
	}
	b.ui.ft.draw_text(bcenter_x-w2, y, b.text, btn_text_cfg)
	//b.ui.gg.draw_empty_rect(bcenter_x-w2, bcenter_y-h2, text_width, text_height, button_border_color)
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
		b.onclick(b.parent.user_ptr, b)
	}
}

fn (b mut Button) mouse_move(e MouseEvent) {}

fn (b mut Button) focus() {
	b.is_focused = true
}

fn (b mut Button) unfocus() {
	b.is_focused = false
}

fn (b &Button) idx() int {
	return b.idx
}

fn (t &Button) typ() WidgetType {
	return .button
}

fn (t &Button) is_focused() bool {
	return t.is_focused
}
