module ui

import gx
import math { max }

// ScrollView exists only when attached to Widget
// Is it not a widget but attached to a widget.
// A ScrollableWidget would have a field scrollview

pub const scrollbar_size = 10
pub const scrollbar_thumb_size = 16
pub const scroolbar_thumb_color = gx.rgb(87, 153, 245)
pub const scrollbar_background_color = gx.rgb(219, 219, 219)
pub const scrollbar_button_color = gx.rgb(150, 150, 150)
pub const scrollbar_focused_button_color = gx.rgb(100, 100, 100)
pub const scrollview_delta_key = 5
// scrollview_delta_mouse         = 10
pub const null_scrollview = &ScrollView(unsafe { nil })

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

pub interface ScrollableWidget {
	ClippingWidget
mut:
	has_scrollview   bool
	scrollview       &ScrollView
	id               string
	ui               &UI
	offset_x         int
	offset_y         int
	on_scroll_change ScrollViewChangedFn
	adj_size() (int, int)
	size() (int, int)
}

// TODO: documentation
pub fn get_scrollview(sw ScrollableWidget) (bool, &ScrollView) {
	has := sw.has_scrollview
	return has, if has {
		sw.scrollview
	} else {
		&ScrollView(unsafe { nil })
	}
}

// TODO: documentation
pub fn has_scrollview(w ScrollableWidget) bool {
	return w.has_scrollview
}

// TODO: documentation
pub fn has_scrollview_or_parent_scrollview(w ScrollableWidget) bool {
	return unsafe { w.scrollview != 0 }
}

// TODO: documentation
pub fn scrollview_is_active(w ScrollableWidget) bool {
	return w.has_scrollview && w.scrollview.is_active()
}

// TODO: documentation
pub fn scrollview_need_update(mut w ScrollableWidget) {
	if w.has_scrollview {
		w.scrollview.children_to_update = true
	}
}

// TODO: documentation
pub fn scrollview_add[T](mut w T) {
	mut sv := &ScrollView{
		parent: w.parent
		widget: unsafe { w }
		ui:     unsafe { nil }
	}
	// IMPORTANT (sort of bug):
	// declaring `widget: w` inside struct before work for stack but not for canvas_layout
	sv.widget = unsafe { w }
	// TEST for the bug above
	// mut w2 := sv.widget
	// wi, he := w2.size()
	// println("add: ($wi, $he) -> ($w.width, $w.height)")
	w.scrollview = sv
	w.has_scrollview = true
	w.clipping = true
}

// TODO: documentation
pub fn scrollview_widget_set_orig_xy(w Widget, reset_offset bool) {
	if w is Stack {
		scrollview_set_orig_xy(w, reset_offset)
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	} else if w is CanvasLayout {
		scrollview_set_orig_xy(w, reset_offset)
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	} else if w is ListBox {
		scrollview_set_orig_xy(w, reset_offset)
	} else if w is ChunkView {
		scrollview_set_orig_xy(w, reset_offset)
	} else if w is TextBox {
		scrollview_set_orig_xy(w, reset_offset)
	} else if w is Group {
		// if has_scrollview(w) {
		// 	scrollview_set_orig_xy(w)
		// }
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	} else if w is BoxLayout {
		scrollview_set_orig_xy(w, reset_offset)
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
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

// TODO: documentation
pub fn scrollview_set_children_orig_xy(w Widget, reset_offset bool) {
	if w is Stack {
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	} else if w is CanvasLayout {
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	} else if w is Group {
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	} else if w is BoxLayout {
		for child in w.children {
			scrollview_widget_set_orig_xy(child, reset_offset)
		}
	}
}

fn has_parent_scrolling(w Widget) bool {
	pw := w.parent
	if pw is ScrollableWidget {
		if has_scrollview(pw) {
			psw := pw as ScrollableWidget
			return psw.scrollview.children_to_update
		}
	}
	return false
}

// TODO: documentation
pub fn scrollview_set_orig_xy(w &ScrollableWidget, reset_offset bool) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		// rest values
		sv.orig_x, sv.orig_y = w.x, w.y
		if reset_offset {
			sv.offset_x, sv.offset_y = 0, 0
		}
		if sv.active_x {
			// if reset_offset {
			// 	sv.offset_x = 0
			// }
			sv.change_value(.btn_x)
		}
		if sv.active_y {
			// if reset_offset {
			// 	sv.orig_y = 0
			// }
			sv.change_value(.btn_y)
		}
		// println('set orig size $.id: ($w.x, $w.y)')
	}
}

