module ui

import gx
import gg
import sokol.sgl
import math

// ScrollView exists only when attached to Widget
// Is it not a widget but attached to a widget.
// A ScrollableWidget would have a field scrollview

const (
	scrollbar_size                 = 10
	scroolbar_thumb_color          = gx.rgb(87, 153, 245)
	scrollbar_background_color     = gx.rgb(219, 219, 219)
	scrollbar_button_color         = gx.rgb(150, 150, 150)
	scrollbar_focused_button_color = gx.rgb(100, 100, 100)
	scrollview_delta_key           = 5
	scrollview_delta_mouse         = 10
	null_scrollview                = &ScrollView(0)
)

enum ScrollViewEvent {
	all
	mouse
	key_x
	key_y
	key
	scroll_x
	scroll_y
	scroll
}

enum ScrollViewActive {
	auto
	auto_xy
	auto_x
	auto_y
	x
	y
	xy
}

enum ScrollViewPart {
	view
	btn_x
	btn_y
	bar_x
	bar_y
}

interface ScrollableWidget {
mut:
	has_scrollview bool
	scrollview &ScrollView
	id string
	x int
	y int
	ui &UI
	offset_x int
	offset_y int
	adj_size() (int, int)
	size() (int, int)
}

pub fn scrollview(w Widget) (bool, &ScrollView) {
	if w is Stack {
		if w.has_scrollview {
			return true, w.scrollview
		}
	} else if w is CanvasLayout {
		if w.has_scrollview {
			return true, w.scrollview
		}
	} else if w is ListBox {
		if w.has_scrollview {
			return true, w.scrollview
		}
	}
	return false, &ScrollView(0)
}

// pub fn scrollview(w Widget) ?&ScrollView {
// 	if w is Stack {
// 		if w.has_scrollview {
// 			return w.scrollview
// 		}
// 	} else if w is CanvasLayout {
// 		if w.has_scrollview {
// 			return w.scrollview
// 		}
// 	} else if w is ListBox {
// 		if w.has_scrollview {
// 			return w.scrollview
// 		}
// 	}
// 	return none
// }

pub fn has_scrollview(w ScrollableWidget) bool {
	return w.has_scrollview
}

pub fn scrollview_is_active(mut w ScrollableWidget) bool {
	return w.has_scrollview && w.scrollview.is_active()
}

pub fn scrollview_add<T>(mut w T) {
	mut sv := &ScrollView{
		ui: 0
	}
	// IMPORTANT (sort of bug):
	// declaring `widget: w` inside struct before work for stack but not for canvas_layout
	sv.widget = w
	// TEST for the bug above
	// mut w2 := sv.widget
	// wi, he := w2.size()
	// println("add: ($wi, $he) -> ($w.width, $w.height)")
	w.scrollview = sv
	w.has_scrollview = true
}

pub fn scrollview_widget_set_orig_size(w Widget) {
	if w is Stack {
		if has_scrollview(w) {
			scrollview_set_orig_size(w)
		}
		for child in w.children {
			scrollview_widget_set_orig_size(child)
		}
	} else if w is CanvasLayout {
		if has_scrollview(w) {
			scrollview_set_orig_size(w)
		}
		for child in w.children {
			scrollview_widget_set_orig_size(child)
		}
	} else if w is ListBox {
		if has_scrollview(w) {
			scrollview_set_orig_size(w)
		}
	}
}

pub fn scrollview_set_orig_size<T>(w &T) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		sv.orig_x, sv.orig_y = w.x, w.y
		sv.offset_x, sv.offset_y = 0, 0
		if sv.active_x {
			sv.change_value(.btn_x)
		}
		if sv.active_y {
			sv.change_value(.btn_y)
		}
		// println('set orig size $.id: ($w.x, $w.y)')
	}
}

pub fn scrollview_delegate_parent_scrollview<T>(mut w T) {
	parent := w.parent
	if parent is Stack {
		w.scrollview = parent.scrollview
	} else if parent is CanvasLayout {
		w.scrollview = parent.scrollview
	}
}

pub fn scrollview_update<T>(w &T) {
	if has_scrollview(w) {
		mut sw := w.scrollview
		sw.update()
	}
}

