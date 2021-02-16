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
	height     				int
	width      				int
	x          				int
	y          				int
	parent     				Layout
	ui         				&UI
	val        				int
	min        				int
	max        				int
	is_focused 				bool
	bar_color  				gx.Color
	bar_border_color 		gx.Color
	background_color  		gx.Color
	background_border_color	gx.Color
}

pub struct ProgressBarConfig {
	width  int
	height int = 16
	min    int
	max    int
	val    int
	bar_color  gx.Color = progress_bar_color
	bar_border_color  gx.Color = progress_bar_border_color
	background_color  gx.Color = progress_bar_background_color
	background_border_color  gx.Color = progress_bar_background_border_color
}

fn (mut pb ProgressBar) init(parent Layout) {
	pb.parent = parent
	ui := parent.get_ui()
	pb.ui = ui
}

pub fn progressbar(c ProgressBarConfig) &ProgressBar {
	mut pb := &ProgressBar{
		height: c.height
		width: c.width
		min: c.min
		max: c.max
		val: c.val
		ui: 0
		bar_color: c.bar_color
		bar_border_color:  c.bar_border_color
		background_color:  c.background_color
		background_border_color: c.background_border_color
	}
	if pb.bar_color != progress_bar_color && pb.bar_border_color == progress_bar_border_color {
		pb.bar_border_color = pb.bar_color
	}
	if pb.background_color != progress_bar_background_color && pb.background_border_color == progress_bar_background_border_color {
		pb.background_border_color = pb.background_color
	}
	return pb
}

fn (mut pb ProgressBar) set_pos(x int, y int) {
	pb.x = x
	pb.y = y
}

fn (mut pb ProgressBar) size() (int, int) {
	return pb.width, pb.height
}

fn (mut pb ProgressBar) propose_size(w int, h int) (int, int) {
	/*
	pb.width = w
	pb.height = h
	return w, h
	*/
	if pb.width == 0 {
		pb.width = w
	}
	return pb.width, pb.height
}

fn (pb &ProgressBar) draw() {
	// Draw the background
	pb.ui.gg.draw_rect(pb.x, pb.y, pb.width, pb.height, pb.background_color)
	pb.ui.gg.draw_empty_rect(pb.x, pb.y, pb.width, pb.height, pb.background_border_color)
	// Draw the value
	width := int(f64(pb.width) * (f64(pb.val) / f64(pb.max)))
	pb.ui.gg.draw_empty_rect(pb.x, pb.y, width, pb.height, pb.bar_border_color) // gx.Black)
	pb.ui.gg.draw_rect(pb.x, pb.y, width, pb.height, pb.bar_color) // gx.Black)
}

fn (pb &ProgressBar) point_inside(x f64, y f64) bool {
	return false // x >= pb.x && x <= pb.x + pb.width && y >= pb.y && y <= pb.y + pb.height
}

fn (pb &ProgressBar) focus() {
}

fn (pb &ProgressBar) is_focused() bool {
	return pb.is_focused
}

fn (pb &ProgressBar) unfocus() {
}
