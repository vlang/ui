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

[heap]
pub struct Switch {
pub mut:
	id         string
	idx        int
	height     int
	width      int
	x          int
	y          int
	offset_x   int
	offset_y   int
	z_index    int
	parent     Layout
	is_focused bool
	open       bool
	ui         &UI
	onclick    SwitchClickFn
	hidden     bool
	// component state for composable widget
	component voidptr
}

pub struct SwitchConfig {
	id      string
	z_index int
	onclick SwitchClickFn
	open    bool
}

pub fn switcher(c SwitchConfig) &Switch {
	mut s := &Switch{
		id: c.id
		height: ui.sw_height
		width: ui.sw_width
		z_index: c.z_index
		open: c.open
		onclick: c.onclick
		ui: 0
	}
	return s
}

fn (mut s Switch) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	s.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, sw_click, s)
}

[manualfree]
pub fn (mut s Switch) cleanup() {
	mut subscriber := s.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, s)
	unsafe { s.free() }
}

[unsafe]
pub fn (s &Switch) free() {
	unsafe {
		s.id.free()
		free(s)
	}
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
	offset_start(mut s)
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
		draw_bb(mut s, s.ui)
	}
	offset_end(mut s)
}

fn (s &Switch) point_inside(x f64, y f64) bool {
	return point_inside(s, x, y)
}

fn sw_click(mut s Switch, e &MouseEvent, w &Window) {
	if s.hidden {
		return
	}
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
	s.hidden = !state
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
