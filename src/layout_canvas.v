// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import gg
import gx
import eventbus

pub type CanvasLayoutDrawDeviceFn = fn (mut d DrawDevice, c &CanvasLayout)

pub type CanvasLayoutScrollFn = fn (c &CanvasLayout, e ScrollEvent)

pub type CanvasLayoutMouseMoveFn = fn (c &CanvasLayout, e MouseMoveEvent)

pub type CanvasLayoutMouseFn = fn (c &CanvasLayout, e MouseEvent)

pub type CanvasLayoutKeyFn = fn (c &CanvasLayout, e KeyEvent)

pub type CanvasLayoutSizeFn = fn (c &CanvasLayout) (int, int)

pub type CanvasLayoutBoundingFn = fn (c &CanvasLayout, bb gg.Rect)

pub type CanvasLayoutDelegateFn = fn (c &CanvasLayout, e &gg.Event)

@[heap]
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
	deactivated      bool
	is_focused       bool
	ui               &UI = unsafe { nil }
	hidden           bool
	is_root_layout   bool = true
	clipping         bool
	adj_width        int
	adj_height       int
	full_width       int
	full_height      int
	// Adjustable
	justify         []f64
	ax              int
	ay              int
	is_canvas_layer bool
	// Style
	theme_style  string
	style        CanvasLayoutShapeStyle
	style_params CanvasLayoutStyleParams
	// text styles
	text_styles TextStyles
	// component state for composable widget
	component         voidptr
	active_evt_mngr   bool
	delegate_evt_mngr bool
	on_build          BuildFn = unsafe { nil }
	on_init           InitFn  = unsafe { nil }
	// scrollview
	has_scrollview bool
	scrollview     &ScrollView = unsafe { nil }
	// callbacks
	draw_device_fn      CanvasLayoutDrawDeviceFn = unsafe { CanvasLayoutDrawDeviceFn(0) }
	post_draw_device_fn CanvasLayoutDrawDeviceFn = unsafe { CanvasLayoutDrawDeviceFn(0) }
	click_fn            CanvasLayoutMouseFn      = unsafe { CanvasLayoutMouseFn(0) }
	mouse_down_fn       CanvasLayoutMouseFn      = unsafe { CanvasLayoutMouseFn(0) }
	mouse_up_fn         CanvasLayoutMouseFn      = unsafe { CanvasLayoutMouseFn(0) }
	scroll_fn           CanvasLayoutScrollFn     = unsafe { CanvasLayoutScrollFn(0) }
	mouse_move_fn       CanvasLayoutMouseMoveFn  = unsafe { CanvasLayoutMouseMoveFn(0) }
	mouse_enter_fn      CanvasLayoutMouseMoveFn  = unsafe { CanvasLayoutMouseMoveFn(0) }
	mouse_leave_fn      CanvasLayoutMouseMoveFn  = unsafe { CanvasLayoutMouseMoveFn(0) }
	key_down_fn         CanvasLayoutKeyFn        = unsafe { CanvasLayoutKeyFn(0) }
	char_fn             CanvasLayoutKeyFn        = unsafe { CanvasLayoutKeyFn(0) }
	full_size_fn        CanvasLayoutSizeFn       = unsafe { CanvasLayoutSizeFn(0) }
	bounding_change_fn  CanvasLayoutBoundingFn   = unsafe { CanvasLayoutBoundingFn(0) }
	on_scroll_change    ScrollViewChangedFn      = unsafe { ScrollViewChangedFn(0) }
	on_delegate         CanvasLayoutDelegateFn   = unsafe { nil }
	parent              Layout                   = empty_stack
mut:
	// To keep track of original position
	pos_ map[int]XYPos
	// debug stuff to be removed
	debug_ids          []string
	debug_children_ids []string
}

