// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import gx

const sw_height = 20
const sw_width = 40
const sw_dot_size = 16
const sw_open_bg_color = gx.rgb(19, 206, 102)
const sw_close_bg_color = gx.rgb(220, 223, 230)
const sw_focus_bg_color = gx.rgb(50, 50, 50)

type SwitchFn = fn (&Switch)

type SwitchU32Fn = fn (&Switch, u32)

@[heap]
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
	ui          &UI         = unsafe { nil }
	on_click    SwitchFn    = unsafe { nil }
	on_key_down SwitchU32Fn = unsafe { nil }
	hidden      bool
	// component state for composable widget
	component voidptr
}

@[params]
pub struct SwitchParams {
pub:
	id          string
	z_index     int
	on_click    SwitchFn    = unsafe { nil }
	on_key_down SwitchU32Fn = unsafe { nil }
	open        bool
}

pub fn switcher(c SwitchParams) &Switch {
	mut s := &Switch{
		id:          c.id
		height:      sw_height
		width:       sw_width
		z_index:     c.z_index
		open:        c.open
		on_click:    c.on_click
		on_key_down: c.on_key_down
		ui:          unsafe { nil }
	}
	return s
}

fn (mut s Switch) init(parent Layout) {
	s.parent = parent
	u := parent.get_ui()
	s.ui = u
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, sw_key_down, s)
	subscriber.subscribe_method(events.on_click, sw_click, s)
}

@[manualfree]
pub fn (mut s Switch) cleanup() {
	mut subscriber := s.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_key_down, s)
	subscriber.unsubscribe_method(events.on_click, s)
	unsafe { s.free() }
}

@[unsafe]
pub fn (s &Switch) free() {
	$if free ? {
		print('switch ${s.id}')
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
	s.draw_device(mut s.ui.dd)
}

fn (mut s Switch) draw_device(mut d DrawDevice) {
	offset_start(mut s)
	$if layout ? {
		if s.ui.layout_print {
			println('Switch(${s.id}): (${s.x}, ${s.y}, ${s.width}, ${s.height})')
		}
	}
	padding := (s.height - sw_dot_size) / 2
	if s.open {
		d.draw_rect_filled(s.x, s.y, s.width, s.height, sw_open_bg_color)
		d.draw_rect_filled(s.x - padding + s.width - sw_dot_size, s.y + padding, sw_dot_size,
			sw_dot_size, gx.white)
	} else {
		d.draw_rect_filled(s.x, s.y, s.width, s.height, sw_close_bg_color)
		d.draw_rect_filled(s.x + padding, s.y + padding, sw_dot_size, sw_dot_size, gx.white)
	}
	if s.is_focused {
		d.draw_rect_empty(s.x, s.y, s.width, s.height, sw_focus_bg_color)
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
		println('sw_keydown: ${s.id}  -> ${s.hidden} ${s.is_focused}')
	}
	if s.hidden {
		return
	}
	if !s.is_focused {
		return
	}
	if s.on_key_down != unsafe { SwitchU32Fn(0) } {
		s.on_key_down(s, e.codepoint)
	} else {
		// default behavior like click for space and enter
		if e.key in [.enter, .space] {
			// println("sw key as a click")
			s.open = !s.open
			if s.on_click != unsafe { SwitchFn(0) } {
				s.on_click(s)
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
		if s.on_click != unsafe { SwitchFn(0) } {
			s.on_click(s)
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
