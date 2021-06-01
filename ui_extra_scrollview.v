module ui

import gx
import gg
import sokol.sgl

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
)

enum ScrollMode {
	view
	btn_x
	btn_y
	bar_x
	bar_y
}

interface ScrollableWidget {
mut:
	x int
	y int
	offset_x int
	offset_y int
	scrollview &ScrollView
	adj_size() (int, int)
	size() (int, int)
	get_ui() &UI
}

pub fn has_scrollview(w ScrollableWidget) bool {
	return w.scrollview != voidptr(0)
}

pub fn is_active_scrollview(mut w ScrollableWidget) bool {
	return w.scrollview != voidptr(0) && w.scrollview.is_active()
}

pub fn update_orig_size<T>(w &T) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		sv.orig_x, sv.orig_y = w.x, w.y
		sv.offset_x, sv.offset_y = 0, 0
		// println('orig size: ($w.x, $w.y)')
	}
}

pub fn update_scrollview<T>(w &T) {
	if has_scrollview(w) {
		mut sw := w.scrollview
		sw.update()
	}
}

pub fn clip_scrollview<T>(mut w T) bool {
	if is_active_scrollview(mut w) {
		mut sv := w.scrollview
		sv.clip()
		w.x = sv.orig_x + sv.offset_x
		w.y = sv.orig_y + sv.offset_y
		// sv.orig_x, sv.orig_y = w.x - sv.offset_x, w.y - sv.offset_y
		// println('clip offfset ($sv.offset_x, $sv.offset_y)')
		return true
	}
	return false
}

pub fn draw_scrollview<T>(w &T) {
	if has_scrollview(w) {
		sv := w.scrollview
		sv.draw()
	}
}

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
}

pub fn add_scrollview<T>(mut w T) {
	sv := &ScrollView{
		widget: w
		ui: 0
	}
	w.scrollview = sv
}

fn (mut sv ScrollView) init(parent Layout) {
	mut widget := sv.widget
	ui := widget.get_ui()
	sv.ui = ui
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

fn (mut sv ScrollView) update() {
	sv.width, sv.height = sv.widget.size()
	sv.adj_width, sv.adj_height = sv.widget.adj_size()
	sv.active_x, sv.active_y = sv.adj_width > sv.width, sv.adj_height > sv.height

	$if svu ? {
		println('scroll: ($sv.active_x = $sv.width < $sv.adj_width, $sv.active_y = $sv.height < $sv.adj_height)')
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

fn (sv &ScrollView) point_inside(x f64, y f64, mode ScrollMode) bool {
	mut x_min, mut y_min, mut x_max, mut y_max := 0, 0, 0, 0
	match mode {
		.view {
			x_min, y_min = sv.orig_x + sv.widget.offset_x, sv.orig_y + sv.widget.offset_y
			x_max, y_max = x_min + sv.width, y_min + sv.height
		}
		.bar_x {
			x_min, y_min = sv.orig_x, sv.orig_y + sv.height - ui.scrollbar_size
			x_max, y_max = x_min + sv.sb_w, y_min + ui.scrollbar_size
		}
		.bar_y {
			x_min, y_min = sv.orig_x + sv.width - ui.scrollbar_size, sv.orig_y
			x_max, y_max = x_min + ui.scrollbar_size, y_min + sv.sb_h
		}
		.btn_x {
			x_min, y_min = sv.orig_x + sv.btn_x, sv.orig_y + sv.height - ui.scrollbar_size
			x_max, y_max = x_min + sv.btn_w, y_min + ui.scrollbar_size
		}
		.btn_y {
			x_min, y_min = sv.orig_x + sv.width - ui.scrollbar_size, sv.orig_y + sv.btn_y
			x_max, y_max = x_min + ui.scrollbar_size, y_min + sv.btn_h
		}
	}
	return x >= x_min && x <= x_max && y >= y_min && y <= y_max
}

fn (mut sv ScrollView) change_value(mode ScrollMode) {
	if mode == .btn_x {
		if sv.offset_x > 0 {
			sv.offset_x = 0
		}
		min_offset_x := -(sv.adj_width - sv.width + 2 * ui.scrollbar_size)
		if sv.offset_x < min_offset_x {
			sv.offset_x = min_offset_x
		}
		sv.btn_x = int(f32(sv.offset_x) * f32(sv.sb_w - sv.btn_w) / f32(min_offset_x))
	} else if mode == .btn_y {
		if sv.offset_y > 0 {
			sv.offset_y = 0
		}
		min_offset_y := -(sv.adj_height - sv.height + 2 * ui.scrollbar_size)
		if sv.offset_y < min_offset_y {
			sv.offset_y = min_offset_y
		}
		sv.btn_y = int(f32(sv.offset_y) * f32(sv.sb_h - sv.btn_h) / f32(min_offset_y))
	}
}

pub fn (mut sv ScrollView) clip() {
	if sv.is_active() {
		sgl.scissor_rect(int(sv.orig_x * gg.dpi_scale()), int(sv.orig_y * gg.dpi_scale()),
			int(sv.width * gg.dpi_scale()), int(sv.height * gg.dpi_scale()), true)
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
	size := gg.window_size_real_pixels()
	sgl.viewport(0, 0, size.width, size.height, true)
	sgl.scissor_rect(0, 0, size.width, size.height, true)
	if sv.active_x {
		// horizontal scrollbar
		sv.ui.gg.draw_rounded_rect(sv.orig_x, sv.orig_y + sv.height - ui.scrollbar_size,
			sv.sb_w, ui.scrollbar_size, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// horizontal button
		sv.ui.gg.draw_rounded_rect(sv.orig_x + sv.btn_x, sv.orig_y + sv.height - ui.scrollbar_size,
			sv.btn_w, ui.scrollbar_size, ui.scrollbar_size / 3, sv.btn_color_x)
	}
	if sv.active_y {
		// vertical scrollbar
		sv.ui.gg.draw_rounded_rect(sv.orig_x + sv.width - ui.scrollbar_size, sv.orig_y,
			ui.scrollbar_size, sv.sb_h, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// vertical button
		sv.ui.gg.draw_rounded_rect(sv.orig_x + sv.width - ui.scrollbar_size, sv.orig_y + sv.btn_y,
			ui.scrollbar_size, sv.btn_h, ui.scrollbar_size / 3, sv.btn_color_y)
	}
}

fn scrollview_scroll(mut sv ScrollView, e &ScrollEvent, zzz voidptr) {
	if sv.is_active() && sv.point_inside(e.mouse_x, e.mouse_y, .view) {
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
	sv.is_focused = sv.point_inside(e.x, e.y, .view)

	// TODO
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
			sv.offset_x = sv.drag_offset - int(e.x)
		} else {
			sv.offset_y = sv.drag_offset - int(e.y)
		}
		sv.change_value(ScrollMode(sv.dragging))
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