// TODO: documentation
pub fn scrollview_widget_save_offset(w Widget) {
	if w is Stack {
		scrollview_save_offset(w)
		for child in w.children {
			scrollview_widget_save_offset(child)
		}
	} else if w is CanvasLayout {
		scrollview_save_offset(w)
		for child in w.children {
			scrollview_widget_save_offset(child)
		}
	} else if w is ListBox {
		scrollview_save_offset(w)
	} else if w is TextBox {
		scrollview_save_offset(w)
	}
}

// TODO: documentation
pub fn scrollview_save_offset(w &ScrollableWidget) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		// Save prev values
		sv.prev_offset_x, sv.prev_offset_y = sv.offset_x, sv.offset_y
		// println("save offset: $sv.offset_x, $sv.offset_y")
	}
}

// TODO: documentation
pub fn scrollview_widget_restore_offset(w Widget, orig bool) {
	if w is Stack {
		scrollview_restore_offset(w, orig)
		for child in w.children {
			scrollview_widget_restore_offset(child, orig)
		}
	} else if w is CanvasLayout {
		scrollview_restore_offset(w, orig)
		for child in w.children {
			scrollview_widget_restore_offset(child, orig)
		}
	} else if w is ListBox {
		scrollview_restore_offset(w, orig)
	} else if w is TextBox {
		scrollview_restore_offset(w, orig)
	}
}

// TODO: documentation
pub fn scrollview_restore_offset(w &ScrollableWidget, orig bool) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		sv.update_active()
		if sv.active_x {
			if !has_parent_scrolling(sv.widget) {
				sv.orig_x = w.x
			}
			sv.offset_x = sv.prev_offset_x
			sv.change_value(.btn_x)
		}
		if sv.active_y {
			if !has_parent_scrolling(sv.widget) {
				// println('restore offset ${sv.widget.id}')
				sv.orig_y = w.y
			}
			sv.offset_y = sv.prev_offset_y
			sv.change_value(.btn_y)
		}
		// println("restore2 offset: $sv.offset_x, $sv.offset_y")
	}
}

// TODO: documentation
pub fn scrollview_delegate_parent_scrollview(mut w Widget) {
	parent := w.parent
	if parent is Stack && mut w is ScrollableWidget {
		w.scrollview = parent.scrollview
	} else if parent is CanvasLayout && mut w is ScrollableWidget {
		w.scrollview = parent.scrollview
	}
}

// TODO: documentation
pub fn scrollview_update(w &ScrollableWidget) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		sv.update()
	}
}

// TODO: documentation
pub fn scrollview_widget_update(w Widget) {
	if w is Stack {
		scrollview_update(w)
		for child in w.children {
			scrollview_widget_update(child)
		}
	}
}

// TODO: documentation
pub fn scrollview_update_active(w &ScrollableWidget) {
	if has_scrollview(w) {
		mut sv := w.scrollview
		sv.update_active()
	}
}

// TODO: documentation
pub fn scrollview_widget_update_active(w Widget) {
	if w is Stack {
		scrollview_update_active(w)
		for child in w.children {
			scrollview_widget_update_active(child)
		}
	}
}

