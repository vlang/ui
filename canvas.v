// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg

pub type DrawFn = fn (ctx &gg.Context, state voidptr, x_offset int, y_offset int)

pub struct Canvas {
mut:
	width   int
	height  int
	x       int
	y       int
	parent  Layout
	draw_fn DrawFn      = voidptr(0)
	gg      &gg.Context = 0
}

pub struct CanvasConfig {
	width   int
	height  int
	text    string
	draw_fn DrawFn = voidptr(0)
}

fn (mut c Canvas) init(parent Layout) {
	c.parent = parent
	c.gg = parent.get_ui().gg
}

pub fn canvas(c CanvasConfig) &Canvas {
	mut canvas := &Canvas{
		width: c.width
		height: c.height
		draw_fn: c.draw_fn
	}
	return canvas
}

fn (mut c Canvas) set_pos(x int, y int) {
	c.x = x
	c.y = y
}

fn (mut c Canvas) size() (int, int) {
	return c.width, c.height
}

fn (mut c Canvas) propose_size(w int, h int) (int, int) {
	/*
	c.width = w
	c.height = h
	return w, h
	*/
	if c.width == 0 {
		c.width = w
	}
	return c.width, c.height
}

fn (c &Canvas) draw() {
	parent := c.parent
	state := parent.get_state()
	if c.draw_fn != voidptr(0) {
		c.draw_fn(c.gg, state, c.x, c.y)
	}
}

fn (c &Canvas) focus() {
}

fn (c &Canvas) is_focused() bool {
	return false
}

fn (c &Canvas) unfocus() {
}

fn (c &Canvas) point_inside(x f64, y f64) bool {
	return false // x >= c.x && x <= c.x + c.width && y >= c.y && y <= c.y + c.height
}
