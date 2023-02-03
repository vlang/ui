// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg
import time
import sokol.sapp

const (
	click_interval      = 200 // ms
	system_mouse_cursor = {
		'default':       sapp.MouseCursor.default
		'arrow':         sapp.MouseCursor.arrow
		'ibeam':         sapp.MouseCursor.ibeam
		'crosshair':     sapp.MouseCursor.crosshair
		'pointing_hand': sapp.MouseCursor.pointing_hand
		'resize_ew':     sapp.MouseCursor.resize_ew
		'resize_ns':     sapp.MouseCursor.resize_ns
		'resize_nwse':   sapp.MouseCursor.resize_nwse
		'resize_nesw':   sapp.MouseCursor.resize_nesw
		'resize_all':    sapp.MouseCursor.resize_all
		'not_allowed':   sapp.MouseCursor.not_allowed
	}
)

pub enum MouseAction {
	up
	down
}

// MouseButton is same to sapp.MouseButton
pub enum MouseButton {
	invalid = 256
	left = 0
	right = 1
	middle = 2
}

pub struct MouseEvent {
pub:
	x      int
	y      int
	button MouseButton
	action MouseAction
	mods   KeyMod
}

pub struct ScrollEvent {
pub:
	x       f64
	y       f64
	mouse_x f64
	mouse_y f64
}

pub struct MouseMoveEvent {
pub:
	x            f64
	y            f64
	mouse_button int
	// TODO enum
}

pub enum Cursor {
	hand
	arrow
	ibeam
}

// Inspiration from 2048 game

struct Pos {
mut:
	x int = -1
	y int = -1
}

struct TouchInfo {
mut:
	start  Touch
	move   Touch
	end    Touch
	button int
}

struct Touch {
mut:
	pos  Pos
	time time.Time
}

struct Mouse {
mut:
	window &Window = unsafe { nil }
	pos    Pos
	id     string
	states []string
	active bool
	size   int = 20
	adj    [2]f32
}

pub const (
	mouse_system = '_system_'
	mouse_hidden = '_hidden_mouse_'
)

pub fn (mut m Mouse) init(w &Window) {
	m.window = w
}

pub fn (mut m Mouse) update() {
	m.active = m.states.len > 0
	if m.active {
		m.id = m.states.last()
		if m.id in ['text', 'vmove'] {
			m.adj[0], m.adj[1] = 0.5, 0.5
		} else {
			m.adj[0], m.adj[1] = 0.0, 0.0
		}

		// println("update current mouse: $m.id")
	}
	ids := m.id.split(':')
	if m.id == ui.mouse_system {
		m.states.clear()
	}
	sapp.set_mouse_cursor(ui.system_mouse_cursor[if ids.len > 1 { ids[1] } else { 'default' }])
	sapp.show_mouse(ids[0] == ui.mouse_system || !m.active)
}

pub fn (mut m Mouse) start(id string) {
	if m.states.len == 0 || id != m.states.last() {
		m.states << if m.window.ui.has_img(id) || id == ui.mouse_hidden
			|| id.starts_with('_system_:') {
			id
		} else {
			ui.mouse_system
		}
		m.update()
	}
}

pub fn (mut m Mouse) stop() {
	if m.active {
		// println("stop mouse")
		m.states.delete_last()
		m.start('_system_')
		// println("${m.states}")
		m.update()
	}
}

pub fn (mut m Mouse) stop_last(id string) {
	if m.active && id == m.states.last() {
		// println("stop last mouse $id")
		m.states.delete_last()
		m.start('_system_')
		// println("${m.states}")
		m.update()
	}
}

pub fn (mut m Mouse) update_pos(x f64, y f64) {
	if m.active {
		m.pos.x, m.pos.y = int(x), int(y)
	}
}

pub fn (mut m Mouse) update_event(e &gg.Event) {
	m.pos.x, m.pos.y = int(e.mouse_x / m.window.dpi_scale), int(e.mouse_y / m.window.dpi_scale)
}

pub fn (mut m Mouse) draw() {
	m.draw_device(mut m.window.ui.dd)
}

pub fn (mut m Mouse) draw_device(mut d DrawDevice) {
	if m.active {
		m.window.ui.draw_device_img(d, m.id, m.pos.x - int(m.size * m.adj[0]), m.pos.y - int(m.size * m.adj[1]),
			m.size, m.size)
	}
}

pub fn show_mouse(state bool) {
	sapp.show_mouse(state)
}