@[params]
pub struct CanvasLayoutParams {
	CanvasLayoutStyleParams
pub:
	id                string
	width             int
	height            int
	full_width        int = -1
	full_height       int = -1
	z_index           int
	clipping          bool
	text              string
	scrollview        bool
	is_focused        bool
	justify           []f64  = [0.0, 0.0]
	theme             string = no_style
	active_evt_mngr   bool   = true
	delegate_evt_mngr bool
	on_draw           CanvasLayoutDrawDeviceFn = unsafe { nil }
	on_post_draw      CanvasLayoutDrawDeviceFn = unsafe { nil }
	on_click          CanvasLayoutMouseFn      = unsafe { nil }
	on_mouse_down     CanvasLayoutMouseFn      = unsafe { nil }
	on_mouse_up       CanvasLayoutMouseFn      = unsafe { nil }
	on_scroll         CanvasLayoutScrollFn     = unsafe { nil }
	on_mouse_move     CanvasLayoutMouseMoveFn  = unsafe { nil }
	on_mouse_enter    CanvasLayoutMouseMoveFn  = unsafe { nil }
	on_mouse_leave    CanvasLayoutMouseMoveFn  = unsafe { nil }
	// resize_fn     ResizeFn
	on_key_down        CanvasLayoutKeyFn      = unsafe { nil }
	on_char            CanvasLayoutKeyFn      = unsafe { nil }
	full_size_fn       CanvasLayoutSizeFn     = unsafe { nil }
	on_bounding_change CanvasLayoutBoundingFn = unsafe { nil }
	on_scroll_change   ScrollViewChangedFn    = unsafe { ScrollViewChangedFn(0) }
	on_delegate        CanvasLayoutDelegateFn = unsafe { nil }
	children           []Widget
}

// TODO: documentation
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
		id:          c.id
		width:       c.width
		height:      c.height
		full_width:  c.full_width
		full_height: c.full_height
		z_index:     c.z_index
		// bg_radius: f32(c.bg_radius)
		// bg_color: c.bg_color
		is_focused:          c.is_focused
		clipping:            c.clipping
		justify:             c.justify
		style_params:        c.CanvasLayoutStyleParams
		active_evt_mngr:     c.active_evt_mngr && !c.delegate_evt_mngr
		delegate_evt_mngr:   c.delegate_evt_mngr
		draw_device_fn:      c.on_draw
		post_draw_device_fn: c.on_post_draw
		click_fn:            c.on_click
		mouse_move_fn:       c.on_mouse_move
		mouse_enter_fn:      c.on_mouse_enter
		mouse_leave_fn:      c.on_mouse_leave
		mouse_down_fn:       c.on_mouse_down
		mouse_up_fn:         c.on_mouse_up
		key_down_fn:         c.on_key_down
		scroll_fn:           c.on_scroll
		full_size_fn:        c.full_size_fn
		bounding_change_fn:  c.on_bounding_change
		char_fn:             c.on_char
		on_scroll_change:    c.on_scroll_change
		on_delegate:         c.on_delegate
	}
	canvas.style_params.style = c.theme
	if c.scrollview {
		scrollview_add(mut canvas)
	}
	return canvas
}

fn (mut c CanvasLayout) build(win &Window) {
	// init for component
	if c.on_build != unsafe { BuildFn(0) } {
		c.on_build(c, win)
	}
}

fn (mut c CanvasLayout) init(parent Layout) {
	c.parent = parent
	u := parent.get_ui()
	c.ui = u
	c.init_size()
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
	if c.active_evt_mngr {
		c.ui.window.evt_mngr.add_receiver(c, [events.on_mouse_down, events.on_mouse_move])
	}
	if c.delegate_evt_mngr {
		c.ui.window.evt_mngr.add_receiver(c, [events.on_delegate])
		subscriber.subscribe_method(events.on_delegate, canvas_layout_delegate, c)
	}
	for mut child in c.children {
		child.init(c)
	}
	// init for component
	if c.on_init != unsafe { InitFn(0) } {
		c.on_init(c)
	}
	c.load_style()

	c.set_adjusted_size(u)
	c.set_children_pos()
	c.set_root_layout()

	if has_scrollview(c) {
		c.scrollview.init(parent)
		c.ui.window.evt_mngr.add_receiver(c, [events.on_scroll])
	} else {
		scrollview_delegate_parent_scrollview(mut c)
	}
}

