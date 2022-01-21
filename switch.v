// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
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
	sw_focus_bg_color = gx.rgb(50, 50, 50)
)

type SwitchClickFn = fn (voidptr, &Switch)

type SwitchKeyDownFn = fn (voidptr, &Switch, u32)

[heap]
pub struct Switch {
pub mut:
	id          string
	idx         int
	height      int
	width       int
	x           int
	y           int
	offset_x    int
	offset_y    int
	z_index     int
	parent      Layout = empty_stack
	is_focused  bool
	open        bool
	ui          &UI
	onclick     SwitchClickFn
	on_key_down SwitchKeyDownFn
	hidden      bool
	// component state for composable widget
	component voidptr
}

[params]
pub struct SwitchParams {
	id          string
	z_index     int
	onclick     SwitchClickFn
	on_key_down SwitchKeyDownFn
	open        bool
}

pub fn switcher(c SwitchParams) &Switch {
	mut s := &Switch{
		id: c.id
		height: ui.sw_height
		width: ui.sw_width
		z_index: c.z_index
		open: c.open
		onclick: c.onclick
		on_key_down: c.on_key_down
		ui: 0
	}
	return s
}

fn (mut s Switch) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	s.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, sw_key_down, s)
	subscriber.subscribe_method(events.on_click, sw_click, s)
}

[manualfree]
pub fn (mut s Switch) cleanup() {
	mut subscriber := s.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_key_down, s)
	subscriber.unsubscribe_method(events.on_click, s)
	unsafe { s.free() }
}

[unsafe]
pub fn (s &Switch) free() {
	$if free ? {
		print('switch $s.id')
	}
	unsafe {
		s.id.free()
		free(s)
	}
	$if free ? {
		println(' -> freed')
	}
}

pub fn (mut s Switch) set_pos(x int, y int) {
	s.x = x
	s.y = y
}

pub fn (mut s Switch) size() (int, int) {
	return s.width, s.height
}

pub fn (mut s Switch) propose_size(w int, h int) (int, int) {
	return s.width, s.height
}

fn (mut s Switch) draw() {
	offset_start(mut s)
	padding := (s.height - ui.sw_dot_size) / 2
	if s.open {
		s.ui.gg.draw_rect_filled(s.x, s.y, s.width, s.height, ui.sw_open_bg_color)
		s.ui.gg.draw_rect_filled(s.x - padding + s.width - ui.sw_dot_size, s.y + padding,
			ui.sw_dot_size, ui.sw_dot_size, gx.white)
	} else {
		s.ui.gg.draw_rect_filled(s.x, s.y, s.width, s.height, ui.sw_close_bg_color)
		s.ui.gg.draw_rect_filled(s.x + padding, s.y + padding, ui.sw_dot_size, ui.sw_dot_size,
			gx.white)
	}
	if s.is_focused {
		s.ui.gg.draw_rect_empty(s.x, s.y, s.width, s.height, ui.sw_focus_bg_color)
	}
	$if bb ? {
		debug_draw_bb_widget(mut s, s.ui)
	}
	offset_end(mut s)
}

fn (s &Switch) point_inside(x f64, y f64) bool {
	return point_inside(s, x, y)
}

fn sw_key_down(mut s Switch, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if sw_keydown ? {
		println('sw_keydown: $s.id  -> $s.hidden $s.is_focused')
	}
	if s.hidden {
		return
	}
	if !s.is_focused {
		return
	}
	if s.on_key_down != SwitchKeyDownFn(0) {
		s.on_key_down(window.state, s, e.codepoint)
	} else {
		// default behavior like click for space and enter
		if e.key in [.enter, .space] {
			// println("sw key as a click")
			s.open = !s.open
			if s.onclick != SwitchClickFn(0) {
				s.onclick(window.state, s)
			}
		}
	}
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
		if s.onclick != SwitchClickFn(0) {
			s.onclick(w.state, s)
		}
	}
}

fn (mut s Switch) set_visible(state bool) {
	s.hidden = !state
}

fn (mut s Switch) focus() {
	mut f := Focusable(s)
	f.set_focus()
}

fn (mut s Switch) unfocus() {
	s.is_focused = false
}
