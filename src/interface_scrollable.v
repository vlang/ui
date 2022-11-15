module ui

import gx
import gg

// ScrollView exists only when attached to Widget
// Is it not a widget but attached to a widget.
// A ScrollableWidget would have a field scrollview

pub const (
	scrollbar_size                 = 10
	scroolbar_thumb_color          = gx.rgb(87, 153, 245)
	scrollbar_background_color     = gx.rgb(219, 219, 219)
	scrollbar_button_color         = gx.rgb(150, 150, 150)
	scrollbar_focused_button_color = gx.rgb(100, 100, 100)
	scrollview_delta_key           = 5
	// scrollview_delta_mouse         = 10
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

pub enum ScrollViewPart {
	view
	btn_x
	btn_y
	bar_x
	bar_y
	bar
}

type ScrollViewChangedFn = fn (sw ScrollableWidget)

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
	on_scroll_change ScrollViewChangedFn
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
	} else if w is TextBox {
		if w.has_scrollview {
			return true, w.scrollview
		}
	}
	return false, &ScrollView(0)
}

pub fn has_scrollview(w ScrollableWidget) bool {
	return w.has_scrollview
}

pub fn has_scrollview_or_parent_scrollview(w ScrollableWidget) bool {
	return unsafe { w.scrollview != 0 }
}

pub fn scrollview_is_active(w ScrollableWidget) bool {
	return w.has_scrollview && w.scrollview.is_active()
}

pub fn scrollview_need_update(mut w ScrollableWidget) {
	if w.has_scrollview {
		w.scrollview.children_to_update = true
	}
}

pub fn scrollview_add<T>(mut w T) {
	mut sv := &ScrollView{
		parent: w.parent
		widget: w
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

pub fn scrollview_widget_set_orig_xy(w Widget) {
	if w is Stack {
		if has_scrollview(w) {
			scrollview_set_orig_xy(w)
		}
		for child in w.children {
			scrollview_widget_set_orig_xy(child)
		}
	} else if w is CanvasLayout {
		if has_scrollview(w) {
			scrollview_set_orig_xy(w)
		}
		for child in w.children {
			scrollview_widget_set_orig_xy(child)
		}
	} else if w is ListBox {
		if has_scrollview(w) {
			scrollview_set_orig_xy(w)
		}
	} else if w is TextBox {
		if has_scrollview(w) {
			scrollview_set_orig_xy(w)
		}
	}

	// TODO: DOES NOT WORK
	// if w is ScrollableWidget {
	// 	mut sw := w as ScrollableWidget
	// 	sw.set_orig_xy()
	// }
	// if w is Stack {
	// 	for child in w.children {
	// 		scrollview_widget_set_orig_xy(child)
	// 	}
	// } else if w is CanvasLayout {
	// 	for child in w.children {
	// 		scrollview_widget_set_orig_xy(child)
	// 	}
	// }
}

// pub fn (mut sw ScrollableWidget) set_orig_xy() {
// 	mut sv := sw.scrollview
// 	if sv != 0 {
// 		sv.orig_x, sv.orig_y = sw.x, sw.y
// 		sv.offset_x, sv.offset_y = 0, 0
// 		if sv.active_x {
// 			sv.change_value(.btn_x)
// 		}
// 		if sv.active_y {
// 			sv.change_value(.btn_y)
// 		}
// 	}
// }

pub fn scrollview_set_orig_xy<T>(w &T) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		// rest values
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

pub fn scrollview_widget_save_offset(w Widget) {
	if w is Stack {
		if has_scrollview(w) {
			scrollview_save_offset(w)
		}
		for child in w.children {
			scrollview_widget_save_offset(child)
		}
	} else if w is CanvasLayout {
		if has_scrollview(w) {
			scrollview_save_offset(w)
		}
		for child in w.children {
			scrollview_widget_save_offset(child)
		}
	} else if w is ListBox {
		if has_scrollview(w) {
			scrollview_save_offset(w)
		}
	} else if w is TextBox {
		if has_scrollview(w) {
			scrollview_save_offset(w)
		}
	}
}

pub fn scrollview_save_offset<T>(w &T) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		// Save prev values
		sv.prev_offset_x, sv.prev_offset_y = sv.offset_x, sv.offset_y
		// println("save offset: $sv.offset_x, $sv.offset_y")
	}
}