pub fn scrollview_draw_begin<T>(mut w T) {
	if scrollview_is_active(mut w) {
		mut sv := w.scrollview
		if sv.children_to_update {
			svx, svy := sv.orig_size()
			if sv.active_x {
				w.x = svx - sv.offset_x
			}
			if sv.active_y {
				w.y = svy - sv.offset_y
			}
			w.set_children_pos()
			sv.children_to_update = false
		}

		sv.clip()
	}
}

pub fn scrollview_draw_end<T>(w &T) {
	if has_scrollview(w) {
		sv := w.scrollview
		sv.draw()
	}
}

// OBSOLETE:
// pub fn scrollview_clip<T>(mut w T) bool {
// 	if scrollview_is_active(mut w) {
// 		mut sv := w.scrollview
// 		sv.clip()
// 		w.x = sv.orig_x - sv.offset_x
// 		w.y = sv.orig_y - sv.offset_y
// 		// sv.orig_x, sv.orig_y = w.x - sv.offset_x, w.y - sv.offset_y
// 		// println('clip offfset ($sv.offset_x, $sv.offset_y)')
// 		return sv.children_to_update
// 	}
// 	return false
// }

// pub fn scrollview_draw<T>(w &T) {
// 	if has_scrollview(w) {
// 		sv := w.scrollview
// 		sv.draw()
// 	}
// }

// type ScrollViewChangedFn = fn (arg_1 voidptr, arg_2 voidptr)

[heap]
pub struct ScrollView {
pub mut:
	widget ScrollableWidget
	// color
	btn_color_x gx.Color = ui.scrollbar_button_color
	btn_color_y gx.Color = ui.scrollbar_button_color
	// horizontal scrollbar
	sb_w  int
	btn_x int
	btn_w int
	// vertical scrollbar
	sb_h  int
	btn_y int
	btn_h int
	// offset
	offset_x int
	offset_y int
	// active scrollbar
	active_x bool
	active_y bool
	// dragging
	dragging    int // 0=invalid, 1=x, 2=y
	drag_offset int
	// to update children pos
	children_to_update bool
	// focus
	is_focused bool
	// sizes of widget
	orig_x     int
	orig_y     int
	width      int
	height     int
	adj_width  int
	adj_height int
	win_width  int
	win_height int
	ui         &UI = 0
	// scissor
	scissor_rect gg.Rect
	parent       Layout
}

fn (mut sv ScrollView) init(parent Layout) {
	mut widget := sv.widget
	ui := widget.ui // get_ui()
	sv.ui = ui
	sv.parent = parent

	// max size first
	size := gg.window_size_real_pixels()
	sv.scissor_rect = gg.Rect{f32(0), f32(0), f32(size.width), f32(size.height)}

	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, scrollview_click, sv)
	subscriber.subscribe_method(events.on_scroll, scrollview_scroll, sv)
	subscriber.subscribe_method(events.on_key_down, scrollview_key_down, sv)
	subscriber.subscribe_method(events.on_mouse_down, scrollview_mouse_down, sv)
	subscriber.subscribe_method(events.on_mouse_up, scrollview_mouse_up, sv)
	subscriber.subscribe_method(events.on_mouse_move, scrollview_mouse_move, sv)
	$if android {
		subscriber.subscribe_method(events.on_touch_down, scrollview_mouse_down, sv)
		subscriber.subscribe_method(events.on_touch_up, scrollview_mouse_up, sv)
		subscriber.subscribe_method(events.on_touch_move, scrollview_touch_move, sv)
	}
}

[manualfree]
pub fn (mut sv ScrollView) cleanup() {
	mut subscriber := sv.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, sv)
	subscriber.unsubscribe_method(events.on_scroll, sv)
	subscriber.unsubscribe_method(events.on_key_down, sv)
	subscriber.unsubscribe_method(events.on_mouse_down, sv)
	subscriber.unsubscribe_method(events.on_mouse_up, sv)
	subscriber.unsubscribe_method(events.on_mouse_move, sv)
	$if android {
		subscriber.subscribe_method(events.on_touch_down, sv)
		subscriber.subscribe_method(events.on_touch_up, sv)
		subscriber.subscribe_method(events.on_touch_move, sv)
	}
	unsafe { sv.free() }
}

