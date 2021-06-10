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

pub type CanvasLayoutKeyFn = fn (e KeyEvent, c &CanvasLayout)

[heap]
pub struct CanvasLayout {
pub mut:
	id               string
	children         []Widget
	drawing_children []Widget
	width            int
	height           int
	x                int
	y                int
	offset_x         int
	offset_y         int
	z_index          int
	is_focused       bool
	ui               &UI = 0
	hidden           bool
	bg_color         gx.Color
	bg_radius        f32
	adj_width        int
	adj_height       int
	// component state for composable widget
	component      voidptr
	component_type string // to save the type of the component
	component_init ComponentInitFn
	// scrollview
	has_scrollview bool
	scrollview     &ScrollView = 0
	// callbacks
	draw_fn       CanvasLayoutDrawFn      = voidptr(0)
	click_fn      CanvasLayoutMouseFn     = voidptr(0)
	mouse_down_fn CanvasLayoutMouseFn     = voidptr(0)
	mouse_up_fn   CanvasLayoutMouseFn     = voidptr(0)
	scroll_fn     CanvasLayoutScrollFn    = voidptr(0)
	mouse_move_fn CanvasLayoutMouseMoveFn = voidptr(0)
	key_down_fn   CanvasLayoutKeyFn       = voidptr(0)
	char_fn       CanvasLayoutKeyFn       = voidptr(0)
mut:
	parent Layout
	// To keep track of original position
	pos_ map[int]XYPos
}

pub struct CanvasLayoutConfig {
	id            string
	width         int
	height        int
	z_index       int
	text          string
	bg_color      gx.Color = no_color
	bg_radius     f64
	scrollview    bool
	on_draw       CanvasLayoutDrawFn      = voidptr(0)
	on_click      CanvasLayoutMouseFn     = voidptr(0)
	on_mouse_down CanvasLayoutMouseFn     = voidptr(0)
	on_mouse_up   CanvasLayoutMouseFn     = voidptr(0)
	on_scroll     CanvasLayoutScrollFn    = voidptr(0)
	on_mouse_move CanvasLayoutMouseMoveFn = voidptr(0)
	// resize_fn     ResizeFn
	on_key_down CanvasLayoutKeyFn = voidptr(0)
	on_char     CanvasLayoutKeyFn = voidptr(0)
}

pub fn canvas_layout(c CanvasLayoutConfig, children []Widget) &CanvasLayout {
	mut canvas := canvas_plus(c)
	canvas.children = children
	// Saves the original position of children
	// used in set_children_pos
	for i, child in children {
		canvas.pos_[i] = XYPos{child.x, child.y}
	}
	return canvas
}

// canvas_plus returns a canvas_layout but without layout
// it can be viewed as a extended canvas
pub fn canvas_plus(c CanvasLayoutConfig) &CanvasLayout {
	mut canvas := &CanvasLayout{
		id: c.id
		width: c.width
		height: c.height
		z_index: c.z_index
		bg_radius: f32(c.bg_radius)
		bg_color: c.bg_color
		draw_fn: c.on_draw
		click_fn: c.on_click
		mouse_move_fn: c.on_mouse_move
		mouse_down_fn: c.on_mouse_down
		mouse_up_fn: c.on_mouse_up
		key_down_fn: c.on_key_down
		char_fn: c.on_char
	}
	if c.scrollview {
		scrollview_add(mut canvas)
	}
	return canvas
}

fn (mut c CanvasLayout) init(parent Layout) {
	c.parent = parent
	ui := parent.get_ui()
	c.ui = ui
	for mut child in c.children {
		child.init(c)
	}
	// init for component
	if c.component_init != ComponentInitFn(0) {
		c.component_init(c)
	}

	c.set_adjusted_size(ui)
	c.set_children_pos()

	if has_scrollview(c) {
		c.scrollview.init(parent)
	} else {
		scrollview_delegate_parent_scrollview(mut c)
	}

	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, canvas_layout_click, c)
	subscriber.subscribe_method(events.on_mouse_down, canvas_layout_mouse_down, c)
	subscriber.subscribe_method(events.on_mouse_up, canvas_layout_mouse_up, c)
	subscriber.subscribe_method(events.on_mouse_move, canvas_layout_mouse_move, c)
	subscriber.subscribe_method(events.on_scroll, canvas_layout_scroll, c)
	subscriber.subscribe_method(events.on_key_down, canvas_layout_key_down, c)
	subscriber.subscribe_method(events.on_char, canvas_layout_char, c)
}

[manualfree]
pub fn (mut c CanvasLayout) cleanup() {
	mut subscriber := c.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, c)
	subscriber.unsubscribe_method(events.on_mouse_down, c)
	subscriber.unsubscribe_method(events.on_mouse_up, c)
	subscriber.unsubscribe_method(events.on_mouse_move, c)
	subscriber.unsubscribe_method(events.on_scroll, c)
	subscriber.unsubscribe_method(events.on_key_down, c)
	subscriber.unsubscribe_method(events.on_char, c)
	for mut child in c.children {
		child.cleanup()
	}
	unsafe { c.free() }
}

