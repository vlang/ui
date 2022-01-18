// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	progress_bar_color                   = gx.rgb(87, 153, 245)
	progress_bar_border_color            = gx.rgb(76, 133, 213)
	progress_bar_background_color        = gx.rgb(219, 219, 219)
	progress_bar_background_border_color = gx.rgb(191, 191, 191)
)

[heap]
pub struct ProgressBar {
pub mut:
	id       string
	height   int
	width    int
	x        int
	y        int
	offset_x int
	offset_y int
	z_index  int
	parent   Layout = empty_stack
	ui       &UI
	val      int
	min      int
	max      int
	hidden   bool
	// component state for composable widget
	component voidptr
}

[params]
pub struct ProgressBarParams {
	id      string
	width   int
	height  int = 16
	z_index int
	min     int
	max     int
	val     int
}

pub fn progressbar(c ProgressBarParams) &ProgressBar {
	mut pb := &ProgressBar{
		id: c.id
		height: c.height
		width: c.width
		z_index: c.z_index
		min: c.min
		max: c.max
		val: c.val
		ui: 0
	}
	return pb
}

fn (mut pb ProgressBar) init(parent Layout) {
	pb.parent = parent
	ui := parent.get_ui()
	pb.ui = ui
}

[manualfree]
pub fn (mut pb ProgressBar) cleanup() {
	unsafe { pb.free() }
}

[unsafe]
pub fn (pb &ProgressBar) free() {
	$if free ? {
		print('progress_bar $pb.id')
	}
	unsafe {
		pb.id.free()
		free(pb)
	}
	$if free ? {
		println(' -> freed')
	}
}

pub fn (mut pb ProgressBar) set_pos(x int, y int) {
	pb.x = x
	pb.y = y
}

pub fn (mut pb ProgressBar) size() (int, int) {
	return pb.width, pb.height
}

pub fn (mut pb ProgressBar) propose_size(w int, h int) (int, int) {
	/*
	pb.width = w
	pb.height = h
	return w, h
	*/
	pb.width = w
	pb.height = h
	return pb.width, pb.height
}

fn (mut pb ProgressBar) draw() {
	offset_start(mut pb)
	// Draw the gray background
	pb.ui.gg.draw_rect_filled(pb.x, pb.y, pb.width, pb.height, ui.progress_bar_background_color)
	pb.ui.gg.draw_rect_empty(pb.x, pb.y, pb.width, pb.height, ui.progress_bar_background_border_color)
	// Draw the value
	width := int(f64(pb.width) * (f64(pb.val) / f64(pb.max)))
	pb.ui.gg.draw_rect_empty(pb.x, pb.y, width, pb.height, ui.progress_bar_border_color) // gx.Black)
	pb.ui.gg.draw_rect_filled(pb.x, pb.y, width, pb.height, ui.progress_bar_color) // gx.Black)
	$if bb ? {
		draw_bb(mut pb, pb.ui)
	}
	offset_end(mut pb)
}

fn (pb &ProgressBar) point_inside(x f64, y f64) bool {
	return point_inside(pb, x, y)
}

fn (mut pb ProgressBar) set_visible(state bool) {
	pb.hidden = !state
}
