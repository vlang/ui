// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	sw_height         = 20
	sw_width          = 40
	sw_dot_size       = 16
	sw_open_bg_color  = gx.rgb(19, 206, 102)
	sw_close_bg_color = gx.rgb(220, 223, 230)
)

type SwitchClickFn = fn (arg_1 voidptr, arg_2 voidptr)

pub struct Switch {
pub mut:
	idx        int
	height     int
	width      int
	x          int
	y          int
	z_index    int
	parent     Layout
	is_focused bool
	open       bool
	ui         &UI
	onclick    SwitchClickFn
	hidden     bool
}

pub struct SwitchConfig {
	z_index int
	onclick SwitchClickFn
	open    bool
}

fn (mut s Switch) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	s.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, sw_click, s)
}

pub fn switcher(c SwitchConfig) &Switch {
	mut s := &Switch{
		height: ui.sw_height
		width: ui.sw_width
		z_index: c.z_index
		open: c.open
		onclick: c.onclick
		ui: 0
	}
	return s
}

fn (mut s Switch) set_pos(x int, y int) {
	s.x = x
	s.y = y
}

fn (mut s Switch) size() (int, int) {
	return s.width, s.height
}

fn (mut s Switch) propose_size(w int, h int) (int, int) {
	return s.width, s.height
}

fn (mut s Switch) draw() {
	padding := (s.height - ui.sw_dot_size) / 2
	if s.open {
		s.ui.gg.draw_rect(s.x, s.y, s.width, s.height, ui.sw_open_bg_color)
		s.ui.gg.draw_rect(s.x - padding + s.width - ui.sw_dot_size, s.y + padding, ui.sw_dot_size,
			ui.sw_dot_size, gx.white)
	} else {
		s.ui.gg.draw_rect(s.x, s.y, s.width, s.height, ui.sw_close_bg_color)
		s.ui.gg.draw_rect(s.x + padding, s.y + padding, ui.sw_dot_size, ui.sw_dot_size,
			gx.white)
	}
	$if bb ? {
		draw_bb(s, s.ui)
	}
}

fn (s &Switch) point_inside(x f64, y f64) bool {
	return x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height
}

fn sw_click(mut s Switch, e &MouseEvent, w &Window) {
	if !s.point_inside(e.x, e.y) {
		return
	}
	// <===== mouse position test added
	if int(e.action) == 0 {
		s.open = !s.open
		if s.onclick != voidptr(0) {
			s.onclick(w.state, s)
		}
	}
}

fn (mut s Switch) set_visible(state bool) {
	s.hidden = state
}

fn (mut s Switch) focus() {
	s.is_focused = true
}

fn (mut s Switch) unfocus() {
	s.is_focused = false
}

fn (s &Switch) is_focused() bool {
	return s.is_focused
}