[unsafe]
pub fn (sv &ScrollView) free() {
	unsafe { free(sv) }
}

fn (sv &ScrollView) parent_offset() (int, int) {
	mut ox, mut oy := 0, 0
	parent := sv.parent
	if parent is Stack {
		if parent.scrollview != voidptr(0) {
			psv := parent.scrollview
			if psv.active_x {
				ox += psv.offset_x
			}
			if psv.active_y {
				oy += psv.offset_y
			}
			pox, poy := psv.parent_offset()
			ox += pox
			oy += poy
		}
	} else if parent is CanvasLayout {
		if parent.scrollview != voidptr(0) {
			psv := parent.scrollview
			if psv.active_x {
				ox += psv.offset_x
			}
			if psv.active_y {
				oy += psv.offset_y
			}
			pox, poy := psv.parent_offset()
			ox += pox
			oy += poy
		}
	}
	return ox, oy
}

fn (sv &ScrollView) orig_size() (int, int) {
	ox, oy := sv.parent_offset()
	return sv.orig_x - ox, sv.orig_y - oy
}

fn (sv &ScrollView) parent_scissor_rect() gg.Rect {
	parent := sv.parent
	size := gg.window_size_real_pixels()
	mut scissor_rect := gg.Rect{f32(0), f32(0), f32(size.width), f32(size.height)}
	if parent is Stack {
		if parent.scrollview != voidptr(0) {
			psv := parent.scrollview
			scissor_rect = psv.scissor_rect
		}
	} else if parent is CanvasLayout {
		if parent.scrollview != voidptr(0) {
			psv := parent.scrollview
			scissor_rect = psv.scissor_rect
		}
	}
	return scissor_rect
}

fn (mut sv ScrollView) update() {
	sv.width, sv.height = sv.widget.size()
	sv.adj_width, sv.adj_height = sv.widget.adj_size()
	sv.active_x, sv.active_y = sv.adj_width > sv.width, sv.adj_height > sv.height

	$if svu ? {
		println('scroll $sv.widget.id: ($sv.active_x = $sv.width < $sv.adj_width, $sv.active_y = $sv.height < $sv.adj_height)')
	}

	if sv.active_x {
		sv.sb_w = sv.width - ui.scrollbar_size
		sv.btn_w = int(f32(sv.width) / f32(sv.adj_width) * f32(sv.sb_w))
	}
	if sv.active_y {
		sv.sb_h = sv.height - ui.scrollbar_size
		sv.btn_h = int(f32(sv.height) / f32(sv.adj_height) * f32(sv.sb_h))
	}
}

pub fn (sv &ScrollView) is_active() bool {
	return sv.active_x || sv.active_y
}

fn (sv &ScrollView) children_point_inside(x f64, y f64, mode ScrollViewPart) bool {
	w := sv.widget
	if w is Stack {
		for child in w.children {
			ok, csv := scrollview(child)
			if ok {
				return csv.point_inside(x, y, mode) || csv.children_point_inside(x, y, mode)
			}
		}
	} else if w is CanvasLayout {
		for child in w.children {
			ok, csv := scrollview(child)
			if ok {
				return csv.point_inside(x, y, mode) || csv.children_point_inside(x, y, mode)
			}
		}
	}
	return false
}

fn (sv &ScrollView) point_inside(x f64, y f64, mode ScrollViewPart) bool {
	mut x_min, mut y_min, mut x_max, mut y_max := 0, 0, 0, 0
	svx, svy := sv.orig_size()
	match mode {
		.view {
			x_min, y_min = svx + sv.widget.offset_x, svy + sv.widget.offset_y
			x_max, y_max = x_min + sv.width, y_min + sv.height
		}
		.bar_x {
			x_min, y_min = svx, svy + sv.height - ui.scrollbar_size
			x_max, y_max = x_min + sv.sb_w, y_min + ui.scrollbar_size
		}
		.bar_y {
			x_min, y_min = svx + sv.width - ui.scrollbar_size, svy
			x_max, y_max = x_min + ui.scrollbar_size, y_min + sv.sb_h
		}
		.btn_x {
			x_min, y_min = svx + sv.btn_x, svy + sv.height - ui.scrollbar_size
			x_max, y_max = x_min + sv.btn_w, y_min + ui.scrollbar_size
		}
		.btn_y {
			x_min, y_min = svx + sv.width - ui.scrollbar_size, svy + sv.btn_y
			x_max, y_max = x_min + ui.scrollbar_size, y_min + sv.btn_h
		}
	}
	return x >= x_min && x <= x_max && y >= y_min && y <= y_max
}

