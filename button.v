// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import oldgg as gg
import freetype
import os

const (
	button_bg_color = gx.rgb(28, 28, 28)
	button_border_color = gx.rgb(200, 200, 200)
	btn_text_cfg = gx.TextCfg{
		// color: gx.white
		color: gx.rgb(38, 38, 38)
		size: freetype.default_font_size
		align: gx.align_left
	}
	button_horizontal_padding = 26
	button_vertical_padding = 8
)

enum ButtonState {
	normal
	pressed
}

type ButtonClickFn fn(voidptr, voidptr) // userptr, btn

pub struct ButtonConfig {
	text      string
	icon_path string
	onclick   ButtonClickFn
	height    int = 20
	width     int
}

[ref_only]
pub struct Button {
pub mut:
	state      ButtonState
	height     int
	width      int
	x          int
	y          int
	parent     Layout
	is_focused bool
	ui         &UI
	onclick    ButtonClickFn
	text       string
	icon_path  string
	texture    u32
}

fn (mut b Button) init(parent Layout) {
	b.parent = parent
	ui := parent.get_ui()
	b.ui = ui
	//TODO
	texture := gg.create_image(b.icon_path)
	b.texture = texture
	b.width = if b.width == 0 { b.ui.ft.text_width(b.text) + button_horizontal_padding } else { b.width }
	b.height = if b.height == 0 { b.ui.ft.text_height(b.text) + button_vertical_padding } else { b.height }
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, btn_click, b)
}

pub fn button(c ButtonConfig) &Button {
	if !os.exists(c.icon_path) {
		println('V UI: icon file "$c.icon_path" not found')
	}
	mut b := &Button{
		width: c.width
		height: c.height
		text: c.text
		icon_path: c.icon_path
		onclick: c.onclick
		ui: 0
	}
	return b
}

fn btn_click(mut b Button, e &MouseEvent, window &Window) {
	//println('btn_click for window=$window.title')
	if b.point_inside(e.x, e.y) {
		if e.action == 1 {
			b.state = .pressed
		}
		else if e.action == 0 {
			b.state = .normal
			if b.onclick != voidptr(0) {
				b.onclick(window.state, b)
			}
		}
	}
}

fn (mut b Button) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (mut b Button) size() (int, int) {
	return b.width, b.height
}

fn (mut b Button) propose_size(w, h int) (int, int) {
	//b.width = w
	//b.height = h
	//b.width = b.ui.ft.text_width(b.text) + button_horizontal_padding
	//b.height = 20 // vertical padding
	return b.width, b.height
}

fn (mut b Button) draw() {
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
	b.ui.gg.draw_image(b.x, b.y, b.width, b.height, b.texture)
	//b.ui.gg.draw_empty_rect(bcenter_x-w2, bcenter_y-h2, text_width, text_height, button_border_color)
}

//fn (b &Button) key_down(e KeyEvent) {}

fn (t &Button) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

//fn (mut b Button) mouse_move(e MouseEvent) {}

fn (mut b Button) focus() {
	b.is_focused = true
}

fn (mut b Button) unfocus() {
	b.is_focused = false
	b.state = .normal
}

fn (t &Button) is_focused() bool {
	return t.is_focused
}
