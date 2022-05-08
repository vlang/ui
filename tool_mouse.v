// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg
import time
import sokol.sapp

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
	window &Window
	pos    Pos
	id     string
	states []string
	active bool
	size   int = 20
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
		// println("update current mouse: $m.id")
	}
	sapp.show_mouse(m.id == ui.mouse_system || !m.active)
}

pub fn (mut m Mouse) start(id string) {
	if m.states.len == 0 || id != m.states.last() {
		m.states << if m.window.ui.has_img(id) || id == ui.mouse_hidden {
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
		// println("${m.states}")
		m.update()
	}
}

pub fn (mut m Mouse) stop_last(id string) {
	if m.active && id == m.states.last() {
		// println("stop last mouse $id")
		m.states.delete_last()
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
	m.pos.x, m.pos.y = int(e.mouse_x / m.window.ui.gg.scale), int(e.mouse_y / m.window.ui.gg.scale)
}

pub fn (mut m Mouse) draw() {
	m.draw_device(m.window.ui.gg)
}

pub fn (mut m Mouse) draw_device(d DrawDevice) {
	if m.active {
		m.window.ui.draw_device_img(d, m.id, m.pos.x, m.pos.y, m.size, m.size)
	}
}

pub fn show_mouse(state bool) {
	sapp.show_mouse(state)
}
