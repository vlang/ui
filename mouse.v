// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import time

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

