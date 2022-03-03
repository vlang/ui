// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
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

pub type CanvasLayoutSizeFn = fn (c &CanvasLayout) (int, int)

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
	full_width       int
	full_height      int
	// text styles
	text_styles TextStyles
	// component state for composable widget
	component      voidptr
	component_init ComponentInitFn
	// scrollview
	has_scrollview bool
	scrollview     &ScrollView = 0
	// callbacks
	draw_fn          CanvasLayoutDrawFn      = CanvasLayoutDrawFn(0)
	click_fn         CanvasLayoutMouseFn     = CanvasLayoutMouseFn(0)
	mouse_down_fn    CanvasLayoutMouseFn     = CanvasLayoutMouseFn(0)
	mouse_up_fn      CanvasLayoutMouseFn     = CanvasLayoutMouseFn(0)
	scroll_fn        CanvasLayoutScrollFn    = CanvasLayoutScrollFn(0)
	mouse_move_fn    CanvasLayoutMouseMoveFn = CanvasLayoutMouseMoveFn(0)
	key_down_fn      CanvasLayoutKeyFn       = CanvasLayoutKeyFn(0)
	char_fn          CanvasLayoutKeyFn       = CanvasLayoutKeyFn(0)
	full_size_fn     CanvasLayoutSizeFn      = CanvasLayoutSizeFn(0)
	on_scroll_change ScrollViewChangedFn     = ScrollViewChangedFn(0)
	parent           Layout = empty_stack
mut:
	// To keep track of original position
	pos_ map[int]XYPos
}

[params]
pub struct CanvasLayoutParams {
	id            string
	width         int
	height        int
	full_width    int = -1
	full_height   int = -1
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
	on_key_down  CanvasLayoutKeyFn  = voidptr(0)
	on_char      CanvasLayoutKeyFn  = voidptr(0)
	full_size_fn CanvasLayoutSizeFn = voidptr(0)
	children     []Widget
}

pub fn canvas_layout(c CanvasLayoutParams) &CanvasLayout {
	mut canvas := canvas_plus(c)
	canvas.children = c.children
	// Saves the original position of children
	// used in set_children_pos
	for i, child in c.children {
		canvas.pos_[i] = XYPos{child.x, child.y}
	}
	return canvas
}

// canvas_plus returns a canvas_layout but without layout
// it can be viewed as a extended canvas
pub fn canvas_plus(c CanvasLayoutParams) &CanvasLayout {
	mut canvas := &CanvasLayout{
		id: c.id
		width: c.width
		height: c.height
		full_width: c.full_width
		full_height: c.full_height
		z_index: c.z_index
		bg_radius: f32(c.bg_radius)
		bg_color: c.bg_color
		draw_fn: c.on_draw
		click_fn: c.on_click
		mouse_move_fn: c.on_mouse_move
		mouse_down_fn: c.on_mouse_down
		mouse_up_fn: c.on_mouse_up
		key_down_fn: c.on_key_down
		full_size_fn: c.full_size_fn
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
	// IMPORTANT: Subscriber needs here to be before initialization of all its children
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, canvas_layout_click, c)
	subscriber.subscribe_method(events.on_mouse_down, canvas_layout_mouse_down, c)
	subscriber.subscribe_method(events.on_mouse_up, canvas_layout_mouse_up, c)
	subscriber.subscribe_method(events.on_mouse_move, canvas_layout_mouse_move, c)
	subscriber.subscribe_method(events.on_scroll, canvas_layout_scroll, c)
	subscriber.subscribe_method(events.on_key_down, canvas_layout_key_down, c)
	subscriber.subscribe_method(events.on_char, canvas_layout_char, c)
	$if android {
		subscriber.subscribe_method(events.on_touch_down, canvas_layout_mouse_down, c)
		subscriber.subscribe_method(events.on_touch_up, canvas_layout_mouse_up, c)
		subscriber.subscribe_method(events.on_touch_move, canvas_layout_mouse_move, c)
	}
	c.ui.window.evt_mngr.add_receiver(c, [events.on_mouse_down])

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
		c.ui.window.evt_mngr.add_receiver(c, [events.on_scroll])
	} else {
		scrollview_delegate_parent_scrollview(mut c)
	}
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
	$if android {
		subscriber.unsubscribe_method(events.on_touch_down, c)
		subscriber.unsubscribe_method(events.on_touch_up, c)
		subscriber.unsubscribe_method(events.on_touch_move, c)
	}
	c.ui.window.evt_mngr.rm_receiver(c, [events.on_mouse_down])
	if has_scrollview(c) {
		c.ui.window.evt_mngr.rm_receiver(c, [events.on_scroll])
	}
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
		// if c.has_scrollview {
		// 	c.scrollview.free()
		// }
		free(c)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn canvas_layout_click(mut c CanvasLayout, e &MouseEvent, window &Window) {
	$if cl_click ? {
		if c.point_inside(e.x, e.y) {
			println('clc $c.id $c.z_index ($e.x, $e.y) ${c.point_inside(e.x, e.y)} ${c.ui.window.is_top_widget(c,
				events.on_mouse_down)}')
		}
	}
	if !c.ui.window.is_top_widget(c, events.on_mouse_down) {
		return
	}
	c.is_focused = c.point_inside(e.x, e.y)
	if c.is_focused && c.click_fn != voidptr(0) {
		// c.is_focused
		e2 := MouseEvent{
			x: e.x - c.x - c.offset_x
			y: e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods: e.mods
		}
		println('$c.id $e2.x $e2.y')
		c.click_fn(e2, c)
	}
}

