// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

// glfw values TODO
pub enum Key {
	left = 263
	right = 262
	arrow_up = 264
	arrow_down = 265
	backspace = 259
	delete = 261
	tab = 258
	key_v = 86
	key_a = 65
	escape = 1
	down = 2
	up = 3
}

pub enum KeyMod {
	shift = 1
	alt = 4
	super = 8
}

pub enum KeyState {
	press = 1
	release = 0
	repeat = 2
}