// Determine wheither CanvasLayout b is a root layout
fn (mut c CanvasLayout) set_root_layout() {
	if mut c.parent is Window {
		// TODO: before removing line below test if this is necessary
		// c.ui.window = unsafe {c.parent }
		mut window := unsafe { c.parent }
		if c.is_root_layout {
			window.root_layout = c
			// window.update_layout()
		} else {
			c.update_layout()
		}
	} else {
		c.is_root_layout = false
	}
}

// TODO: documentation
@[manualfree]
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
	if c.active_evt_mngr {
		c.ui.window.evt_mngr.rm_receiver(c, [events.on_mouse_down, events.on_mouse_move])
	}
	if c.delegate_evt_mngr {
		c.ui.window.evt_mngr.rm_receiver(c, [events.on_delegate])
		subscriber.unsubscribe_method(events.on_delegate, c)
	}
	if has_scrollview(c) {
		c.ui.window.evt_mngr.rm_receiver(c, [events.on_scroll])
	}
	for mut child in c.children {
		child.cleanup()
	}
	unsafe { c.free() }
}

// TODO: documentation
@[unsafe]
pub fn (c &CanvasLayout) free() {
	$if free ? {
		print('canvas_layout ${c.id}')
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

fn (mut c CanvasLayout) init_size() {
	parent := c.parent
	if c.parent is SubWindow {
		// println("$s.id init_size: $s.width, $s.height ${s.adj_size()}")
		c.width, c.height = c.adj_size()
	} else if c.parent is Window {
		c.width, c.height = parent.size()
	}
	scrollview_update(c)
}

fn canvas_layout_delegate(mut c CanvasLayout, e &gg.Event, window &Window) {
	if !c.point_inside(e.mouse_x / c.ui.window.dpi_scale, e.mouse_y / c.ui.window.dpi_scale) {
		return
	}
	if c.on_delegate != unsafe { CanvasLayoutDelegateFn(0) } {
		c.on_delegate(c, e)
	}
}

fn canvas_layout_click(mut c CanvasLayout, e &MouseEvent, window &Window) {
	$if cl_click ? {
		if c.point_inside(e.x, e.y) {
			println('clc ${c.id} ${c.z_index} (${e.x}, ${e.y}) ${c.point_inside(e.x, e.y)} ${c.ui.window.is_top_widget(c,
				events.on_mouse_down)}')
		} else {
			println('clc ${c.id} ${c.z_index} (${e.x}, ${e.y}) ${c.ui.window.is_top_widget(c,
				events.on_mouse_down)}')
			println('point_inside ${c.id} (${e.x}, ${e.y}) in (${c.x} + ${c.offset_x} + ${c.width}, ${c.y} + ${c.offset_y} + ${c.height})')
		}
	}
	if !c.ui.window.is_top_widget(c, events.on_mouse_down) {
		return
	}
	c.is_focused = c.point_inside(e.x, e.y)
	if c.is_focused && c.click_fn != unsafe { nil } {
		// c.is_focused
		e2 := MouseEvent{
			x:      e.x - c.x - c.offset_x
			y:      e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods:   e.mods
		}
		// println('$c.id $e2.x $e2.y')
		c.click_fn(c, e2)
	}
}

fn canvas_layout_mouse_down(mut c CanvasLayout, e &MouseEvent, window &Window) {
	if c.hidden {
		return
	}
	if !c.ui.window.is_top_widget(c, events.on_mouse_down) {
		return
	}
	if c.point_inside(e.x, e.y) && c.mouse_down_fn != unsafe { nil } {
		e2 := MouseEvent{
			x:      e.x - c.x - c.offset_x
			y:      e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods:   e.mods
		}
		c.mouse_down_fn(c, e2)
	}
}

fn canvas_layout_mouse_up(mut c CanvasLayout, e &MouseEvent, window &Window) {
	if c.hidden {
		return
	}
	if c.point_inside(e.x, e.y) && c.mouse_up_fn != unsafe { nil } {
		e2 := MouseEvent{
			x:      e.x - c.x - c.offset_x
			y:      e.y - c.y - c.offset_y
			button: e.button
			action: e.action
			mods:   e.mods
		}
		c.mouse_up_fn(c, e2)
	}
}