fn canvas_layout_mouse_down(mut c CanvasLayout, e &MouseEvent, window &Window) {
	if !c.ui.window.is_top_widget(c, events.on_mouse_down) {
		return
	}
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

fn (mut c CanvasLayout) set_adjusted_size(gui &UI) {
	// println('set_adj $c.full_width $c.full_height')
	if c.full_width > 0 && c.full_height > 0 {
		c.adj_width, c.adj_height = c.full_width, c.full_height
		return
	} else if c.full_width == -1 || c.full_height == -1 { // dynamical
		fw, fh := c.full_size()
		if fw > 0 && fh > 0 {
			c.adj_width, c.adj_height = fw, fh
			return
		}
	}
	mut w, mut h := 0, 0
	for mut child in c.children {
		if child.z_index > z_index_hidden { // taking into account only visible widgets
			child_width, child_height := child.size()

			if child.x + child_width > w {
				w = child.x + child_width
			}
			if child.y + child_height > h {
				h = child.y + child_height
			}
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
	// println("cl set_adj $c.id -> ($w, $h)")
	c.adj_width = w
	c.adj_height = h
}

fn (mut c CanvasLayout) set_children_pos() {
	for i, mut child in c.children {
		child.set_pos(c.pos_[i].x + c.x + c.offset_x, c.pos_[i].y + c.y + c.offset_y)
		if mut child is Stack {
			child.update_layout()
		}
	}
}

pub fn (mut c CanvasLayout) set_pos(x int, y int) {
	c.x = x
	c.y = y
	// scrollview_update_orig_size(c)
	c.set_children_pos()
}

fn (c CanvasLayout) adj_size() (int, int) {
	return c.adj_width, c.adj_height
}

pub fn (c CanvasLayout) size() (int, int) {
	return c.width, c.height
}

// possibly dynamic full size
pub fn (c &CanvasLayout) full_size() (int, int) {
	mut fw, mut fh := c.full_width, c.full_height
	// println('full_size $fw, $fh')
	if c.full_width == -1 || c.full_height == -1 {
		if c.full_size_fn == voidptr(0) {
			return 0, 0
		} else {
			w, h := c.full_size_fn(c)
			if c.full_width == -1 {
				fw = w
			}
			if c.full_height == -1 {
				fh = h
			}
		}
	}
	// println('$fw, $fh')
	return fw, fh
}

pub fn (mut c CanvasLayout) propose_size(w int, h int) (int, int) {
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
		mut w, mut h := c.width, c.height
		fw, fh := c.full_size()
		if fw > 0 && fh > 0 {
			w, h = int(f32(fw) * c.ui.gg.scale), int(f32(fh) * c.ui.gg.scale)
		}
		if c.bg_radius > 0 {
			radius := relative_size(c.bg_radius, w, h)
			c.draw_rounded_rect_filled(0, 0, w, h, radius, c.bg_color)
		} else {
			c.draw_rect_filled(0, 0, w, h, c.bg_color)
		}
	}

	if c.draw_fn != voidptr(0) {
		c.draw_fn(c, state)
	}
	$if cdraw_scroll ? {
		if Layout(c).has_scrollview_or_parent_scrollview() {
			// if c.scrollview != 0 {
			for i, mut child in c.drawing_children {
				if child !is Layout
					&& is_empty_intersection(c.scrollview.scissor_rect, child.scaled_bounds()) {
					sr := c.scrollview.scissor_rect
					cr := child.bounds()
					println('cdraw $c.id ($sr.x, $sr.y, $sr.width, $sr.height)  $i) $child.type_name() $child.id ($cr.x, $cr.y, $cr.width, $cr.height) clipped')
				}
			}
		}
	}
	// if Layout(c).has_scrollview_or_parent_scrollview() {
	if c.scrollview != 0 {
		for mut child in c.drawing_children {
			if mut child is Layout
				|| !is_empty_intersection(c.scrollview.scissor_rect, child.scaled_bounds()) {
				child.draw()
			}
		}
	} else {
		$if cl_draw_children ? {
			println('draw $c.id: ${c.drawing_children.map(it.id)}')
		}
		for mut child in c.drawing_children {
			child.draw()
		}
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

fn (c &CanvasLayout) point_inside(x f64, y f64) bool {
	// println("point_inside $c.id ($x, $y) in ($c.x + $c.offset_x + $c.width, $c.y + $c.offset_y + $c.height)")
	return point_inside(c, x, y)
}

fn (c &CanvasLayout) get_ui() &UI {
	return c.ui
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

pub fn (c &CanvasLayout) child_index_by_id(id string) int {
	for i, child in c.children {
		if child.id() == id {
			return i
		}
	}
	return -1
}

// Methods for delegating drawing methods relatively to canvas coordinates

// ---- text

pub fn (c &CanvasLayout) draw_text_def(x int, y int, text string) {
	c.ui.gg.draw_text_def(x + c.x + c.offset_x, y + c.y + c.offset_y, text)
}

pub fn (c &CanvasLayout) draw_text(x int, y int, text string) {
	mut dtw := DrawTextWidget(c)
	// println("dt $x + $c.x + $c.offset_x, $y + $c.y + $c.offset_y, $text")
	dtw.draw_text(x + c.x + c.offset_x, y + c.y + c.offset_y, text)
}

pub fn (c &CanvasLayout) draw_styled_text(x int, y int, text string, ts TextStyleParams) {
	mut dtw := DrawTextWidget(c)
	dtw.draw_styled_text(x + c.x + c.offset_x, y + c.y + c.offset_y, text, ts)
}

// ---- triangle

pub fn (c &CanvasLayout) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	c.ui.gg.draw_triangle_empty(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, x3 + c.x + c.offset_x, y3 + c.y + c.offset_y, color)
}

pub fn (c &CanvasLayout) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	c.ui.gg.draw_triangle_filled(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, x3 + c.x + c.offset_x, y3 + c.y + c.offset_y, color)
}

// ---- square

pub fn (c &CanvasLayout) draw_square_empty(x f32, y f32, s f32, color gx.Color) {
	c.draw_rect_empty(x, y, s, s, color)
}

pub fn (c &CanvasLayout) draw_square_filled(x f32, y f32, s f32, color gx.Color) {
	c.draw_rect_filled(x, y, s, s, color)
}

// ---- rectangle

pub fn (c &CanvasLayout) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	c.ui.gg.draw_rect_empty(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, color)
}

pub fn (c &CanvasLayout) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	c.ui.gg.draw_rect_filled(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h, color)
}

pub fn (c &CanvasLayout) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	rad := relative_size(radius, int(w), int(h))
	c.ui.gg.draw_rounded_rect_filled(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h,
		rad, color)
}

