// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import os
import gg

pub struct Picture {
mut:
	text    string
	parent ILayouter
	x       int
	y       int
	width   int
	height  int
	
	ui      &UI
	texture u32
}

pub struct PictureConfig {
	path   string
	width  int
	height int
	ref		&Picture
}

fn (pic mut Picture)init(p &ILayouter) {
	parent := *p
	ui := parent.get_ui()
	pic.ui = ui
}

pub fn picture(c PictureConfig) &Picture {
	if !os.exists(c.path) {
		println('V UI: picture file "$c.path" not found')
	}
	mut pic := &Picture{
		width: c.width
		height: c.height
		texture: gg.create_image(c.path)
	}
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *pic
		return &ref
	}
	return pic
}

fn (b mut Picture) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut Picture) propose_size(w, h int) (int, int) {
	//b.width = w
	//b.height = h
	return b.width, b.height
}

fn (b mut Picture) draw() {
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
