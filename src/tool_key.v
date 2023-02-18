// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub fn parse_shortcut(s string) (KeyMod, int, string) {
	mods, key := parse_mods_shortcut(s)
	code := parse_key(key)
	// N.B.: if code == 0 => char mode shortcut
	$if parse_shortcut ? {
		println([mods.str(), code.str(), key])
	}
	return mods, code, key
}

fn parse_mods_shortcut(s string) (KeyMod, string) {
	parts := s.split('+')
	mut mods := 0
	if parts.len > 1 {
		for mut part in parts[0..(parts.len - 1)] {
			match part.trim_space().to_lower() {
				'shift' { mods += 1 << 0 }
				'ctrl' { mods += 1 << 1 }
				'alt' { mods += 1 << 2 }
				'super' { mods += 1 << 3 }
				else {}
			}
		}
	}
	return unsafe { KeyMod(mods) }, parts[parts.len - 1].trim_space().to_lower()
}

pub fn parse_char_key(key_str string) int {
	key_rune := key_str.runes()[0]
	key := match key_rune {
		`a`...`z` { int(Key.a) + int(key_rune) - int(`a`) }
		else { int(Key.invalid) }
	}
	return key
}

// parse ley
pub fn parse_key(key_str string) int {
	mut key := match key_str {
		'escape' { int(Key.escape) }
		'enter' { int(Key.enter) }
		'tab' { int(Key.tab) }
		'backspace' { int(Key.backspace) }
		'insert' { int(Key.insert) }
		'delete' { int(Key.delete) }
		'right' { int(Key.right) }
		'left' { int(Key.left) }
		'down' { int(Key.down) }
		'up' { int(Key.up) }
		'page_up' { int(Key.page_up) }
		'page_down' { int(Key.page_down) }
		'home' { int(Key.home) }
		'end' { int(Key.end) }
		'f1' { int(Key.f1) }
		'f2' { int(Key.f2) }
		'f3' { int(Key.f3) }
		'f4' { int(Key.f4) }
		'f5' { int(Key.f5) }
		'f6' { int(Key.f6) }
		'f7' { int(Key.f7) }
		'f8' { int(Key.f8) }
		'f9' { int(Key.f9) }
		'f10' { int(Key.f10) }
		'f11' { int(Key.f11) }
		'f12' { int(Key.f12) }
		'f13' { int(Key.f13) }
		'f14' { int(Key.f14) }
		'f15' { int(Key.f15) }
		'f16' { int(Key.f16) }
		'f17' { int(Key.f17) }
		'f18' { int(Key.f18) }
		'f19' { int(Key.f19) }
		'f20' { int(Key.f20) }
		'f21' { int(Key.f21) }
		'f22' { int(Key.f22) }
		'f23' { int(Key.f23) }
		'f24' { int(Key.f24) }
		'f25' { int(Key.f25) }
		else { int(Key.invalid) }
	}
	$if windows {
		if key == 0 {
			key = parse_char_key(key_str)
		}
	}
	return key
}

// BitMask

[flag]
pub enum KeyMod {
	shift //= 1 // (1<<0)
	ctrl //= 2 // (1<<1)
	alt //= 4 // (1<<2)
	super //= 8 // (1<<3)
}

pub enum KeyState {
	release
	press
	repeat
}

pub struct KeyEvent {
pub:
	key       Key
	action    int
	code      int
	mods      KeyMod
	codepoint u32
}

// Copied from sapp/enums TODO alias?
// QWERTY keyboard (TODO add AZERTY and other layouts)
pub enum Key {
	invalid = 0
	space = 32
	apostrophe = 39 // '
	comma = 44 // ,
	minus = 45 // -
	period = 46 // .
	slash = 47 // /
	_0 = 48
	_1 = 49
	_2 = 50
	_3 = 51
	_4 = 52
	_5 = 53
	_6 = 54
	_7 = 55
	_8 = 56
	_9 = 57
	semicolon = 59 // ;
	equal = 61 // =
	a = 65
	b = 66
	c = 67
	d = 68
	e = 69
	f = 70
	g = 71
	h = 72
	i = 73
	j = 74
	k = 75
	l = 76
	m = 77
	n = 78
	o = 79
	p = 80
	q = 81
	r = 82
	s = 83
	t = 84
	u = 85
	v = 86
	w = 87
	x = 88
	y = 89
	z = 90
	left_bracket = 91 // [
	backslash = 92 // \
	right_bracket = 93 // ]
	grave_accent = 96 // `
	world_1 = 161 // non-us #1
	world_2 = 162 // non-us #2
	escape = 256
	enter = 257
	tab = 258
	backspace = 259
	insert = 260
	delete = 261
	right = 262
	left = 263
	down = 264
	up = 265
	page_up = 266
	page_down = 267
	home = 268
	end = 269
	caps_lock = 280
	scroll_lock = 281
	num_lock = 282
	print_screen = 283
	pause = 284
	f1 = 290
	f2 = 291
	f3 = 292
	f4 = 293
	f5 = 294
	f6 = 295
	f7 = 296
	f8 = 297
	f9 = 298
	f10 = 299
	f11 = 300
	f12 = 301
	f13 = 302
	f14 = 303
	f15 = 304
	f16 = 305
	f17 = 306
	f18 = 307
	f19 = 308
	f20 = 309
	f21 = 310
	f22 = 311
	f23 = 312
	f24 = 313
	f25 = 314
	kp_0 = 320
	kp_1 = 321
	kp_2 = 322
	kp_3 = 323
	kp_4 = 324
	kp_5 = 325
	kp_6 = 326
	kp_7 = 327
	kp_8 = 328
	kp_9 = 329
	kp_decimal = 330
	kp_divide = 331
	kp_multiply = 332
	kp_subtract = 333
	kp_add = 334
	kp_enter = 335
	kp_equal = 336
	left_shift = 340
	left_control = 341
	left_alt = 342
	left_super = 343
	right_shift = 344
	right_control = 345
	right_alt = 346
	right_super = 347
	menu = 348
}

pub fn shift_key(mods KeyMod) bool {
	return int(mods) & 1 == 1
}

pub fn ctrl_key(mods KeyMod) bool {
	return int(mods) & 2 == 2
}

pub fn alt_key(mods KeyMod) bool {
	return int(mods) & 4 == 4
}

pub fn super_key(mods KeyMod) bool {
	return int(mods) & 8 == 8
}

pub fn ctl_shift_key(mods KeyMod) bool {
	return int(mods) & 3 == 3
}

pub fn ctl_alt_key(mods KeyMod) bool {
	return int(mods) & 6 == 6
}

pub fn super_alt_key(mods KeyMod) bool {
	return int(mods) & 12 == 12
}

pub fn has_key_mods(mods KeyMod, opts KeyMod) bool {
	return int(mods) & int(opts) == int(opts)
}

// NB: to complete if useful
