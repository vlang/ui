// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

pub struct Rectangle {
mut:
	text   string
	parent ILayouter
	x      int
	y      int
	height int
	width  int
	radius int
	border bool
	border_color gx.Color
	color  gx.Color
	ui     &UI
}

pub struct RectangleConfig {
	height int
	width  int
	color  gx.Color
	radius int = 0
	border bool = false
	border_color gx.Color = gx.Color { r: 180, g: 180, b: 190 }
	ref		&Rectangle
}

fn (r mut Rectangle)init(parent ILayouter) {
	ui := parent.get_ui()
	r.ui = ui
}

pub fn rectangle(c RectangleConfig) &Rectangle {
	rect := &Rectangle{
		height: c.height
		width: c.width
		radius: c.radius
		color: c.color
		border: c.border
		border_color: c.border_color
	}
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *rect
		return &ref
	}
	return rect
}

fn (r mut Rectangle) set_pos(x, y int) {
	r.x = x
	r.y = y
}

fn (b mut Rectangle) size() (int, int) {
	return b.width, b.height
}

fn (r mut Rectangle) propose_size(w, h int) (int, int) {
	return r.width, r.height
}

fn (r mut Rectangle) draw() {
	if r.radius > 0 {
		r.ui.gg.draw_rounded_rect(r.x, r.y, r.width, r.height, r.radius, r.color)
		if r.border { r.ui.gg.draw_empty_rounded_rect(r.x, r.y, r.width, r.height, r.radius, r.border_color) }
	} else {
		r.ui.gg.draw_rect(r.x, r.y, r.width, r.height, r.color)
		if r.border { r.ui.gg.draw_empty_rect(r.x, r.y, r.width, r.height, r.border_color) }
	}
}

fn (r &Rectangle) focus() {}

fn (r &Rectangle) is_focused() bool { return false }

fn (r &Rectangle) unfocus() {}

fn (r &Rectangle) point_inside(x, y f64) bool { return false }
