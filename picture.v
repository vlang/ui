// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import os
import gg

pub struct Picture {
pub:
	offset_x  int
	offset_y  int
mut:
	text      string
	parent    Layout
	x         int
	y         int
	width     int
	height    int
	path      string
	ui       &UI
	texture   u32
	use_cache bool
}

pub struct PictureConfig {
	path       string
	width      int
	height     int
	use_cache  bool = true
	ref       &Picture = 0
}

fn (mut pic Picture)init(parent Layout) {
	mut ui := parent.get_ui()
	pic.ui = ui
	if !pic.use_cache && pic.path in ui.resource_cache {
		pic.texture = ui.resource_cache[pic.path]
	} else {
		texture := gg.create_image(pic.path)
		pic.texture = texture
		ui.resource_cache[pic.path] = texture
	}
}

pub fn picture(c PictureConfig) &Picture {
	if !os.exists(c.path) {
		println('V UI: picture file "$c.path" not found')
	}
	mut pic := &Picture{
		width: c.width
		height: c.height
		path: c.path
		use_cache: c.use_cache
		ui: 0
	}
	return pic
}

fn (mut b Picture) set_pos(x, y int) {
	b.x = x + b.offset_x
	b.y = y + b.offset_y
}

fn (mut b Picture) size() (int, int) {
	return b.width, b.height
}

fn (mut b Picture) propose_size(w, h int) (int, int) {
	//b.width = w
	//b.height = h
	return b.width, b.height
}

fn (mut b Picture) draw() {
	b.ui.gg.draw_image(b.x, b.y, b.width, b.height, b.texture)
}

fn (t &Picture) focus() {}

fn (t &Picture) is_focused() bool {
	return false
}

fn (t &Picture) unfocus() {}

fn (t &Picture) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}
