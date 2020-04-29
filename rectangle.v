// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import freetype

pub struct Rectangle {
mut:
	text         string
	parent       ILayouter
	x            int
	y            int
	height       int
	width        int
	radius       int
	border       bool
	border_color gx.Color
	color        gx.Color
	ui           &UI
}

pub struct RectangleConfig {
	text         string
	height       int
	width        int
	color        gx.Color
	radius       int=0
	border       bool=false
	border_color gx.Color=gx.Color {
		r: 180
		g: 180
		b: 190
	}
	ref          &Rectangle
	x	int
	y	int
}

fn (r mut Rectangle) init(parent ILayouter) {
	ui := parent.get_ui()
	r.ui = ui
}

pub fn rectangle(c RectangleConfig) &Rectangle {
	rect := &Rectangle{
		text: c.text
		height: c.height
		width: c.width
		radius: c.radius
		color: c.color
		border: c.border
		border_color: c.border_color
		x:c.x
		y:c.y
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

fn (b mut Rectangle) size() (int,int) {
	return b.width,b.height
}

fn (r mut Rectangle) propose_size(w, h int) (int,int) {
	return r.width,r.height
}

fn (r mut Rectangle) draw() {
	if r.radius > 0 {
		r.ui.gg.draw_rounded_rect(r.x, r.y, r.width, r.height, r.radius, r.color)
		if r.border {
			r.ui.gg.draw_empty_rounded_rect(r.x, r.y, r.width, r.height, r.radius, r.border_color)
		}
	}
	else {
		r.ui.gg.draw_rect(r.x, r.y, r.width, r.height, r.color)
		if r.border {
			r.ui.gg.draw_empty_rect(r.x, r.y, r.width, r.height, r.border_color)
		}
	}
	text_cfg := gx.TextCfg{
		color: gx.red
		size: freetype.default_font_size
		align: gx.ALIGN_LEFT
		max_width: r.x + r.width
	}
	// Display rectangle text
	if r.text != '' {
		text_width,text_height := r.ui.ft.text_size(r.text)
		mut dx := (r.width - text_width) / 2
		mut dy := (r.height - text_height) / 2
		if dx < 0 {
			dx = 0
		}
		if dy < 0 {
			dy = 0
		}
		r.ui.ft.draw_text(r.x + dx, r.y + dy, r.text, text_cfg)
	}
}

fn (r &Rectangle) focus() {}

fn (r &Rectangle) is_focused() bool {
	return false
}

fn (r &Rectangle) unfocus() {}

fn (r &Rectangle) point_inside(x, y f64) bool {
	return false
}