pub fn scrollview_widget_restore_offset(w Widget) {
	if w is Stack {
		if has_scrollview(w) {
			scrollview_restore_offset(w)
		}
		for child in w.children {
			scrollview_widget_restore_offset(child)
		}
	} else if w is CanvasLayout {
		if has_scrollview(w) {
			scrollview_restore_offset(w)
		}
		for child in w.children {
			scrollview_widget_restore_offset(child)
		}
	} else if w is ListBox {
		if has_scrollview(w) {
			scrollview_restore_offset(w)
		}
	} else if w is TextBox {
		if has_scrollview(w) {
			scrollview_restore_offset(w)
		}
	}
}

pub fn scrollview_restore_offset<T>(w &T) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		sv.orig_x, sv.orig_y = w.x, w.y
		// Load prev offset
		sv.offset_x, sv.offset_y = sv.prev_offset_x, sv.prev_offset_y
		// println("restore offset: $sv.offset_x, $sv.offset_y")
		sv.update_active()
		if sv.active_x {
			sv.change_value(.btn_x)
		}
		if sv.active_y {
			sv.change_value(.btn_y)
		}
		// println("restore2 offset: $sv.offset_x, $sv.offset_y")
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

pub fn scrollview_widget_update(w Widget) {
	if w is Stack {
		if has_scrollview(w) {
			scrollview_update(w)
		}
		for child in w.children {
			scrollview_widget_update(child)
		}
	}
}

pub fn scrollview_update_active<T>(w &T) {
	if has_scrollview(w) {
		mut sw := w.scrollview
		sw.update_active()
	}
}

pub fn scrollview_widget_update_active(w Widget) {
	if w is Stack {
		if has_scrollview(w) {
			scrollview_update_active(w)
		}
		for child in w.children {
			scrollview_widget_update_active(child)
		}
	}
}

pub fn scrollview_draw_begin<T>(mut w T, d DrawDevice) {
	if scrollview_is_active(w) {
		mut sv := w.scrollview
		if sv.children_to_update {
			svx, svy := sv.orig_xy()
			if sv.active_x {
				w.x = svx - sv.offset_x
			}
			if sv.active_y {
				w.y = svy - sv.offset_y
			}
			w.set_children_pos()
			sv.children_to_update = false
		}

		sv.clip(d)
	}
}

pub fn scrollview_draw_end<T>(w &T, d DrawDevice) {
	if has_scrollview(w) {
		sv := w.scrollview
		sv.draw_device(d)
	}
}

pub fn scrollview_reset<T>(mut w T) {
	mut sv := w.scrollview
	svx, svy := sv.orig_xy()
	if !sv.active_x {
		sv.offset_x = 0
		w.x = svx
	}
	if !sv.active_y {
		sv.offset_y = 0
		w.y = svy
	}
	w.set_children_pos()
}

pub fn lock_scrollview_key(w ScrollableWidget) {
	mut sv := w.scrollview
	sv.key_locked = true
}

