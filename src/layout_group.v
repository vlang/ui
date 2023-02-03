// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
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
	is_focused    bool
	parent        Layout = empty_stack
	ui            &UI    = unsafe { nil }
	children      []Widget
	margin_left   int = 5
	margin_top    int = 10
	margin_right  int = 5
	margin_bottom int = 5
	spacing       int = 5
	adj_height    int
	adj_width     int
	hidden        bool
	clipping      bool
	// component state for composable widget
	component voidptr
	// debug stuff to be removed
	debug_ids []string
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
	clipping bool
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
		spacing: c.spacing
		clipping: c.clipping
		children: c.children
		ui: 0
	}
	return g
}

fn (mut g Group) init(parent Layout) {
	g.parent = parent
	ui := parent.get_ui()
	g.ui = ui
	g.decode_size()
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
		print('group ${g.id}')
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

fn (mut g Group) decode_size() {
	parent_width, parent_height := g.parent.size()
	// Relative sizes
	g.width = relative_size_from_parent(g.width, parent_width)
	g.height = relative_size_from_parent(g.height, parent_height)
	// }
	// println('g size: ($g.width, $g.height) ($parent_width, $parent_height) ')
	// debug_show_size(s, "decode after -> ")
}

fn (mut g Group) set_pos(x int, y int) {
	g.x = x
	g.y = y
	g.calculate_child_positions()
}

fn (mut g Group) calculate_child_positions() {
	$if gccp ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('group ccp ${g.id} size: (${g.width}, ${g.height})')
		}
	}
	mut widgets := g.children.clone()
	title_off := if g.title.len > 0 { g.margin_top / 2 } else { 0 }
	mut start_x := g.x + g.margin_left
	mut start_y := g.y + g.margin_top + title_off
	for mut widget in widgets {
		_, wid_h := widget.size()
		widget.set_pos(start_x, start_y)
		start_y = start_y + wid_h + g.spacing
	}
	$if gccp ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('group ccp2 ${g.id} size: (${g.width}, ${g.height})')
		}
	}
}

fn (mut g Group) draw() {
	g.draw_device(mut g.ui.dd)
}

fn (mut g Group) draw_device(mut d DrawDevice) {
	offset_start(mut g)
	defer {
		offset_end(mut g)
	}
	cstate := clipping_start(g, mut d) or { return }
	defer {
		clipping_end(g, mut d, cstate)
	}

	// Border
	$if gdraw ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('group ${g.id} size: (${g.width}, ${g.height})')
		}
	}
	title_off := if g.title.len > 0 { g.margin_top / 2 } else { 0 }
	d.draw_rect_empty(g.x, g.y + title_off, g.width, g.height - title_off, gx.gray)
	mut title := g.title
	mut text_width := g.ui.dd.text_width(title)
	if text_width > (g.width - check_mark_size - 3) {
		proportion := f32(g.width) / f32(text_width)
		target_len := int(math.floor(title.len * proportion)) - 5
		title = if target_len < 0 { '' } else { title.substr(0, target_len) + '..' }
		text_width = g.ui.dd.text_width(title)
	}
	// Title
	d.draw_rect_filled(g.x + check_mark_size, g.y, text_width + 5, 10, g.ui.window.bg_color)
	g.ui.dd.draw_text_def(g.x + check_mark_size + 3, g.y - 2, title)
	for mut child in g.children {
		child.draw_device(mut d)
	}
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

fn (g &Group) get_subscriber() &eventbus.Subscriber {
	parent := g.parent
	return parent.get_subscriber()
}

fn (mut g Group) set_adjusted_size(i int, ui &UI) {
	mut h, mut w := 0, 0
	for mut child in g.children {
		mut child_width, mut child_height := child.size()

		$if ui_group ? {
			println('${i} ${child.type_name()} => child_width, child_height: ${child_width}, ${child_height}')
		}

		h += child_height // height of vertical stack means adding children's height
		if child_width > w { // width of vertical stack means greatest children's width
			w = child_width
		}
	}
	h += g.spacing * (g.children.len - 1)
	g.adj_width = w
	g.adj_height = h
	$if adj_size_group ? {
		println('group ${g.id} adj size: (${g.adj_width}, ${g.adj_height})')
	}
}

fn (g &Group) adj_size() (int, int) {
	return g.adj_width, g.adj_height
}

fn (mut g Group) propose_size(w int, h int) (int, int) {
	g.width = w
	g.height = h
	// println('g prop size: ($w, $h)')
	$if gps ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('group ${g.id} propose size: (${g.width}, ${g.height})')
		}
	}
	return g.width, g.height
}

fn (g &Group) size() (int, int) {
	return g.width, g.height
}

fn (g &Group) get_children() []Widget {
	return g.children
}

fn (g &Group) update_layout() {}