fn canvas_layout_mouse_move(mut c CanvasLayout, e &MouseMoveEvent, window &Window) {
	if c.hidden {
		return
	}
	if c.point_inside(e.x, e.y) && c.mouse_move_fn != unsafe { nil } {
		e2 := MouseMoveEvent{
			x:            e.x - c.x - c.offset_x
			y:            e.y - c.y - c.offset_y
			mouse_button: e.mouse_button
		}
		c.mouse_move_fn(c, e2)
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) mouse_enter(e &MouseMoveEvent) {
	// println("enter $c.id")
	if c.mouse_enter_fn != unsafe { CanvasLayoutMouseMoveFn(0) } {
		e2 := MouseMoveEvent{
			x:            e.x - c.x - c.offset_x
			y:            e.y - c.y - c.offset_y
			mouse_button: e.mouse_button
		}
		c.mouse_enter_fn(c, e2)
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) mouse_leave(e &MouseMoveEvent) {
	// println("leave $c.id")
	if c.mouse_leave_fn != unsafe { CanvasLayoutMouseMoveFn(0) } {
		e2 := MouseMoveEvent{
			x:            e.x - c.x - c.offset_x
			y:            e.y - c.y - c.offset_y
			mouse_button: e.mouse_button
		}
		c.mouse_leave_fn(c, e2)
	}
}

fn canvas_layout_scroll(mut c CanvasLayout, e &ScrollEvent, window &Window) {
	if c.scroll_fn != unsafe { CanvasLayoutScrollFn(0) } {
		e2 := ScrollEvent{
			mouse_x: e.mouse_x - c.x - c.offset_x
			mouse_y: e.mouse_y - c.y - c.offset_y
			x:       e.x
			y:       e.y
		}
		c.scroll_fn(c, e2)
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
	if c.key_down_fn != unsafe { CanvasLayoutKeyFn(0) } {
		c.key_down_fn(c, *e)
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
	if c.char_fn != unsafe { CanvasLayoutKeyFn(0) } {
		c.char_fn(c, *e)
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) update_layout() {
	if c.is_canvas_layer {
		return
	}
	// TODO: test if this is necessary
	if c.is_root_layout {
		window := c.ui.window
		mut to_resize := window.mode in [.fullscreen, .max_size, .resizable]
		$if android {
			to_resize = true
		}
		if to_resize {
			c.resize(window.width, window.height)
		}
	}

	// update size and scrollview if necessary
	c.set_adjusted_size(c.ui)
	scrollview_update(c)
	// println("$c.id update_layout")
	c.set_drawing_children()
	// TODO: this make component/grid example failing
	// otherwise layout/canas_layout example failing
	scrollview_set_children_orig_xy(c, false)
}

// TODO: documentation
pub fn (mut c CanvasLayout) set_adjusted_size(gui &UI) {
	$if c_adj_size ? {
		c.debug_ids = env('UI_IDS').split(',').clone()
		c.debug_children_ids = []
		if c.debug_ids.len == 0 || c.id in c.debug_ids {
			println('cvl set_adj ${c.id} ${c.full_width} ${c.full_height}')
		}
	}
	if c.full_width > 0 && c.full_height > 0 {
		c.adj_width, c.adj_height = c.full_width, c.full_height
		return
	} else if c.full_width == -1 || c.full_height == -1 { // dynamical
		fw, fh := c.full_size()
		$if c_adj_size ? {
			if c.debug_ids.len == 0 || c.id in c.debug_ids {
				println('cvl set_adj by full_size ${c.id} ${fw} ${fh}')
			}
		}
		if fw > 0 && fh > 0 {
			c.adj_width, c.adj_height = fw, fh
			return
		}
	}
	mut w, mut h := 0, 0
	$if c_adj_size ? {
		if c.debug_ids.len == 0 || c.id in c.debug_ids {
			println('cvl ${c.id} children: ${c.children.map(it.id)}')
		}
	}
	for mut child in c.children {
		$if c_adj_size ? {
			if c.debug_ids.len == 0 || c.id in c.debug_ids {
				println('cvl child ${child.id} ${child.z_index} > ${z_index_hidden}')
			}
		}
		if child.z_index > z_index_hidden { // taking into account only visible widgets
			child_width, child_height := child.size()

			if child.x + child_width > w {
				w = child.x + child_width
			}
			if child.y + child_height > h {
				h = child.y + child_height
			}
			$if c_adj_size ? {
				if c.debug_ids.len == 0 || c.id in c.debug_ids {
					println('cvl size child ${child.id} ${child.type_name()} -> (${child.x} + ${child_width}, ${child.y} + ${child_height}) -> (${w}, ${h})')
				}
			}
		}
	}
	$if c_adj_size ? {
		if c.debug_ids.len == 0 || c.id in c.debug_ids {
			println('cl set_adj before: ${c.id} -> (${w}, ${h})')
		}
	}
	if c.width > w {
		w = c.width
	}
	if c.height > h {
		h = c.height
	}
	$if c_adj_size ? {
		if c.debug_ids.len == 0 || c.id in c.debug_ids {
			println('cl set_adj after: ${c.id} -> (${w}, ${h})')
		}
	}
	c.adj_width = w
	c.adj_height = h
}

// TODO: documentation
pub fn (mut c CanvasLayout) set_children_pos() {
	// println('scp ${c.id}')
	for i, mut child in c.children {
		// scrollview_widget_save_offset(child)
		child.set_pos(c.pos_[i].x + c.x + c.offset_x, c.pos_[i].y + c.y + c.offset_y)
		// scrollview_widget_restore_offset(child, true)
		if mut child is Stack {
			child.update_layout()
		}
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) set_child_relative_pos(id string, x int, y int) {
	for i, child in c.children {
		if child.id == id {
			c.pos_[i] = XYPos{x, y}
			scrollview_need_update(mut c)
		}
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) set_pos(x int, y int) {
	scrollview_widget_save_offset(c)
	c.x = x
	c.y = y
	c.bounding_changed()
	scrollview_widget_restore_offset(c, true)
	// scrollview_update_orig_size(c)
	c.set_children_pos()
}

// TODO: documentation
pub fn (c CanvasLayout) adj_size() (int, int) {
	return c.adj_width, c.adj_height
}

// TODO: documentation
pub fn (c CanvasLayout) size() (int, int) {
	return c.width, c.height
}

// possibly dynamic full size
pub fn (c &CanvasLayout) full_size() (int, int) {
	mut fw, mut fh := c.full_width, c.full_height
	// println('full_size $fw, $fh')
	if c.full_width == -1 || c.full_height == -1 {
		if c.full_size_fn == unsafe { nil } {
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

pub fn (mut c CanvasLayout) bounding_changed() {
	if c.bounding_change_fn != unsafe { nil } {
		c.bounding_change_fn(c, gg.Rect{c.x, c.y, c.width, c.height})
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) propose_size(w int, h int) (int, int) {
	// TODO: to check if this valid for everything
	c.width = if w > 0 { w } else { c.adj_width }
	c.height = if h > 0 { h } else { c.adj_height }
	scrollview_update(c)
	$if cl_ps ? {
		if c.id == 'dtv_root0' {
			println('cl propose_size ${c.id}   size(${c.width}, ${c.height}) -> adj_size(${c.adj_width}, ${c.adj_height})')
		}
	}
	c.bounding_changed()
	return c.width, c.height
}

fn (mut c CanvasLayout) set_drawing_children() {
	for mut child in c.children {
		if mut child is Stack {
			child.set_drawing_children()
		} else if mut child is CanvasLayout {
			child.set_drawing_children()
		} else if mut child is BoxLayout {
			child.set_drawing_children()
		}
		// println("z_index: ${child.type_name()} $child.z_index")
		if child.z_index > c.z_index {
			$if cl_z_index_update ? {
				println('${c.id} changed z_index from ${child.id} ${child.z_index}')
			}
			c.z_index = child.z_index - 1
		}
	}
	c.drawing_children = c.children.filter(!it.hidden)
	c.sorted_drawing_children()
}

fn (mut c CanvasLayout) draw() {
	c.draw_device(mut c.ui.dd)
}

fn (mut c CanvasLayout) draw_device(mut d DrawDevice) {
	if c.hidden {
		return
	}
	offset_start(mut c)
	defer {
		offset_end(mut c)
	}
	cstate := clipping_start(c, mut d) or { return }
	defer {
		clipping_end(c, mut d, cstate)
	}

	$if layout ? {
		if c.ui.layout_print {
			fw, fh := c.full_size()
			println('CanvasLayout(${c.id}): (${c.x}, ${c.y}, ${fw}, ${fh})')
		}
	}
	mut dtw := DrawTextWidget(c)
	dtw.draw_device_load_style(d)
	// if scrollview_clip(mut c) {
	// 	c.set_children_pos()
	// 	c.scrollview.children_to_update = false
	// }
	scrollview_draw_begin(mut c, d)
	defer {
		scrollview_draw_end(c, d)
	}

	// println("$c.id $c.style")
	if c.style.bg_color !in [no_color, transparent] {
		mut w, mut h := c.width, c.height
		fw, fh := c.full_size()
		if fw > 0 && fh > 0 {
			w = int(f32(fw) * c.ui.window.dpi_scale)
			h = int(f32(fh) * c.ui.window.dpi_scale)
		}
		// println("$c.id ($w, $h)")
		if c.style.bg_radius > 0 {
			radius := relative_size(c.style.bg_radius, w, h)
			c.draw_device_rounded_rect_filled(d, 0, 0, w, h, radius, c.style.bg_color)
		} else {
			c.draw_device_rect_filled(d, 0, 0, w, h, c.style.bg_color)
		}
	}

	if c.draw_device_fn != unsafe { CanvasLayoutDrawDeviceFn(0) } {
		c.draw_device_fn(mut d, c)
	}
	//$if cdraw_scroll ? {
	//	if Layout(c).has_scrollview_or_parent_scrollview() {
	//		// if c.scrollview != 0 {
	//		for i, mut child in c.drawing_children {
	//			if child !is Layout
	//				&& is_empty_intersection(c.scrollview.scissor_rect, child.bounds()) {
	//				sr := c.scrollview.scissor_rect // THIS WAS REMOVED
	//				cr := child.bounds()
	//				println('cdraw ${c.id} (${sr.x}, ${sr.y}, ${sr.width}, ${sr.height})  ${i}) ${child.type_name()} ${child.id} (${cr.x}, ${cr.y}, ${cr.width}, ${cr.height}) clipped')
	//			}
	//		}
	//	}
	//}

	// REMARK: DO NOT REMOVE -> not used maybe update later
	// active_scrollview := Layout(c).has_scrollview_or_parent_scrollview() && scrollview_is_active(c)
	for mut child in c.drawing_children {
		$if cl_draw_children ? {
			println('draw <${c.id}>: ${c.drawing_children.map(it.id)} at ${c.drawing_children.map(it.x)}')
		}
		// if active_scrollview {
		// 	// TODO: calculate whether child falls outside clipping rect and
		// 	// continue (i.e., skip child drawing)
		// 	// if mut child is Layout
		// 	//	|| !is_empty_intersection(c.scrollview.scissor_rect, child.bounds()) {
		// 	//	child.draw_device(mut d)
		// 	//}
		// }
		child.draw_device(mut d)
	}

	// if Layout(c).has_scrollview_or_parent_scrollview() && scrollview_is_active(c) {
	//	// if c.scrollview != 0  && scrollview_is_active(c) {
	//	$if cl_draw_children ? {
	//		println('draw <${c.id}>: ${c.drawing_children.map(it.id)}')
	//	}
	//	for mut child in c.drawing_children {
	//		if mut child is Layout
	//			|| !is_empty_intersection(c.scrollview.scissor_rect, child.bounds()) {
	//			child.draw_device(mut d)
	//		}
	//	}
	//} else {
	//	$if cl_draw_children ? {
	//		println('draw <${c.id}>: ${c.drawing_children.map(it.id)} at ${c.drawing_children.map(it.x)}')
	//	}
	//	for mut child in c.drawing_children {
	//		child.draw_device(mut d)
	//	}
	//}

	if c.post_draw_device_fn != unsafe { CanvasLayoutDrawDeviceFn(0) } {
		c.post_draw_device_fn(mut *d, c)
	}
}

// TODO: documentation
pub fn (mut c CanvasLayout) set_visible(state bool) {
	c.hidden = !state
	for mut child in c.children {
		child.set_visible(state)
	}
}

// TODO: documentation
pub fn (c &CanvasLayout) point_inside(x f64, y f64) bool {
	return scrollview_widget_point_inside(c, x, y)
}

fn (c &CanvasLayout) get_ui() &UI {
	return c.ui
}

fn (mut c CanvasLayout) resize(width int, height int) {
	c.propose_size(width, height)
}

fn (c &CanvasLayout) get_subscriber() &eventbus.Subscriber[string] {
	parent := c.parent
	return parent.get_subscriber()
}

// TODO: documentation
pub fn (mut c CanvasLayout) focus() {
	mut f := Focusable(c)
	f.set_focus()
}

// TODO: documentation
pub fn (mut c CanvasLayout) unfocus() {
	c.is_focused = false
}

// TODO: documentation
pub fn (c &CanvasLayout) get_children() []Widget {
	return c.children
}

// TODO: documentation
pub fn (c &CanvasLayout) child_index_by_id(id string) int {
	for i, child in c.children {
		if child.id() == id {
			return i
		}
	}
	return -1
}

//

// TODO: documentation
pub fn (c &CanvasLayout) orig_pos(x f64, y f64) (int, int) {
	return int(x + c.x + c.offset_x), int(y + c.y + c.offset_y)
}

// TODO: documentation
pub fn (c &CanvasLayout) abs_pos(x f64, y f64) (int, int) {
	cx, cy := if has_scrollview(c) { c.scrollview.orig_xy() } else { c.x, c.y }
	return int(x + cx + c.offset_x), int(y + cy + c.offset_y)
}

// TODO: documentation
pub fn (c &CanvasLayout) rel_pos(x f64, y f64) (f32, f32) {
	return f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y)
}

// TODO: documentation
pub fn (c &CanvasLayout) rel_pos_x(x f64) f32 {
	return f32(x + c.x + c.offset_x)
}

// TODO: documentation
pub fn (c &CanvasLayout) rel_pos_y(y f64) f32 {
	// println("$y + $c.y + $c.offset_y")
	return f32(y + c.y + c.offset_y)
}

// Methods for delegating drawing methods relatively to canvas coordinates

// ---- text

// TODO: documentation
pub fn (c &CanvasLayout) draw_text(x int, y int, text string) {
	c.draw_device_text(c.ui.dd, x, y, text)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_text(d DrawDevice, x int, y int, text string) {
	mut dtw := DrawTextWidget(c)
	// println("dt $x + $c.x + $c.offset_x, $y + $c.y + $c.offset_y, $text")
	dtw.draw_device_text(d, x + c.x + c.offset_x, y + c.y + c.offset_y, text)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_styled_text(x int, y int, text string, ts TextStyleParams) {
	mut dtw := DrawTextWidget(c)
	dtw.draw_device_styled_text(c.ui.dd, x + c.x + c.offset_x, y + c.y + c.offset_y, text,
		ts)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_styled_text(d DrawDevice, x int, y int, text string, ts TextStyleParams) {
	mut dtw := DrawTextWidget(c)
	dtw.draw_device_styled_text(d, x + c.x + c.offset_x, y + c.y + c.offset_y, text, ts)
}

// ---- triangle

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_triangle_empty(d DrawDevice, x f64, y f64, x2 f64, y2 f64, x3 f64, y3 f64, color gx.Color) {
	d.draw_triangle_empty(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), f32(x2 + c.x +
		c.offset_x), f32(y2 + c.y + c.offset_y), f32(x3 + c.x + c.offset_x), f32(y3 + c.y +
		c.offset_y), color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_triangle_filled(d DrawDevice, x f64, y f64, x2 f64, y2 f64, x3 f64, y3 f64, color gx.Color) {
	d.draw_triangle_filled(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), f32(x2 + c.x +
		c.offset_x), f32(y2 + c.y + c.offset_y), f32(x3 + c.x + c.offset_x), f32(y3 + c.y +
		c.offset_y), color)
}

// ---- square

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_square_empty(d DrawDevice, x f64, y f64, s f32, color gx.Color) {
	c.draw_device_rect_empty(d, f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y),
		s, s, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_square_filled(d DrawDevice, x f64, y f64, s f32, color gx.Color) {
	c.draw_device_rect_filled(d, f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y),
		s, s, color)
}

// ---- rectangle

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_rect_empty(d DrawDevice, x f64, y f64, w f32, h f32, color gx.Color) {
	d.draw_rect_empty(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), w, h, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_rect_filled(d DrawDevice, x f64, y f64, w f32, h f32, color gx.Color) {
	d.draw_rect_filled(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), w, h, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_rounded_rect_filled(d DrawDevice, x f64, y f64, w f32, h f32, radius f32, color gx.Color) {
	rad := relative_size(radius, int(w), int(h))
	d.draw_rounded_rect_filled(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), w,
		h, rad, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_rounded_rect_empty(d DrawDevice, x f64, y f64, w f32, h f32, radius f32, border_color gx.Color) {
	rad := relative_size(radius, int(w), int(h))
	d.draw_rounded_rect_empty(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), w,
		h, rad, border_color)
}

// ---- circle

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_circle_line(d DrawDevice, x f64, y f64, r int, segments int, color gx.Color) {
	d.draw_circle_line(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), r, segments,
		color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_circle_empty(d DrawDevice, x f64, y f64, r f32, color gx.Color) {
	d.draw_circle_empty(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), r, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_circle_filled(d DrawDevice, x f64, y f64, r f32, color gx.Color) {
	d.draw_circle_filled(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), r, color)
}

// ---- slice

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_slice_empty(d DrawDevice, x f64, y f64, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	d.draw_slice_empty(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), r, start_angle,
		end_angle, segments, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_slice_filled(d DrawDevice, x f64, y f64, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	d.draw_slice_filled(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), r, start_angle,
		end_angle, segments, color)
}

// ---- arc

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_arc_empty(d DrawDevice, x f64, y f64, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	d.draw_arc_empty(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), radius, thickness,
		start_angle, end_angle, segments, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_arc_filled(d DrawDevice, x f64, y f64, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	d.draw_arc_filled(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), radius, thickness,
		start_angle, end_angle, segments, color)
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_arc_line(d DrawDevice, x f64, y f64, radius f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	d.draw_arc_line(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), radius, start_angle,
		end_angle, segments, color)
}

// ---- line

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_line(d DrawDevice, x f64, y f64, x2 f64, y2 f64, color gx.Color) {
	// println("dl $x + $c.x + $c.offset_x, $y + $c.y + $c.offset_y, $x2 + $c.x + $c.offset_x,
	// $y2 + $c.y + $c.offset_y")
	d.draw_line(f32(x + c.x + c.offset_x), f32(y + c.y + c.offset_y), f32(x2 + c.x + c.offset_x),
		f32(y2 + c.y + c.offset_y), color)
}

// ---- polygon
// TODO: What to do about canvas offset?
// TODO: documentation
pub fn (c &CanvasLayout) draw_device_convex_poly(d DrawDevice, points []f32, color gx.Color) {
}

// TODO: documentation
pub fn (c &CanvasLayout) draw_device_empty_poly(d DrawDevice, points []f32, color gx.Color) {
}

// special stuff for surrounding rectangle

pub fn (c &CanvasLayout) draw_device_rect_surrounded(d DrawDevice, x f32, y f32, w f32, h f32, size int, color gx.Color) {
	c.draw_device_rect_filled(d, x - size, y - size, w + 2 * size, size, color)
	c.draw_device_rect_filled(d, x - size, y + h, w + 2 * size, size, color)
	c.draw_device_rect_filled(d, x - size, y - size, size, h + 2 * size, color)
	c.draw_device_rect_filled(d, x + w, y - size, size, h + 2 * size, color)
}