pub fn unlock_scrollview_key(w ScrollableWidget) {
	mut sv := w.scrollview
	sv.key_locked = false
}

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
	orig_offset int
	// to update children pos
	children_to_update bool
	// focus
	is_focused bool
	key_locked bool
	// sizes of widget
	orig_x     int
	orig_y     int
	width      int
	height     int
	adj_width  int
	adj_height int
	win_width  int
	win_height int
	ui         &UI = unsafe { nil }
	// scissor
	scissor_rect gg.Rect
	parent       Layout
	// delta mouse
	delta_mouse int = 50
	// saved scrollview
	prev_offset_x int
	prev_offset_y int
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
		subscriber.subscribe_method(events.on_touch_move, scrollview_mouse_move, sv)
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
		subscriber.unsubscribe_method(events.on_touch_down, sv)
		subscriber.unsubscribe_method(events.on_touch_up, sv)
		subscriber.unsubscribe_method(events.on_touch_move, sv)
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
		if parent.scrollview != unsafe { nil } {
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
		if parent.scrollview != unsafe { nil } {
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

pub fn (sv &ScrollView) orig_xy() (int, int) {
	ox, oy := sv.parent_offset()
	return sv.orig_x - ox, sv.orig_y - oy
}

fn (sv &ScrollView) parent_scissor_rect() gg.Rect {
	parent := sv.parent
	size := gg.window_size() //_real_pixels()
	mut scissor_rect := gg.Rect{f32(0), f32(0), f32(size.width), f32(size.height)}
	if parent is Stack {
		if parent.scrollview != unsafe { nil } {
			psv := parent.scrollview
			scissor_rect = psv.scissor_rect
		}
	} else if parent is CanvasLayout {
		if parent.scrollview != unsafe { nil } {
			psv := parent.scrollview
			scissor_rect = psv.scissor_rect
		}
	}
	return scissor_rect
}

fn (mut sv ScrollView) update_active() {
	sv.active_x, sv.active_y = sv.adj_width > sv.width || sv.offset_x > 0,
		sv.adj_height > sv.height || sv.offset_y > 0
	// println("update_active: $sv.active_x, $sv.active_y = $sv.adj_width > $sv.width || $sv.offset_x > 0,
	// $sv.adj_height > $sv.height || $sv.offset_y > 0")
}

fn (mut sv ScrollView) update() {
	sv.width, sv.height = sv.widget.size()
	sv.adj_width, sv.adj_height = sv.widget.adj_size()
	sv.update_active()

	$if svu ? {
		println('scroll ${sv.widget.id}: (${sv.active_x} = ${sv.width} < ${sv.adj_width}, ${sv.active_y} = ${sv.height} < ${sv.adj_height})')
	}

	if sv.active_x {
		sv.sb_w = sv.width - ui.scrollbar_size
		sv.btn_w = if sv.width < sv.adj_width {
			int(f32(sv.width) / f32(sv.adj_width) * f32(sv.sb_w))
		} else {
			sv.sb_w
		}
	}
	if sv.active_y {
		sv.sb_h = sv.height - ui.scrollbar_size
		sv.btn_h = if sv.height < sv.adj_height {
			// println("update: sv.sb_h=$sv.sb_h sv.btn_h = int(${f32(sv.height)} / ${f32(sv.adj_height)} * ${f32(sv.sb_h)} = $sv.btn_h")
			int(f64(sv.height) / f64(sv.adj_height) * f64(sv.sb_h))
		} else {
			sv.sb_h
		}
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
	svx, svy := sv.orig_xy()
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
		.btn_x { // thanks to draw_rounded_fill_rect the size of the button is at least of width 2 * ui.scrollbar_size / 3 even if sv.btn_w is 0
			x_min, y_min = svx + sv.btn_x - ui.scrollbar_size / 3, svy + sv.height - ui.scrollbar_size
			x_max, y_max = x_min + sv.btn_w + 2 * ui.scrollbar_size / 3, y_min + ui.scrollbar_size
		}
		.btn_y { // thanks to draw_rounded_fill_rect the size of the button is at least of height 2 * ui.scrollbar_size / 3 even if sv.btn_h is 0
			x_min, y_min = svx + sv.width - ui.scrollbar_size, svy + sv.btn_y - ui.scrollbar_size / 3
			x_max, y_max = x_min + ui.scrollbar_size, y_min + sv.btn_h + 2 * ui.scrollbar_size / 3
		}
		.bar {
			return sv.point_inside(x, y, .bar_x) || sv.point_inside(x, y, .bar_y)
		}
	}
	// if mode == .view {
	// 	println("${sv.widget.id} $x >= $x_min && $x <= $x_max && $y >= $y_min && $y <= $y_max")
	// }
	return x >= x_min && x <= x_max && y >= y_min && y <= y_max
}

fn (mut sv ScrollView) change_value(mode ScrollViewPart) {
	sv.children_to_update = true
	if mode == .btn_x {
		if sv.offset_x < 0 {
			sv.offset_x = 0
		}
		max_offset_x, a_x := sv.coef_x()
		if sv.offset_x > max_offset_x && max_offset_x >= 0 {
			sv.offset_x = max_offset_x
		}
		sv.btn_x = int(f32(sv.offset_x) * a_x)
	} else if mode == .btn_y {
		if sv.offset_y < 0 {
			sv.offset_y = 0
		}
		max_offset_y, a_y := sv.coef_y()
		// println("change_value: sv.offset_y = $sv.offset_y max_offset_y = $max_offset_y")
		if sv.offset_y > max_offset_y && max_offset_y >= 0 {
			sv.offset_y = max_offset_y
		}
		// println("change_value2: sv.offset_y = $sv.offset_y")
		sv.btn_y = int(f32(sv.offset_y) * a_y)
	}
	// Special treatment for textbox
	mut sw := sv.widget
	if mut sw is TextBox {
		// println("textbox scroll changed")
		if sw.has_scrollview {
			sw.tv.scroll_changed()
		}
	}
	// User defined treatment for scrollable widget
	if sw.on_scroll_change != ScrollViewChangedFn(0) {
		sw.on_scroll_change(sw)
	}
}

pub fn (mut sv ScrollView) clip(d DrawDevice) {
	if sv.is_active() {
		svx, svy := sv.orig_xy()
		sr := gg.Rect{
			x: svx //* gg.dpi_scale()
			y: svy //* gg.dpi_scale()
			width: sv.width //* gg.dpi_scale()
			height: sv.height //* gg.dpi_scale()
		}
		psr := sv.parent_scissor_rect()
		scissor_rect := intersection_rect(sr, psr)
		d.scissor_rect(int(scissor_rect.x), int(scissor_rect.y), int(scissor_rect.width),
			int(scissor_rect.height))
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

pub fn (sv &ScrollView) draw_device(d DrawDevice) {
	scissor_rect := sv.parent_scissor_rect()
	d.scissor_rect(int(scissor_rect.x), int(scissor_rect.y), int(scissor_rect.width),
		int(scissor_rect.height))

	svx, svy := sv.orig_xy()

	if sv.active_x {
		// horizontal scrollbar
		d.draw_rounded_rect_filled(svx, svy + sv.height - ui.scrollbar_size, sv.sb_w,
			ui.scrollbar_size, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// horizontal button
		d.draw_rounded_rect_filled(svx + sv.btn_x, svy + sv.height - ui.scrollbar_size,
			sv.btn_w, ui.scrollbar_size, ui.scrollbar_size / 3, sv.btn_color_x)
	}
	if sv.active_y {
		// vertical scrollbar
		d.draw_rounded_rect_filled(svx + sv.width - ui.scrollbar_size, svy, ui.scrollbar_size,
			sv.sb_h, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// vertical button
		d.draw_rounded_rect_filled(svx + sv.width - ui.scrollbar_size, svy + sv.btn_y,
			ui.scrollbar_size, sv.btn_h, ui.scrollbar_size / 3, sv.btn_color_y)
	}
}

pub fn (mut sv ScrollView) set(val int, mode ScrollViewPart) {
	if sv.is_active() {
		if sv.active_x && mode == .btn_x {
			sv.offset_x = val
			sv.change_value(.btn_x)
		} else if sv.active_y && mode == .btn_y {
			sv.offset_y = val
			// println("set sv.offset_y = $val")
			sv.change_value(.btn_y)
		}
	}
}

pub fn (mut sv ScrollView) scroll_to_end_y() {
	max_offset_y, _ := sv.coef_y()
	sv.set(max_offset_y, .btn_y)
}

pub fn (mut sv ScrollView) inc(delta int, mode ScrollViewPart) {
	if sv.is_active() {
		if sv.active_x && mode == .btn_x {
			sv.offset_x += delta
			sv.change_value(.btn_x)
		} else if sv.active_y && mode == .btn_y {
			sv.offset_y += delta
			// println("sv.offset_y = $sv.offset_y")
			sv.change_value(.btn_y)
		}
	}
}

fn scrollview_scroll(mut sv ScrollView, e &ScrollEvent, zzz voidptr) {
	// println("sv srollview ${sv.point_inside(e.mouse_x, e.mouse_y, .view)}")
	if sv.is_active() && sv.point_inside(e.mouse_x, e.mouse_y, .view)
		&& !sv.children_point_inside(e.mouse_x, e.mouse_y, .view) {
		sw := sv.widget
		if sw is Widget {
			w := sw as Widget
			if sv.ui.window.is_top_widget(w, events.on_scroll) {
				if sv.active_x {
					sv.offset_x -= int(e.x * sv.delta_mouse)
					sv.change_value(.btn_x)
				}

				if sv.active_y {
					sv.offset_y -= int(e.y * sv.delta_mouse)
					// println("scroll sv.offset_y = $sv.offset_y")
					sv.change_value(.btn_y)
				}
			}
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
		sv.offset_x = int((e.x - sv.orig_x - sv.btn_w / 2) / a_x)
		sv.change_value(.btn_x)
	} else if sv.active_y && sv.point_inside(e.x, e.y, .bar_y) {
		sv.is_focused = true
		_, a_y := sv.coef_y()
		sv.offset_y = int((e.y - sv.orig_y - sv.btn_h / 2) / a_y)
		// println("$sv.offset_y = int(($e.y - $sv.orig_y - $sv.btn_h / 2) / $a_y)")
		sv.change_value(.btn_y)
	}
}

// fn scrollview_touch_move(mut sv ScrollView, e &MouseMoveEvent, zzz voidptr) {
// 	if !sv.is_active() {
// 		return
// 	}
// 	// TODO
// }

fn scrollview_mouse_down(mut sv ScrollView, e &MouseEvent, zzz voidptr) {
	if !sv.is_active() {
		return
	}
	if int(e.button) == 0 {
		if sv.active_x && sv.point_inside(e.x, e.y, .btn_x) {
			sv.dragging = 1 // x
			sv.drag_offset = e.x
			sv.orig_offset = sv.offset_x
		} else if sv.active_y && sv.point_inside(e.x, e.y, .btn_y) {
			sv.dragging = 2 // y
			sv.drag_offset = e.y
			sv.orig_offset = sv.offset_y
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
			sv.offset_x = sv.orig_offset + int(f32(e.x - sv.drag_offset) / a_x)
		} else {
			_, a_y := sv.coef_y()
			sv.offset_y = sv.orig_offset + int(f32(e.y - sv.drag_offset) / a_y)
			// println("move: $sv.offset_y = $sv.orig_offset + ($e.y - $sv.drag_offset) /  $a_y")
		}
		sv.change_value(unsafe { ScrollViewPart(sv.dragging) })
	}
}

// N.B.: deactivated for TextBox and ListBox
fn scrollview_key_down(mut sv ScrollView, e &KeyEvent, zzz voidptr) {
	if !sv.is_active() || !sv.is_focused || sv.key_locked {
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

pub fn (sv &ScrollView) coef_x() (int, f32) {
	max_offset_x := sv.adj_width - sv.width + 2 * ui.scrollbar_size
	return max_offset_x, f32(sv.sb_w - sv.btn_w) / f32(max_offset_x)
}

pub fn (sv &ScrollView) coef_y() (int, f32) {
	max_offset_y := (sv.adj_height - sv.height + 2 * ui.scrollbar_size)
	// println("coef_y: max_offset_y := ( (adj_h =$sv.adj_height) - (h=$sv.height) + 2 * (size=$ui.scrollbar_size))")
	return max_offset_y, f32(sv.sb_h - sv.btn_h) / f32(max_offset_y)
}