fn (mut sv ScrollView) change_value(mode ScrollViewPart) {
	sv.children_to_update = true
	if mode == .btn_x {
		if sv.offset_x < 0 {
			sv.offset_x = 0
		}
		max_offset_x, a_x := sv.coef_x()
		if sv.offset_x > max_offset_x {
			sv.offset_x = max_offset_x
		}
		sv.btn_x = int(f32(sv.offset_x) * a_x)
	} else if mode == .btn_y {
		if sv.offset_y < 0 {
			sv.offset_y = 0
		}
		max_offset_y, a_y := sv.coef_y()
		if sv.offset_y > max_offset_y {
			sv.offset_y = max_offset_y
		}
		sv.btn_y = int(f32(sv.offset_y) * a_y)
	}
}

pub fn (mut sv ScrollView) clip() {
	if sv.is_active() {
		svx, svy := sv.orig_size()
		sr := gg.Rect{
			x: svx * gg.dpi_scale()
			y: svy * gg.dpi_scale()
			width: sv.width * gg.dpi_scale()
			height: sv.height * gg.dpi_scale()
		}
		psr := sv.parent_scissor_rect()
		scissor_rect := intersection(sr, psr)
		sgl.scissor_rect(int(scissor_rect.x), int(scissor_rect.y), int(scissor_rect.width),
			int(scissor_rect.height), true)
		sv.scissor_rect = scissor_rect
	} else {
		if !sv.active_x {
			sv.offset_x = 0
		}
		if !sv.active_y {
			sv.offset_y = 0
		}
	}
}

