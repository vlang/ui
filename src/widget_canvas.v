// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg

pub type DrawFn = fn (ctx &gg.Context, c &Canvas) // x_offset int, y_offset int)

[heap]
pub struct Canvas {
pub mut:
	id       string
	width    int
	height   int
	x        int
	y        int
	offset_x int
	offset_y int
	z_index  int
	ui       &UI = unsafe { nil }
	hidden   bool
	clipping bool
	// component state for composable widget
	component voidptr
mut:
	parent  Layout = empty_stack
	draw_fn DrawFn = unsafe { nil }
}

[params]
pub struct CanvasParams {
	id       string
	width    int
	height   int
	z_index  int
	text     string
	draw_fn  DrawFn = unsafe { nil }
	clipping bool
}

pub fn canvas(c CanvasParams) &Canvas {
	mut canvas := &Canvas{
		id: c.id
		width: c.width
		height: c.height
		z_index: c.z_index
		draw_fn: c.draw_fn
		clipping: c.clipping
	}
	return canvas
}

fn (mut c Canvas) init(parent Layout) {
	c.parent = parent
	ui := parent.get_ui()
	c.ui = ui
}

[manualfree]
pub fn (mut c Canvas) cleanup() {
	unsafe { c.free() }
}

[unsafe]
pub fn (c &Canvas) free() {
	$if free ? {
		print('canvas ${c.id}')
	}
	unsafe {
		c.id.free()
		free(c)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (mut c Canvas) set_pos(x int, y int) {
	c.x = x
	c.y = y
}

fn (mut c Canvas) size() (int, int) {
	return c.width, c.height
}

fn (mut c Canvas) propose_size(w int, h int) (int, int) {
	c.width = w
	c.height = h
	return c.width, c.height
}

fn (mut c Canvas) draw() {
	c.draw_device(mut c.ui.dd)
}

fn (mut c Canvas) draw_device(mut d DrawDevice) {
	if c.hidden {
		return
	}
	offset_start(mut c)
	defer {
		offset_end(mut c)
	}
	cstate := clipping_start(c, mut d) or { return }
	defer {
		clipping_end(c, mut d, cstate)
	}

	if c.draw_fn != unsafe { nil } {
		if mut c.ui.dd is DrawDeviceContext {
			c.draw_fn(&c.ui.dd.Context, c)
		}
	}
}

fn (mut c Canvas) set_visible(state bool) {
	c.hidden = !state
}

fn (c &Canvas) point_inside(x f64, y f64) bool {
	return point_inside(c, x, y)
}
