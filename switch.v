// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	sw_height = 20
	sw_width = 40
	sw_dot_size = 16
	sw_open_bg_color = gx.rgb(19, 206, 102)
	sw_close_bg_color = gx.rgb(220, 223, 230)
)

type SwitchClickFn fn()

pub struct Switch {
pub mut:
	idx        int
	height     int
	width      int
	x          int
	y          int
	parent     &ui.Window
	is_focused bool
	open bool
	ui         &UI
	onclick    SwitchClickFn
}

pub struct SwitchConfig {
	x       int
	y       int
	parent  &ui.Window
	onclick SwitchClickFn
	open bool
}

pub fn new_switch(c SwitchConfig) &Switch {
	mut sw := &Switch{
		height: sw_height
		width: sw_width
		open:c.open
		x: c.x
		y: c.y
		parent: c.parent
		ui: c.parent.ui
		idx: c.parent.children.len
		onclick: c.onclick
	}
	sw.parent.children << sw
	return sw
}

fn (b mut Switch) draw() {
	padding := (b.height-sw_dot_size)/2
	if b.open {
	    b.ui.gg.draw_rect(b.x, b.y, b.width, b.height, sw_open_bg_color)
		b.ui.gg.draw_rect(b.x - padding + b.width - sw_dot_size , b.y + padding, sw_dot_size, sw_dot_size, gx.white)
	}else{
	    b.ui.gg.draw_rect(b.x, b.y, b.width, b.height, sw_close_bg_color)
	    b.ui.gg.draw_rect(b.x + padding, b.y + padding, sw_dot_size, sw_dot_size, gx.white)
	}
}

fn (b &Switch) key_down(e KeyEvent) {}

fn (t &Switch) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b mut Switch) click(e MouseEvent) {
	if e.action == 0 {
		b.open = !b.open
	}
}

fn (b mut Switch) mouse_move(e MouseEvent) {}

fn (b mut Switch) focus() {
	b.is_focused = true
}

fn (b mut Switch) unfocus() {
	b.is_focused = false
}

fn (b &Switch) idx() int {
	return b.idx
}

fn (t &Switch) typ() WidgetType {
	return .switch_box
}

fn (t &Switch) is_focused() bool {
	return t.is_focused
}
