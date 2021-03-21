// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg
import gx
import eventbus

pub type CanvasPlusDrawFn = fn (c &CanvasPlus, state voidptr) // x_offset int, y_offset int)

pub struct CanvasPlus {
pub mut:
	children   []Widget
	width      int
	height     int
	x          int
	y          int
	offset_x   int
	offset_y   int
	z_index    int
	ui         &UI = 0
	hidden     bool
	adj_width  int
	adj_height int
mut:
	parent  Layout
	draw_fn CanvasPlusDrawFn = voidptr(0)
}

pub struct CanvasPlusConfig {
	width    int
	height   int
	z_index  int
	text     string
	draw_fn  CanvasPlusDrawFn = voidptr(0)
	children []At = []At{}
}

fn (mut c CanvasPlus) init(parent Layout) {
	c.parent = parent
	ui := parent.get_ui()
	c.ui = ui
	for mut child in c.children {
		child.init(c)
	}
	c.set_adjusted_size(ui)
}

pub fn canvas_plus(c CanvasPlusConfig) &CanvasPlus {
	mut children := []Widget{}
	for child in c.children {
		mut widget := child.widget
		widget.x = child.x
		widget.y = child.y
		children << widget
	}
	mut canvas := &CanvasPlus{
		width: c.width
		height: c.height
		z_index: c.z_index
		draw_fn: c.draw_fn
		children: children
	}
	return canvas
}

fn (mut c CanvasPlus) set_adjusted_size(ui &UI) {
	mut h := 0
	mut w := 0
	for mut child in c.children {
		child_width, child_height := child.size()

		if child_width > w {
			w = child_width
		}
		if child_height > w {
			w = child_height
		}
	}
	c.adj_width = w
	c.adj_height = h
}

fn (mut c CanvasPlus) set_pos(x int, y int) {
	c.x = x
	c.y = y
}

fn (mut c CanvasPlus) size() (int, int) {
	return c.width, c.height
}

fn (mut c CanvasPlus) propose_size(w int, h int) (int, int) {
	c.width = w
	c.height = h
	return c.width, c.height
}

fn (mut c CanvasPlus) draw() {
	offset_start(mut c)
	parent := c.parent
	state := parent.get_state()
	if c.draw_fn != voidptr(0) {
		c.draw_fn(c, state)
	}
	for mut child in c.children {
		set_offset(mut child, c.x + c.offset_x, c.y + c.offset_y)
		child.draw()
	}
	offset_end(mut c)
}

fn (mut c CanvasPlus) set_visible(state bool) {
	c.hidden = state
}

fn (c &CanvasPlus) focus() {
}

fn (c &CanvasPlus) is_focused() bool {
	return false
}

fn (c &CanvasPlus) unfocus() {
	c.unfocus_all()
}

fn (c &CanvasPlus) point_inside(x f64, y f64) bool {
	return point_inside<CanvasPlus>(c, x, y)
}

fn (c &CanvasPlus) get_ui() &UI {
	return c.ui
}

fn (c &CanvasPlus) unfocus_all() {
	for mut child in c.children {
		child.unfocus()
	}
}

fn (c &CanvasPlus) resize(width int, height int) {
}

fn (c &CanvasPlus) get_state() voidptr {
	parent := c.parent
	return parent.get_state()
}

fn (c &CanvasPlus) get_subscriber() &eventbus.Subscriber {
	parent := c.parent
	return parent.get_subscriber()
}

fn (c &CanvasPlus) get_children() []Widget {
	return c.children
}

// Methods for delegating drawing methods relatively to canvas coordinates

pub fn (c &CanvasPlus) draw_text_def(x int, y int, text string) {
	c.ui.gg.draw_text_def(x + c.x + c.offset_x, y + c.y + c.offset_y, text)
}

pub fn (c &CanvasPlus) draw_rect(x f32, y f32, w f32, h f32, color gx.Color) {
	c.ui.gg.draw_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, color)
}

pub fn (c &CanvasPlus) draw_triangle(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	c.ui.gg.draw_triangle(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, x3 + c.x + c.offset_x, y3 + c.y + c.offset_y, color)
}

pub fn (c &CanvasPlus) draw_empty_rect(x f32, y f32, w f32, h f32, color gx.Color) {
	c.ui.gg.draw_empty_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, color)
}

pub fn (c &CanvasPlus) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	c.ui.gg.draw_circle_line(x + c.x + c.offset_x, y + c.y + c.offset_y, r, segments,
		color)
}

pub fn (c &CanvasPlus) draw_circle(x f32, y f32, r f32, color gx.Color) {
	c.ui.gg.draw_circle(x + c.x + c.offset_x, y + c.y + c.offset_y, r, color)
}

pub fn (c &CanvasPlus) draw_arc_line(x f32, y f32, r int, start_angle f32, arc_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_arc_line(x + c.x + c.offset_x, y + c.y + c.offset_y, r, start_angle,
		arc_angle, segments, color)
}

pub fn (c &CanvasPlus) draw_arc(x f32, y f32, r int, start_angle f32, arc_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_arc(x + c.x + c.offset_x, y + c.y + c.offset_y, r, start_angle, arc_angle,
		segments, color)
}

pub fn (c &CanvasPlus) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	c.ui.gg.draw_line(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, color)
}

pub fn (c &CanvasPlus) draw_rounded_rect(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	c.ui.gg.draw_rounded_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, radius,
		color)
}

pub fn (c &CanvasPlus) draw_empty_rounded_rect(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	c.ui.gg.draw_empty_rounded_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h,
		radius, border_color)
}

pub fn (c &CanvasPlus) draw_convex_poly(points []f32, color gx.Color) {
}

pub fn (c &CanvasPlus) draw_empty_poly(points []f32, color gx.Color) {
}