pub fn (c &CanvasLayout) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	rad := relative_size(radius, int(w), int(h))
	c.ui.gg.draw_rounded_rect_empty(x + c.x + c.offset_x, y + c.y + c.offset_y, w, h,
		rad, border_color)
}

// ---- circle

pub fn (c &CanvasLayout) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	c.ui.gg.draw_circle_line(x + c.x + c.offset_x, y + c.y + c.offset_y, r, segments,
		color)
}

pub fn (c &CanvasLayout) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	c.ui.gg.draw_circle_empty(x + c.x + c.offset_x, y + c.y + c.offset_y, r, color)
}

pub fn (c &CanvasLayout) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	c.ui.gg.draw_circle_filled(x + c.x + c.offset_x, y + c.y + c.offset_y, r, color)
}

// ---- slice

pub fn (c &CanvasLayout) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_slice_empty(x + c.x + c.offset_x, y + c.y + c.offset_y, r, start_angle,
		end_angle, segments, color)
}

pub fn (c &CanvasLayout) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_slice_filled(x + c.x + c.offset_x, y + c.y + c.offset_y, r, start_angle,
		end_angle, segments, color)
}

// ---- arc

pub fn (c &CanvasLayout) draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_arc_empty(x + c.x + c.offset_x, y + c.y + c.offset_y, inner_radius, thickness,
		start_angle, end_angle, segments, color)
}

pub fn (c &CanvasLayout) draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	c.ui.gg.draw_arc_filled(x + c.x + c.offset_x, y + c.y + c.offset_y, inner_radius,
		thickness, start_angle, end_angle, segments, color)
}

// ---- line

pub fn (c &CanvasLayout) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	// println("dl $x + $c.x + $c.offset_x, $y + $c.y + $c.offset_y, $x2 + $c.x + $c.offset_x,
	// $y2 + $c.y + $c.offset_y")
	c.ui.gg.draw_line(x + c.x + c.offset_x, y + c.y + c.offset_y, x2 + c.x + c.offset_x,
		y2 + c.y + c.offset_y, color)
}

// ---- polygon
// TODO: What to do about canvas offset?
pub fn (c &CanvasLayout) draw_convex_poly(points []f32, color gx.Color) {
}

pub fn (c &CanvasLayout) draw_empty_poly(points []f32, color gx.Color) {
}
