// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub type DrawFn fn(voidptr)

pub struct Canvas {
mut:
	width int
	height int
	x		int
	y		int
	parent ILayouter
	draw_fn DrawFn
	
}

pub struct CanvasConfig {
	width int
	height int
	text   string
	draw_fn DrawFn
}

fn (c mut Canvas)init(p &ILayouter) {
	parent := *p
	c.parent = parent
}

pub fn canvas(c CanvasConfig) &Canvas {
	mut canvas := &Canvas{
		width: c.width
		height: c.height
		draw_fn: c.draw_fn
	}
	return canvas
}

fn (b mut Canvas) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut Canvas) size() (int,int) {
	return b.width, b.height
}

fn (b mut Canvas) propose_size(w, h int) (int, int) {
	/* b.width = w
	b.height = h
	return w, h */
	if b.width == 0 {
		b.width = w
	}
	return b.width, b.height
}

fn (c mut Canvas) draw() {
	parent := c.parent
	user_ptr := parent.get_user_ptr()
	c.draw_fn(user_ptr)
}

fn (t &Canvas) focus() {}

fn (t &Canvas) is_focused() bool {
	return false
}

fn (t &Canvas) unfocus() {}

fn (t &Canvas) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