[unsafe]
pub fn (c &CanvasLayout) free() {
	$if free ? {
		print('canvas_layout $c.id')
	}
	unsafe {
		c.id.free()
		c.drawing_children.free()
		c.children.free()
		if c.has_scrollview {
			c.scrollview.free()
		}
		free(c)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn canvas_layout_click(mut c CanvasLayout, e &MouseEvent, window &Window) {
	c.is_focused = c.point_inside(e.x, e.y)
	if c.is_focused && c.click_fn != voidptr(0) {
		c.is_focused
		e2 := MouseEvent{
			x: e.x - c.x - c.offset_x
			y: e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods: e.mods
		}
		c.click_fn(e2, c)
	}
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

fn canvas_layout_key_down(mut c CanvasLayout, e &KeyEvent, window &Window) {
	// println('key down $c.id $c.hidden $e')
	if c.hidden {
		return
	}
	if !c.is_focused {
		return
	}
	if c.key_down_fn != voidptr(0) {
		c.key_down_fn(*e, c)
	}
}

fn canvas_layout_char(mut c CanvasLayout, e &KeyEvent, window &Window) {
	// println('key down $e')
	if c.hidden {
		return
	}
	if !c.is_focused {
		return
	}
	if c.char_fn != voidptr(0) {
		c.char_fn(*e, c)
	}
}

pub fn (mut c CanvasLayout) update_layout() {
	c.set_drawing_children()
}

fn (mut c CanvasLayout) set_adjusted_size(ui &UI) {
	mut w, mut h := 0, 0
	for mut child in c.children {
		child_width, child_height := child.size()

		if child.x + child_width > w {
			w = child.x + child_width
		}
		if child.y + child_height > h {
			h = child.y + child_height
		}
		// println("${child.type_name()} -> ($child.x + $child_width, $child.y + $child_height) -> ($w, $h)")
	}
	// println("$c.id -> ($w, $h)")
	if c.width > w {
		w = c.width
	}
	if c.height > h {
		h = c.height
	}

	c.adj_width = w
	c.adj_height = h
}

fn (c &CanvasLayout) set_children_pos() {
	for i, mut child in c.children {
		child.set_pos(c.pos_[i].x + c.x + c.offset_x, c.pos_[i].y + c.y + c.offset_y)
		if mut child is Stack {
			child.update_layout()
		}
	}
}

fn (mut c CanvasLayout) set_pos(x int, y int) {
	c.x = x
	c.y = y
	// scrollview_update_orig_size(c)
	c.set_children_pos()
}

fn (mut c CanvasLayout) adj_size() (int, int) {
	return c.adj_width, c.adj_height
}

fn (mut c CanvasLayout) size() (int, int) {
	return c.width, c.height
}

fn (mut c CanvasLayout) propose_size(w int, h int) (int, int) {
	c.width = w
	c.height = h
	scrollview_update(c)
	// println("propose_size size($c.width, $c.height) -> adj_size($c.adj_width, $c.adj_height)")
	return c.width, c.height
}

fn (mut c CanvasLayout) set_drawing_children() {
	for mut child in c.children {
		if mut child is Stack {
			child.set_drawing_children()
		} else if mut child is CanvasLayout {
			child.set_drawing_children()
		}
		// println("z_index: ${child.type_name()} $child.z_index")
		if child.z_index > c.z_index {
			c.z_index = child.z_index
		}
	}
	c.drawing_children = c.children.filter(!it.hidden)
	c.sorted_drawing_children()
}

fn (mut c CanvasLayout) draw() {
	if c.hidden {
		return
	}
	offset_start(mut c)
	parent := c.parent
	state := parent.get_state()

	// if scrollview_clip(mut c) {
	// 	c.set_children_pos()
	// 	c.scrollview.children_to_update = false
	// }
	scrollview_draw_begin(mut c)

	if c.bg_color != no_color {
		if c.bg_radius > 0 {
			radius := relative_size(c.bg_radius, c.width, c.height)
			c.draw_rounded_rect(c.x, c.y, c.width, c.height, radius, c.bg_color)
		} else {
			c.draw_rect(c.x, c.y, c.width, c.height, c.bg_color)
		}
	}

	if c.draw_fn != voidptr(0) {
		c.draw_fn(c, state)
	}
	for mut child in c.drawing_children {
		child.draw()
	}

	// scrollview_draw(c)
	scrollview_draw_end(c)

	offset_end(mut c)
}

pub fn (mut c CanvasLayout) set_visible(state bool) {
	c.hidden = !state
	for mut child in c.children {
		child.set_visible(state)
	}
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
	return point_inside(c, x, y)
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

pub fn (c &CanvasLayout) get_state() voidptr {
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
	rad := relative_size(radius, int(w), int(h))
	c.ui.gg.draw_rounded_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, rad, color)
}

pub fn (c &CanvasLayout) draw_empty_rounded_rect(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	rad := relative_size(radius, int(w), int(h))
	c.ui.gg.draw_empty_rounded_rect(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h,
		rad, border_color)
}

pub fn (c &CanvasLayout) draw_convex_poly(points []f32, color gx.Color) {
}

pub fn (c &CanvasLayout) draw_empty_poly(points []f32, color gx.Color) {
}

pub fn (c &CanvasLayout) child_index_by_id(id string) int {
	for i, child in c.children {
		if widget_id(child) == id {
			return i
		}
	}
	return -1
}
