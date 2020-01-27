// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

// glfw values TODO
pub enum Key {
	left = 263
	right = 262
	arrow_up = 265
	arrow_down = 264
	backspace = 259
	delete = 261
	tab = 258
	space = 32
	key_v = 86
	key_a = 65
	enter = 257
	escape = 256
	down = 2
	up = 3
}

pub enum KeyMod {
	shift = 1
	alt = 4
	super = 8
	ctrl = 2
}

pub enum KeyState {
	press = 1
	release = 0
	repeat = 2
}
