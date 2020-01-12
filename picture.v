// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import os
import gg

struct Picture {
mut:
	text    string
	parent  &ui.Window
	x       int
	y       int
	width   int
	height  int
	idx     int
	ctx     &UI
	texture u32
}

pub struct PictureConfig {
	x      int
	y      int
	parent &ui.Window
	path   string
	width  int
	height int
}

pub fn new_picture(c PictureConfig) &Picture {
	if !os.exists(c.path) {
		println('V UI: picture file "$c.path" not found')
	}
	mut pic := &Picture{
		x: c.x
		y: c.y
		width: c.width
		height: c.height
		parent: c.parent
		ctx: c.parent.ctx
	}
	pic.parent.children << pic
	pic.texture = gg.create_image(c.path)
	return pic
}

fn (b mut Picture) draw() {
	b.ctx.gg.draw_image(b.x, b.y, b.width, b.height, b.texture)
}

fn (t &Picture) key_down(e KeyEvent) {}

fn (t &Picture) click(e MouseEvent) {
}

fn (t &Picture) focus() {}

fn (t &Picture) idx() int {
	return t.idx
}

fn (t &Picture) is_focused() bool {
	return false
}

fn (t &Picture) unfocus() {}

fn (t &Picture) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}