pub fn (sv &ScrollView) draw() {
	scissor_rect := sv.parent_scissor_rect()
	sgl.scissor_rect(int(scissor_rect.x), int(scissor_rect.y), int(scissor_rect.width),
		int(scissor_rect.height), true)

	svx, svy := sv.orig_size()

	if sv.active_x {
		// horizontal scrollbar
		sv.ui.gg.draw_rounded_rect(svx, svy + sv.height - ui.scrollbar_size, sv.sb_w,
			ui.scrollbar_size, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// horizontal button
		sv.ui.gg.draw_rounded_rect(svx + sv.btn_x, svy + sv.height - ui.scrollbar_size,
			sv.btn_w, ui.scrollbar_size, ui.scrollbar_size / 3, sv.btn_color_x)
	}
	if sv.active_y {
		// vertical scrollbar
		sv.ui.gg.draw_rounded_rect(svx + sv.width - ui.scrollbar_size, svy, ui.scrollbar_size,
			sv.sb_h, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// vertical button
		sv.ui.gg.draw_rounded_rect(svx + sv.width - ui.scrollbar_size, svy + sv.btn_y,
			ui.scrollbar_size, sv.btn_h, ui.scrollbar_size / 3, sv.btn_color_y)
	}
}

fn scrollview_scroll(mut sv ScrollView, e &ScrollEvent, zzz voidptr) {
	if sv.is_active() && sv.point_inside(e.mouse_x, e.mouse_y, .view)
		&& !sv.children_point_inside(e.mouse_x, e.mouse_y, .view) {
		if sv.active_x {
			sv.offset_x += int(e.x * ui.scrollview_delta_mouse)
			sv.change_value(.btn_x)
		}

		if sv.active_y {
			sv.offset_y += int(e.y * ui.scrollview_delta_mouse)
			sv.change_value(.btn_y)
		}
	}
}

fn scrollview_click(mut sv ScrollView, e &MouseEvent, zzz voidptr) {
	if !sv.is_active() {
		return
	}
	sv.is_focused = sv.point_inside(e.x, e.y, .view) && !sv.children_point_inside(e.x, e.y, .view)
	if sv.active_x && sv.point_inside(e.x, e.y, .bar_x) {
		sv.is_focused = true
		_, a_x := sv.coef_x()
		sv.offset_x = int((e.x - sv.orig_x - sv.btn_x / 2) / a_x)
		sv.change_value(.btn_x)
	} else if sv.active_y && sv.point_inside(e.x, e.y, .bar_y) {
		sv.is_focused = true
		_, a_y := sv.coef_y()
		sv.offset_y = int((e.y - sv.orig_y - sv.btn_y / 2) / a_y)
		sv.change_value(.btn_y)
	}
}

fn scrollview_touch_move(mut sv ScrollView, e &MouseMoveEvent, zzz voidptr) {
	if !sv.is_active() {
		return
	}
	// TODO
}

fn scrollview_mouse_down(mut sv ScrollView, e &MouseEvent, zzz voidptr) {
	if !sv.is_active() {
		return
	}
	if int(e.button) == 0 {
		if sv.active_x && sv.point_inside(e.x, e.y, .btn_x) {
			sv.dragging = 1 // x
			sv.drag_offset = e.x
		} else if sv.active_y && sv.point_inside(e.x, e.y, .btn_y) {
			sv.dragging = 2 // y
			sv.drag_offset = e.y
		}
	}
}

fn scrollview_mouse_up(mut sv ScrollView, e &MouseEvent, zzz voidptr) {
	if !sv.is_active() {
		return
	}
	sv.dragging = 0 // invalid neither x nor y
	sv.drag_offset = 0
}

fn scrollview_mouse_move(mut sv ScrollView, e &MouseMoveEvent, zzz voidptr) {
	if !sv.is_active() {
		return
	}
	sv.btn_color_x = if sv.point_inside(e.x, e.y, .btn_x) {
		ui.scrollbar_focused_button_color
	} else {
		ui.scrollbar_button_color
	}
	sv.btn_color_y = if sv.point_inside(e.x, e.y, .btn_y) {
		ui.scrollbar_focused_button_color
	} else {
		ui.scrollbar_button_color
	}
	if !sv.ui.btn_down[0] {
		sv.dragging = 0 // invalid neither x nor y
	} else if sv.dragging > 0 {
		if sv.dragging == 1 {
			_, a_x := sv.coef_x()
			sv.offset_x = int(f32(e.x - sv.drag_offset) / a_x)
		} else {
			_, a_y := sv.coef_y()
			sv.offset_y = int(f32(e.y - sv.drag_offset) / a_y)
		}
		sv.change_value(ScrollViewPart(sv.dragging))
	}
}

fn scrollview_key_down(mut sv ScrollView, e &KeyEvent, zzz voidptr) {
	if !sv.is_active() || !sv.is_focused {
		return
	}
	match e.key {
		.up {
			if sv.active_y {
				sv.offset_y -= ui.scrollview_delta_key
				sv.change_value(.btn_y)
			}
		}
		.down {
			if sv.active_y {
				sv.offset_y += ui.scrollview_delta_key
				sv.change_value(.btn_y)
			}
		}
		.left {
			if sv.active_x {
				sv.offset_x -= ui.scrollview_delta_key
				sv.change_value(.btn_x)
			}
		}
		.right {
			if sv.active_x {
				sv.offset_x += ui.scrollview_delta_key
				sv.change_value(.btn_x)
			}
		}
		else {}
	}
}

fn (sv &ScrollView) coef_x() (int, f32) {
	max_offset_x := sv.adj_width - sv.width + 2 * ui.scrollbar_size
	return max_offset_x, f32(sv.sb_w - sv.btn_w) / f32(max_offset_x)
}

fn (sv &ScrollView) coef_y() (int, f32) {
	max_offset_y := (sv.adj_height - sv.height + 2 * ui.scrollbar_size)
	return max_offset_y, f32(sv.sb_h - sv.btn_h) / f32(max_offset_y)
}

fn intersection(r1 gg.Rect, r2 gg.Rect) gg.Rect {
	// top left and bottom right points
	tl_x, tl_y := math.max(r1.x, r2.x), math.max(r1.y, r2.y)
	br_x, br_y := math.min(r1.x + r1.width, r2.x + r2.width), math.min(r1.y + r1.height,
		r2.y + r2.height)
	// interesction
	r := gg.Rect{f32(tl_x), f32(tl_y), f32(br_x - tl_x), f32(br_y - tl_y)}
	return r
}
