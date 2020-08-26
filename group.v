// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import eventbus

pub struct Group {
pub mut:
	title         string
	height        int
	width         int
	x             int
	y             int
	parent        Layout
	ui            &UI
	children      []Widget
	margin_left   int = 5
	margin_top    int = 10
	margin_right  int = 5
	margin_bottom int = 5
	spacing       int = 5
}

pub struct GroupConfig {
pub mut:
	title  string
	x      int
	y      int
	width  int
	height int
}

fn (mut g Group) init(parent Layout) {
	g.parent = parent
	ui := parent.get_ui()
	g.ui = ui
	for child in g.children {
		child.init(g)
	}
	g.calculate_child_positions()
}

pub fn group(c GroupConfig, children []Widget) &Group {
	mut g := &Group{
		title: c.title
		x: c.x
		y: c.y
		width: c.width
		height: c.height
		children: children
		ui: 0
	}
	return g
}

fn (mut g Group) set_pos(x, y int) {
	g.x = x
	g.y = y
	g.calculate_child_positions()
}

fn (mut g Group) calculate_child_positions() {
	mut widgets := g.children
	mut start_x := g.x + g.margin_left
	mut start_y := g.y + g.margin_top
	for widget in widgets {
		mut wid_w, wid_h := widget.size()
		widget.set_pos(start_x, start_y)
		start_y = start_y + wid_h + g.spacing
		if wid_w > g.width - g.margin_left - g.margin_right {
			g.width = wid_w + g.margin_left + g.margin_right
		}
		if start_y + g.margin_bottom > g.height {
			g.height = start_y - wid_h
		}
	}
}

fn (mut g Group) propose_size(w, h int) (int, int) {
	g.width = w
	g.height = h
	return g.width, g.height
}

fn (mut g Group) draw() {
	// Border
	g.ui.gg.draw_empty_rect(g.x, g.y, g.width, g.height, gx.gray)
	// Title
	g.ui.gg.draw_rect(g.x + check_mark_size, g.y - 5, g.ui.gg.text_width(g.title) + 5,
		10, default_window_color)
	g.ui.gg.draw_text_def(g.x + check_mark_size + 3, g.y - 7, g.title)
	for child in g.children {
		child.draw()
	}
}

fn (g &Group) point_inside(x, y f64) bool {
	return x >= g.x && x <= g.x + g.width && y >= g.y && y <= g.y + g.height
}

fn (mut g Group) focus() {
}

fn (mut g Group) unfocus() {
}

fn (g &Group) is_focused() bool {
	return false
}

fn (g &Group) get_ui() &UI {
	return g.ui
}

fn (g &Group) unfocus_all() {
	for child in g.children {
		child.unfocus()
	}
}

fn (g &Group) resize(width, height int) {
}

fn (g &Group) get_state() voidptr {
	parent := g.parent
	return parent.get_state()
}

fn (g &Group) get_subscriber() &eventbus.Subscriber {
	parent := g.parent
	return parent.get_subscriber()
}

fn (g &Group) size() (int, int) {
	return g.width, g.height
}
