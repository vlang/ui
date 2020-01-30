// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	progress_bar_color = gx.rgb(87, 153, 245)
	progress_bar_border_color = gx.rgb(76, 133, 213)
	progress_bar_background_color = gx.rgb(219, 219, 219)
	progress_bar_background_border_color = gx.rgb(191, 191, 191)
)

pub struct ProgressBar {
pub mut:
	height     int
	width      int
	x          int
	y          int
	parent ILayouter
	ui         &UI
	val        int
	min        int
	max        int
	is_focused bool
}

pub struct ProgressBarConfig {
	width  int
	height int=16
	min    int
	max    int
	val    int
	ref		&ProgressBar
}

fn (pb mut ProgressBar)init(p &ILayouter) {
	parent := *p
	pb.parent = parent
	ui := parent.get_ui()
	pb.ui = ui
}

pub fn progressbar(c ProgressBarConfig) &ProgressBar {
	mut p := &ProgressBar{
		height: c.height
		width: c.width
		min: c.min
		max: c.max
		val: c.val
	}
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *p
		return &ref
	}
	return p
}

fn (b mut ProgressBar) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut ProgressBar) set_size(w, h int) {
	b.width = w
}

fn (b mut ProgressBar) propose_size(w, h int) (int, int) {
	/* b.width = w
	b.height = h
	return w, h */
	if b.width == 0 {
		b.width = w
	}
	return b.width, b.height
}

fn (b &ProgressBar) draw() {
	// Draw the gray background
	b.ui.gg.draw_rect(b.x, b.y, b.width, b.height, progress_bar_background_color)
	b.ui.gg.draw_empty_rect(b.x, b.y, b.width, b.height, progress_bar_background_border_color)
	// Draw the value
	width := int(f64(b.width) * (f64(b.val) / f64(b.max)))
	b.ui.gg.draw_empty_rect(b.x, b.y, width, b.height, progress_bar_border_color) // gx.Black)
	b.ui.gg.draw_rect(b.x, b.y, width, b.height, progress_bar_color) // gx.Black)
}

fn (t &ProgressBar) point_inside(x, y f64) bool {
	return false//x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b &ProgressBar) focus() {
}

fn (t &ProgressBar) is_focused() bool {
	return t.is_focused
}

fn (b &ProgressBar) unfocus() {
}
