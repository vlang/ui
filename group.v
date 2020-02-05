// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

pub struct Group {
pub mut:
	title          string
	height         int
	width          int
	x              int
	y              int
	parent ILayouter
	ui             &UI
	children []IWidgeter
}

pub struct GroupConfig {
pub mut:
	title  string
	x          int
	y          int
	width  int
	height int
	children []IWidgeter
}

fn (r mut Group)init(p &ILayouter) {
	parent := *p
	r.parent = parent
	ui := parent.get_ui()
	r.ui = ui
	
	for child in r.children {
		child.init(p)
	}
}

pub fn group(c GroupConfig) &Group {
	mut cb := &Group{
		title: c.title
		x: c.x
		y:c.y
		width: c.width
		height: c.height
		children: c.children
	}
	return cb
}

fn (g mut Group) set_pos(x, y int) {
	g.x = x
	g.y = y
}

fn (g mut Group) propose_size(w, h int) (int, int) {
	g.width = w
	g.height = h
	return g.width, g.height
}

fn (b mut Group) draw() {
	// Border
	b.ui.gg.draw_empty_rect(b.x, b.y, b.width, b.height, gx.gray)
	// Title
	b.ui.gg.draw_rect(b.x + check_mark_size, b.y - 5, b.ui.ft.text_width(b.title) + 5, 10, default_window_color)
	b.ui.ft.draw_text_def(b.x + check_mark_size + 3, b.y - 7, b.title)

	for child in b.children {
		child.draw()
	}
}

fn (t &Group) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b mut Group) focus() {
}

fn (b mut Group) unfocus() {
}

fn (t &Group) is_focused() bool {
	return false
}
