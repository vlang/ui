// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import math
import gx
import eventbus

[heap]
pub struct Group {
pub mut:
	id            string
	title         string
	height        int
	width         int
	x             int
	y             int
	offset_x      int
	offset_y      int
	z_index       int
	parent        Layout = empty_stack
	ui            &UI
	children      []Widget
	margin_left   int = 5
	margin_top    int = 10
	margin_right  int = 5
	margin_bottom int = 5
	spacing       int = 5
	adj_height    int
	adj_width     int
	hidden        bool
	// component state for composable widget
	component voidptr
}

[params]
pub struct GroupParams {
pub mut:
	id       string
	title    string
	x        int
	y        int
	width    int
	height   int
	spacing  int = 5
	children []Widget
}

pub fn group(c GroupParams) &Group {
	mut g := &Group{
		id: c.id
		title: c.title
		x: c.x
		y: c.y
		width: c.width
		height: c.height
		children: c.children
		spacing: c.spacing
		ui: 0
	}
	return g
}

fn (mut g Group) init(parent Layout) {
	g.parent = parent
	ui := parent.get_ui()
	g.ui = ui
	g.decode_size(parent)
	for mut child in g.children {
		child.init(g)
	}
	g.calculate_child_positions()
}

[manualfree]
pub fn (mut g Group) cleanup() {
	for mut child in g.children {
		child.cleanup()
	}
	unsafe {
		g.free()
	}
}

[unsafe]
pub fn (g &Group) free() {
	$if free ? {
		print('group $g.id')
	}
	unsafe {
		g.id.free()
		g.title.free()
		g.children.free()
		free(g)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (mut g Group) decode_size(parent Layout) {
	parent_width, parent_height := parent.size()
	// s.debug_show_sizes("decode before -> ")
	// if parent is Window {
	// 	// Default: like stretch = strue
	// 	s.height = parent_height - s.margin.top - s.margin.right
	// 	s.width = parent_width - s.margin.left - s.margin.right
	// } else
	// if g.stretch {
	// 	g.height = parent_height - g.margin_top - g.margin_right
	// 	g.width = parent_width - g.margin_left - g.margin_right
	// } else {
	// Relative sizes
	g.width = relative_size_from_parent(g.width, parent_width)
	g.height = relative_size_from_parent(g.height, parent_height)
	// }
	println('g size: ($g.width, $g.height) ($parent_width, $parent_height) ')
	// s.debug_show_size("decode after -> ")
}

fn (mut g Group) set_pos(x int, y int) {
	g.x = x
	g.y = y
	g.calculate_child_positions()
}

fn (mut g Group) calculate_child_positions() {
	mut widgets := g.children
	mut start_x := g.x + g.margin_left
	mut start_y := g.y + g.margin_top
	for mut widget in widgets {
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

fn (mut g Group) propose_size(w int, h int) (int, int) {
	g.width = w
	g.height = h
	println('g prop size: ($w, $h)')
	return g.width, g.height
}

fn (mut g Group) draw() {
	offset_start(mut g)
	// Border
	g.ui.gg.draw_rect_empty(g.x, g.y, g.width, g.height, gx.gray)
	mut title := g.title
	mut text_width := g.ui.gg.text_width(title)
	if text_width > (g.width - check_mark_size - 3) {
		proportion := f32(g.width) / f32(text_width)
		target_len := int(math.floor(title.len * proportion)) - 5
		title = if target_len < 0 { '' } else { title.substr(0, target_len) + '..' }
		text_width = g.ui.gg.text_width(title)
	}
	// Title
	g.ui.gg.draw_rect_filled(g.x + check_mark_size, g.y - 5, text_width + 5, 10, g.ui.window.bg_color)
	g.ui.gg.draw_text_def(g.x + check_mark_size + 3, g.y - 7, title)
	for mut child in g.children {
		child.draw()
	}
	offset_end(mut g)
}

fn (g &Group) point_inside(x f64, y f64) bool {
	return point_inside(g, x, y)
}

fn (mut g Group) set_visible(state bool) {
	g.hidden = !state
}

fn (g &Group) get_ui() &UI {
	return g.ui
}

fn (g &Group) resize(width int, height int) {
}

fn (g &Group) get_state() voidptr {
	parent := g.parent
	return parent.get_state()
}

fn (g &Group) get_subscriber() &eventbus.Subscriber {
	parent := g.parent
	return parent.get_subscriber()
}

fn (g &Group) adj_size() (int, int) {
	return g.adj_width, g.adj_height
}

fn (g &Group) size() (int, int) {
	return g.width, g.height
}

fn (g &Group) get_children() []Widget {
	return g.children
}

fn (g &Group) update_layout() {}

fn (mut g Group) set_adjusted_size(i int, ui &UI) {
	mut h := 0
	mut w := 0
	for mut child in g.children {
		mut child_width, mut child_height := child.size()

		$if ui_group ? {
			println('$i $child.type_name() => child_width, child_height: $child_width, $child_height')
		}

		h += child_height // height of vertical stack means adding children's height
		if child_width > w { // width of vertical stack means greatest children's width
			w = child_width
		}
	}
	h += g.spacing * (g.children.len - 1)
	g.adj_width = w
	g.adj_height = h
	$if adj_size ? {
		println('group $g.id adj size: ($g.adj_width, $g.adj_height)')
	}
}
