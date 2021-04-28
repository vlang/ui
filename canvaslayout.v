// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg
import gx
import eventbus

pub type CanvasLayoutDrawFn = fn (c &CanvasLayout, state voidptr) // x_offset int, y_offset int)

pub type CanvasLayoutScrollFn = fn (e ScrollEvent, c &CanvasLayout)

pub type CanvasLayoutMouseMoveFn = fn (e MouseMoveEvent, c &CanvasLayout)

pub type CanvasLayoutMouseFn = fn (e MouseEvent, c &CanvasLayout)

pub struct CanvasLayout {
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
	// additional attached state usable for composable widget
	component      voidptr
	component_type string // to save the type of the component
mut:
	parent        Layout
	draw_fn       CanvasLayoutDrawFn      = voidptr(0)
	mouse_down_fn CanvasLayoutMouseFn     = voidptr(0)
	mouse_up_fn   CanvasLayoutMouseFn     = voidptr(0)
	scroll_fn     CanvasLayoutScrollFn    = voidptr(0)
	mouse_move_fn CanvasLayoutMouseMoveFn = voidptr(0)
}

pub struct CanvasLayoutConfig {
	width         int
	height        int
	z_index       int
	text          string
	draw_fn       CanvasLayoutDrawFn      = voidptr(0)
	mouse_down_fn CanvasLayoutMouseFn     = voidptr(0)
	mouse_up_fn   CanvasLayoutMouseFn     = voidptr(0)
	scroll_fn     CanvasLayoutScrollFn    = voidptr(0)
	mouse_move_fn CanvasLayoutMouseMoveFn = voidptr(0)
	// resize_fn     ResizeFn
	// key_down_fn   KeyFn
	// char_fn       KeyFn
}

fn (mut c CanvasLayout) init(parent Layout) {
	c.parent = parent
	ui := parent.get_ui()
	c.ui = ui
	for mut child in c.children {
		child.init(c)
	}
	c.set_adjusted_size(ui)
	c.set_children_pos()
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_mouse_down, canvas_layout_mouse_down, c)
	subscriber.subscribe_method(events.on_mouse_up, canvas_layout_mouse_up, c)
	subscriber.subscribe_method(events.on_mouse_move, canvas_layout_mouse_move, c)
	subscriber.subscribe_method(events.on_scroll, canvas_layout_scroll, c)
}

pub fn canvas_layout(c CanvasLayoutConfig, children []Widget) &CanvasLayout {
	mut canvas := &CanvasLayout{
		width: c.width
		height: c.height
		z_index: c.z_index
		draw_fn: c.draw_fn
		mouse_move_fn: c.mouse_move_fn
		mouse_down_fn: c.mouse_down_fn
		mouse_up_fn: c.mouse_up_fn
		children: children
	}
	return canvas
}

fn canvas_layout_mouse_down(mut c CanvasLayout, e &MouseEvent, window &Window) {
	if c.point_inside(e.x, e.y) && c.mouse_down_fn != voidptr(0) {
		e2 := MouseEvent{
			x: e.x - c.x - c.offset_x
			y: e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods: e.mods
		}
		c.mouse_down_fn(e2, c)
	}
}

fn canvas_layout_mouse_up(mut c CanvasLayout, e &MouseEvent, window &Window) {
	if c.point_inside(e.x, e.y) && c.mouse_up_fn != voidptr(0) {
		e2 := MouseEvent{
			x: e.x - c.x - c.offset_x
			y: e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods: e.mods
		}
		c.mouse_up_fn(e2, c)
	}
}

fn canvas_layout_mouse_move(mut c CanvasLayout, e &MouseMoveEvent, window &Window) {
	if c.point_inside(e.x, e.y) && c.mouse_move_fn != voidptr(0) {
		e2 := MouseMoveEvent{
			x: e.x - c.x - c.offset_x
			y: e.y - c.y - c.offset_y
			mouse_button: e.mouse_button
		}
		c.mouse_move_fn(e2, c)
	}
}

fn canvas_layout_scroll(mut c CanvasLayout, e &ScrollEvent, window &Window) {
	if c.scroll_fn != voidptr(0) {
		e2 := ScrollEvent{
			x: e.x - c.x - c.offset_x
			y: e.y - c.y - c.offset_y
		}
		c.scroll_fn(e2, c)
	}
}

