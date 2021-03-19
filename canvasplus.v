// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg
import eventbus

pub type CanvasPlusDrawFn = fn (c &CanvasPlus, state voidptr) // x_offset int, y_offset int)

pub struct CanvasPlus {
pub mut:
	children []Widget
	width    int
	height   int
	x        int
	y        int
	offset_x int
	offset_y int
	z_index  int
	ui       &UI = 0
	hidden   bool
	gg       &gg.Context = 0
mut:
	parent  Layout
	draw_fn CanvasPlusDrawFn = voidptr(0)
}

pub struct CanvasPlusConfig {
	width    int
	height   int
	z_index  int
	text     string
	draw_fn  CanvasPlusDrawFn = voidptr(0)
	children []Widget = []Widget{}
}

fn (mut c CanvasPlus) init(parent Layout) {
	c.parent = parent
	ui := parent.get_ui()
	c.ui = ui
	c.gg = ui.gg
}

pub fn canvas_plus(c CanvasPlusConfig) &CanvasPlus {
	mut canvas := &CanvasPlus{
		width: c.width
		height: c.height
		z_index: c.z_index
		draw_fn: c.draw_fn
		children: c.children
	}
	return canvas
}

fn (mut c CanvasPlus) set_pos(x int, y int) {
	c.x = x
	c.y = y
}

fn (mut c CanvasPlus) size() (int, int) {
	return c.width, c.height
}

fn (mut c CanvasPlus) propose_size(w int, h int) (int, int) {
	c.width = w
	c.height = h
	return c.width, c.height
}

fn (mut c CanvasPlus) draw() {
	draw_start(mut c)
	parent := c.parent
	state := parent.get_state()
	if c.draw_fn != voidptr(0) {
		c.draw_fn(c, state)
	}
	for mut child in c.children {
		child.draw()
	}
	draw_end(mut c)
}

fn (mut c CanvasPlus) set_visible(state bool) {
	c.hidden = state
}

fn (c &CanvasPlus) focus() {
}

fn (c &CanvasPlus) is_focused() bool {
	return false
}

fn (c &CanvasPlus) unfocus() {
	c.unfocus_all()
}

fn (c &CanvasPlus) point_inside(x f64, y f64) bool {
	return point_inside<CanvasPlus>(c, x, y)
}

fn (c &CanvasPlus) get_ui() &UI {
	return c.ui
}

fn (c &CanvasPlus) unfocus_all() {
	for mut child in c.children {
		child.unfocus()
	}
}

fn (c &CanvasPlus) resize(width int, height int) {
}

fn (c &CanvasPlus) get_state() voidptr {
	parent := c.parent
	return parent.get_state()
}

fn (c &CanvasPlus) get_subscriber() &eventbus.Subscriber {
	parent := c.parent
	return parent.get_subscriber()
}

fn (c &CanvasPlus) get_children() []Widget {
	return c.children
}