// TODO: documentation
pub fn scrollview_draw_begin[T](mut w T, d DrawDevice) {
	if scrollview_is_active(w) {
		mut sv := w.scrollview
		if sv.children_to_update {
			$if ui_clipping ? {
				println('sv: ${sv.widget.id} update children')
			}
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
	}
}

// TODO: documentation
pub fn scrollview_draw_end(w &ScrollableWidget, d DrawDevice) {
	if has_scrollview(w) {
		sv := w.scrollview
		sv.draw_device(d)
	}
}

// TODO: documentation
pub fn scrollview_reset[T](mut w T) {
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

// TODO: documentation
pub fn lock_scrollview_key(w ScrollableWidget) {
	mut sv := w.scrollview
	sv.key_locked = true
}

// TODO: documentation
pub fn unlock_scrollview_key(w ScrollableWidget) {
	mut sv := w.scrollview
	sv.key_locked = false
}

@[heap]
pub struct ScrollView {
pub mut:
	widget &Widget = unsafe { nil }
	// color
	btn_color_x gx.Color = scrollbar_button_color
	btn_color_y gx.Color = scrollbar_button_color
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
	// win_width  int
	// win_height int
	ui     &UI = unsafe { nil }
	parent Layout
	// delta mouse
	delta_mouse int = 50
	// saved scrollview
	prev_offset_x int
	prev_offset_y int
}

fn (mut sv ScrollView) init(parent Layout) {
	mut widget := sv.widget
	u := widget.ui // get_ui()
	sv.ui = u
	sv.parent = parent

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

// TODO: documentation
@[manualfree]
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

// TODO: documentation
@[unsafe]
pub fn (sv &ScrollView) free() {
	unsafe { free(sv) }
}

fn (sv &ScrollView) parent_offset() (int, int) {
	parent := sv.parent
	if parent is ScrollableWidget {
		if parent.scrollview != unsafe { nil } {
			psv := parent.scrollview
			mut ox, mut oy := psv.parent_offset()
			if psv.active_x {
				ox += psv.offset_x
			}
			if psv.active_y {
				oy += psv.offset_y
			}
			return ox, oy
		}
	}
	return 0, 0
}

// From a ScrollableWidget's ScrollView, fetch the "original" (x,y) co-ordinates
// for the widget, prior to them being adjusted due to scrolling. (Note:
// although they're called "original" co-ordinates, they will also reflect any
// scrolling offsets that have occurred in parent ScrollViews -- which is
// usually what you want -- and so should technically be thought of as the (x,y)
// co-ordinates of this widget where no scrolling has occurred in this widget.)
pub fn (sv &ScrollView) orig_xy() (int, int) {
	ox, oy := sv.parent_offset()
	return sv.orig_x - ox, sv.orig_y - oy
}

fn (mut sv ScrollView) update_active() {
	sv.active_x, sv.active_y = sv.adj_width > sv.width || sv.offset_x > 0,
		sv.adj_height > sv.height || sv.offset_y > 0
	// println("update_active: $sv.active_x, $sv.active_y = $sv.adj_width > $sv.width || $sv.offset_x > 0,
	// $sv.adj_height > $sv.height || $sv.offset_y > 0")
}

fn (mut sv ScrollView) update() {
	mut sw := sv.widget as ScrollableWidget
	sv.width, sv.height = sw.size()
	sv.adj_width, sv.adj_height = sw.adj_size()
	sv.update_active()

	$if svu ? {
		println('scroll ${sv.widget.id}: (${sv.active_x} = ${sv.width} < ${sv.adj_width}, ${sv.active_y} = ${sv.height} < ${sv.adj_height})')
	}

	if sv.active_x {
		sv.sb_w = sv.width - scrollbar_size
		sv.btn_w = if sv.width < sv.adj_width {
			max(int(f32(sv.width) / f32(sv.adj_width) * f32(sv.sb_w)), scrollbar_thumb_size)
		} else {
			sv.sb_w
		}
	}
	if sv.active_y {
		sv.sb_h = sv.height - scrollbar_size
		sv.btn_h = if sv.height < sv.adj_height {
			// println("update: sv.sb_h=$sv.sb_h sv.btn_h = int(${f32(sv.height)} / ${f32(sv.adj_height)} * ${f32(sv.sb_h)} = $sv.btn_h")
			max(int(f64(sv.height) / f64(sv.adj_height) * f64(sv.sb_h)), scrollbar_thumb_size)
		} else {
			sv.sb_h
		}
	}
}

// TODO: documentation
pub fn (sv &ScrollView) is_active() bool {
	return sv.active_x || sv.active_y
}

fn has_child_with_active_scrollview(w Widget, x f64, y f64) bool {
	ww := w
	if w is Layout {
		xx, yy := x - ww.offset_x, y - ww.offset_y
		for child in w.get_children() {
			if child is ScrollableWidget {
				if scrollview_is_active(child) && scrollview_widget_point_inside(child, x, y) {
					$if ui_scroll_nest ? { // see examples/nested_scrollview.v
						println('...found active child scrollview: ${child.id}')
					}
					return true
				}
			}
			if has_child_with_active_scrollview(child, xx, yy) {
				return true
			}
		}
	}
	return false
}

fn scrollview_widget_point_inside(w ScrollableWidget, x f64, y f64) bool {
	xx, yy := if has_scrollview(w) { w.scrollview.orig_xy() } else { w.x, w.y }
	wx, wy := xx + w.offset_x, yy + w.offset_y
	// REMOVED: This doesn't work for textboxes where the text does not fill the
	// width of the box. So, scroll events AWAY from the text (but inside the
	// Textbox) are ignored.
	// if has_scrollview(w) {
	//    if w.id == 'b11' {
	//        println("ww ${ww}, w.sv.adj_w ${w.scrollview.adj_width}")
	//    }
	//    ww = math.min(ww, w.scrollview.adj_width)
	//    hh = math.min(hh, w.scrollview.adj_height)
	//}
	return x >= wx && x <= wx + w.width && y >= wy && y <= wy + w.height
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
			x_min, y_min = svx, svy + sv.height - scrollbar_size
			x_max, y_max = x_min + sv.sb_w, y_min + scrollbar_size
		}
		.bar_y {
			x_min, y_min = svx + sv.width - scrollbar_size, svy
			x_max, y_max = x_min + scrollbar_size, y_min + sv.sb_h
		}
		.btn_x {
			// thanks to draw_rounded_rect_filled() the width of the button is
			// at least 2 * ui.scrollbar_size / 3 even if sv.btn_w is 0
			x_min, y_min = svx + sv.btn_x - scrollbar_size / 3, svy + sv.height - scrollbar_size
			x_max, y_max = x_min + sv.btn_w + 2 * scrollbar_size / 3, y_min + scrollbar_size
		}
		.btn_y {
			// thanks to draw_rounded_rect_filled() the height of the button is
			// at least 2 * ui.scrollbar_size / 3 even if sv.btn_h is 0
			x_min, y_min = svx + sv.width - scrollbar_size, svy + sv.btn_y - scrollbar_size / 3
			x_max, y_max = x_min + scrollbar_size, y_min + sv.btn_h + 2 * scrollbar_size / 3
		}
		.bar {
			return sv.point_inside(x, y, .bar_x) || sv.point_inside(x, y, .bar_y)
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
		max_offset_x, a_x := sv.x_offset_max_and_coef()
		if sv.offset_x > max_offset_x && max_offset_x >= 0 {
			sv.offset_x = max_offset_x
		}
		sv.btn_x = int(f32(sv.offset_x) * a_x)
	} else if mode == .btn_y {
		if sv.offset_y < 0 {
			sv.offset_y = 0
		}
		max_offset_y, a_y := sv.y_offset_max_and_coef()
		// println("change_value: sv.offset_y = $sv.offset_y max_offset_y = $max_offset_y")
		if sv.offset_y > max_offset_y && max_offset_y >= 0 {
			sv.offset_y = max_offset_y
		}
		// println("change_value2: sv.offset_y = $sv.offset_y")
		sv.btn_y = int(f32(sv.offset_y) * a_y)
	}
	// Special treatment for textbox
	mut sw := sv.widget as ScrollableWidget
	if mut sw is TextBox {
		// println("textbox $sw.id scroll changed")
		if sw.has_scrollview {
			sw.tv.scroll_changed()
		}
	}
	// User defined treatment for scrollable widget
	if sw.on_scroll_change != unsafe { ScrollViewChangedFn(0) } {
		sw.on_scroll_change(sw)
	}
}

// TODO: documentation
pub fn (sv &ScrollView) draw_device(d DrawDevice) {
	svx, svy := sv.orig_xy()

	if sv.active_x {
		// horizontal scrollbar
		d.draw_rounded_rect_filled(svx, svy + sv.height - scrollbar_size, sv.sb_w, scrollbar_size,
			scrollbar_size / 3, scrollbar_background_color)
		// horizontal button
		d.draw_rounded_rect_filled(svx + sv.btn_x, svy + sv.height - scrollbar_size, sv.btn_w,
			scrollbar_size, scrollbar_size / 3, sv.btn_color_x)
	}
	if sv.active_y {
		$if sv_draw ? {
			println('sv_draw ${sv.widget.id} -> ${svx} + ${sv.width} - ${scrollbar_size}, ${svy}, ${scrollbar_size}, ${sv.sb_h}')
		}
		// vertical scrollbar
		d.draw_rounded_rect_filled(svx + sv.width - scrollbar_size, svy, scrollbar_size,
			sv.sb_h, scrollbar_size / 3, scrollbar_background_color)
		// vertical button
		d.draw_rounded_rect_filled(svx + sv.width - scrollbar_size, svy + sv.btn_y, scrollbar_size,
			sv.btn_h, scrollbar_size / 3, sv.btn_color_y)
	}
}

// TODO: documentation
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

// TODO: documentation
pub fn (mut sv ScrollView) scroll_to_end_y() {
	max_offset_y, _ := sv.y_offset_max_and_coef()
	sv.set(max_offset_y, .btn_y)
}

// TODO: documentation
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

fn scrollview_scroll(mut sv ScrollView, e &ScrollEvent, _ voidptr) {
	$if ui_scroll_nest ? { // see examples/nested_scrollview.v
		println('checking scrollview: ${sv.widget.id}')
	}
	if sv.is_active() && sv.point_inside(e.mouse_x, e.mouse_y, .view)
		&& !has_child_with_active_scrollview(sv.widget, e.mouse_x, e.mouse_y) {
		sw := sv.widget
		if sw is Widget {
			w := sw as Widget
			if sv.ui.window.is_top_widget(w, events.on_scroll) {
				// println('scroll ${w.id}')
				if sv.active_x {
					sv.offset_x -= int(e.x * sv.delta_mouse)
					sv.change_value(.btn_x)
				}
				if sv.active_y {
					sv.offset_y -= int(e.y * sv.delta_mouse)
					// println("scroll $sw.id sv.offset_y = $sv.offset_y")
					sv.change_value(.btn_y)
				}
			}
		}
	}
}

fn scrollview_click(mut sv ScrollView, e &MouseEvent, _ voidptr) {
	if !sv.is_active() {
		return
	}
	$if ui_scroll_nest ? { // see examples/nested_scrollview.v
		println('checking scrollview: ${sv.widget.id}')
	}
	sv.is_focused = sv.point_inside(e.x, e.y, .view)
		&& !has_child_with_active_scrollview(sv.widget, e.x, e.y)
	if sv.active_x && sv.point_inside(e.x, e.y, .bar_x) {
		sv.is_focused = true
		println('svc x ${sv.widget.id}')
		_, a_x := sv.x_offset_max_and_coef()
		svx, _ := sv.orig_xy()
		sv.offset_x = int((e.x - svx - sv.btn_w / 2) / a_x)
		sv.change_value(.btn_x)
	} else if sv.active_y && sv.point_inside(e.x, e.y, .bar_y) {
		sv.is_focused = true
		println('svc y ${sv.widget.id}')
		_, a_y := sv.y_offset_max_and_coef()
		_, svy := sv.orig_xy()
		sv.offset_y = int((e.y - svy - sv.btn_h / 2) / a_y)
		// println("$sv.offset_y = int(($e.y - $sv.orig_y - $sv.btn_h / 2) / $a_y)")
		sv.change_value(.btn_y)
	}
}

// fn scrollview_touch_move(mut sv ScrollView, e &MouseMoveEvent, _ voidptr) {
// 	if !sv.is_active() {
// 		return
// 	}
// 	// TODO
// }

fn scrollview_mouse_down(mut sv ScrollView, e &MouseEvent, _ voidptr) {
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

fn scrollview_mouse_up(mut sv ScrollView, e &MouseEvent, _ voidptr) {
	if !sv.is_active() {
		return
	}
	sv.dragging = 0 // invalid neither x nor y
	sv.drag_offset = 0
}

fn scrollview_mouse_move(mut sv ScrollView, e &MouseMoveEvent, _ voidptr) {
	if !sv.is_active() {
		return
	}
	sv.btn_color_x = if sv.point_inside(e.x, e.y, .btn_x) {
		scrollbar_focused_button_color
	} else {
		scrollbar_button_color
	}
	sv.btn_color_y = if sv.point_inside(e.x, e.y, .btn_y) {
		scrollbar_focused_button_color
	} else {
		scrollbar_button_color
	}
	if !sv.ui.btn_down[0] {
		sv.dragging = 0 // invalid neither x nor y
	} else if sv.dragging > 0 {
		if sv.dragging == 1 {
			_, a_x := sv.x_offset_max_and_coef()
			sv.offset_x = sv.orig_offset + int(f32(e.x - sv.drag_offset) / a_x)
		} else {
			_, a_y := sv.y_offset_max_and_coef()
			sv.offset_y = sv.orig_offset + int(f32(e.y - sv.drag_offset) / a_y)
			// println("move: $sv.offset_y = $sv.orig_offset + ($e.y - $sv.drag_offset) /  $a_y")
		}
		sv.change_value(unsafe { ScrollViewPart(sv.dragging) })
	}
}

// N.B.: deactivated for TextBox and ListBox
fn scrollview_key_down(mut sv ScrollView, e &KeyEvent, _ voidptr) {
	if !sv.is_active() || !sv.is_focused || sv.key_locked {
		return
	}
	match e.key {
		.up {
			if sv.active_y {
				sv.offset_y -= scrollview_delta_key
				sv.change_value(.btn_y)
			}
		}
		.down {
			if sv.active_y {
				sv.offset_y += scrollview_delta_key
				sv.change_value(.btn_y)
			}
		}
		.left {
			if sv.active_x {
				sv.offset_x -= scrollview_delta_key
				sv.change_value(.btn_x)
			}
		}
		.right {
			if sv.active_x {
				sv.offset_x += scrollview_delta_key
				sv.change_value(.btn_x)
			}
		}
		else {}
	}
}

// returns max scroll offset (in scrollview pixels), and scrollview-to-scrollbar
// coefficient (i.e., multiplying a number of pixels in the view by this gives
// you the smaller, fractional number of pixels in the scrollbar which is the
// scrollbar button offset)
fn (sv &ScrollView) x_offset_max_and_coef() (int, f32) {
	max_offset_x := sv.adj_width - sv.width + 2 * scrollbar_size
	return max_offset_x, f32(sv.sb_w - sv.btn_w) / f32(max_offset_x)
}

fn (sv &ScrollView) y_offset_max_and_coef() (int, f32) {
	max_offset_y := (sv.adj_height - sv.height + 2 * scrollbar_size)
	// println("y_offset_max_and_coef: max_offset_y := ( (adj_h =$sv.adj_height) - (h=$sv.height) + 2 * (size=$ui.scrollbar_size))")
	return max_offset_y, f32(sv.sb_h - sv.btn_h) / f32(max_offset_y)
}