fn (mut c CanvasLayout) set_adjusted_size(ui &UI) {
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

fn (c &CanvasLayout) set_children_pos() {
	for mut child in c.children {
		child.set_pos(child.x + c.x + c.offset_x, child.y + c.y + c.offset_y)
	}
}

fn (mut c CanvasLayout) set_pos(x int, y int) {
	c.x = x
	c.y = y
}

fn (mut c CanvasLayout) size() (int, int) {
	return c.width, c.height
}

fn (mut c CanvasLayout) propose_size(w int, h int) (int, int) {
	c.width = w
	c.height = h
	return c.width, c.height
}

fn (mut c CanvasLayout) draw() {
	offset_start(mut c)
	parent := c.parent
	state := parent.get_state()
	if c.draw_fn != voidptr(0) {
		c.draw_fn(c, state)
	}
	for mut child in c.children {
		// x, y := child.x, child.y
		// child.set_pos(child.x + c.x + c.offset_x, child.y + c.y + c.offset_y)
		child.draw()
		// child.set_pos(x, y)
	}
	offset_end(mut c)
}

fn (mut c CanvasLayout) set_visible(state bool) {
	c.hidden = !state
}

fn (c &CanvasLayout) focus() {
}

fn (c &CanvasLayout) is_focused() bool {
	return false
}

fn (c &CanvasLayout) unfocus() {
	c.unfocus_all()
}

fn (c &CanvasLayout) point_inside(x f64, y f64) bool {
	return point_inside<CanvasLayout>(c, x, y)
}

fn (c &CanvasLayout) get_ui() &UI {
	return c.ui
}

fn (c &CanvasLayout) unfocus_all() {
	for mut child in c.children {
		child.unfocus()
	}
}

fn (c &CanvasLayout) resize(width int, height int) {
}

fn (c &CanvasLayout) get_state() voidptr {
	parent := c.parent
	return parent.get_state()
}

fn (c &CanvasLayout) get_subscriber() &eventbus.Subscriber {
	parent := c.parent
	return parent.get_subscriber()
}

pub fn (c &CanvasLayout) get_children() []Widget {
	return c.children
}

// Methods for delegating drawing methods relatively to canvas coordinates

pub fn (c &CanvasLayout) draw_text_def(x int, y int, text string) {
	c.ui.gg.draw_text_def(x + c.x + c.offset_x, y + c.y + c.offset_y, text)
}

pub fn (c &CanvasLayout) draw_rect(x f32, y f32, w f32, h f32, color gx.Color) {
	c.ui.gg.draw_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, color)
}

pub fn (c &CanvasLayout) draw_triangle(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	c.ui.gg.draw_triangle(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, x3 + c.x + c.offset_x, y3 + c.y + c.offset_y, color)
}

pub fn (c &CanvasLayout) draw_empty_rect(x f32, y f32, w f32, h f32, color gx.Color) {
	c.ui.gg.draw_empty_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, color)
}

pub fn (c &CanvasLayout) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	c.ui.gg.draw_circle_line(x + c.x + c.offset_x, y + c.y + c.offset_y, r, segments,
		color)
}

pub fn (c &CanvasLayout) draw_circle(x f32, y f32, r f32, color gx.Color) {
	c.ui.gg.draw_circle(x + c.x + c.offset_x, y + c.y + c.offset_y, r, color)
}

pub fn (c &CanvasLayout) draw_arc_line(x f32, y f32, r int, start_angle f32, arc_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_arc_line(x + c.x + c.offset_x, y + c.y + c.offset_y, r, start_angle,
		arc_angle, segments, color)
}

pub fn (c &CanvasLayout) draw_arc(x f32, y f32, r int, start_angle f32, arc_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_arc(x + c.x + c.offset_x, y + c.y + c.offset_y, r, start_angle, arc_angle,
		segments, color)
}

pub fn (c &CanvasLayout) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	c.ui.gg.draw_line(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, color)
}

pub fn (c &CanvasLayout) draw_rounded_rect(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	c.ui.gg.draw_rounded_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, radius,
		color)
}

pub fn (c &CanvasLayout) draw_empty_rounded_rect(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	c.ui.gg.draw_empty_rounded_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h,
		radius, border_color)
}

pub fn (c &CanvasLayout) draw_convex_poly(points []f32, color gx.Color) {
}

pub fn (c &CanvasLayout) draw_empty_poly(points []f32, color gx.Color) {
}
