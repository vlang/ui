// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import freetype

const (
	progress_bar_color = gx.rgb(87, 153, 245)
	progress_bar_border_color = gx.rgb(76, 133, 213)
	progress_bar_background_color = gx.rgb(219, 219, 219)
	progress_bar_background_border_color = gx.rgb(191, 191, 191)
)

// glfw values TODO
enum Key {
	left = 263
	right = 262
	backspace = 259
	delete = 261
	tab = 258
	key_v = 86
}

enum KeyMod {
	shift = 1
	alt = 4
	super = 8
}

pub struct ProgressBar {
pub mut:
	idx        int
	height     int
	width      int
	x          int
	y          int
	parent     &Window
	ctx        &UI
	val        int
	min        int
	max        int
	is_focused bool
}

struct ProgressBarConfig {
	x      int
	y      int
	width  int
	height int=16
	min    int
	max    int
	val    int
	parent &Window
}

pub fn new_progress_bar(c ProgressBarConfig) &ProgressBar {
	mut p := &ProgressBar{
		height: c.height
		width: c.width
		x: c.x
		y: c.y
		parent: c.parent
		ctx: c.parent.ctx
		idx: c.parent.children.len
		min: c.min
		max: c.max
		val: c.val
	}
	p.parent.children << p
	return p
}

fn (b &ProgressBar) draw() {
	// Draw the gray background
	b.ctx.gg.draw_rect(b.x, b.y, b.width, b.height, progress_bar_background_color)
	b.ctx.gg.draw_empty_rect(b.x, b.y, b.width, b.height, progress_bar_background_border_color)
	// Draw the value
	width := int(f64(b.width) * (f64(b.val) / f64(b.max)))
	b.ctx.gg.draw_empty_rect(b.x, b.y, width, b.height, progress_bar_border_color) // gx.Black)
	b.ctx.gg.draw_rect(b.x, b.y, width, b.height, progress_bar_color) // gx.Black)
}

fn (b &ProgressBar) key_down(e KeyEvent) {}

fn (t &ProgressBar) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b &ProgressBar) click(e MouseEvent) {
}

fn (b &ProgressBar) focus() {
}

fn (b &ProgressBar) idx() int {
	return b.idx
}

fn (t &ProgressBar) is_focused() bool {
	return t.is_focused
}

fn (b &ProgressBar) unfocus() {
}
