module ui

import gx
import gg
import sokol.sgl

// ScrollView exists only when attached to Widget
// Is it not a widget but attached to a widget.
// A ScrollableWidget would have a field scrollview

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
		mut sw := w.scrollview
		sw.orig_x, sw.orig_y = w.x, w.y
		println('orig size: ($w.x, $w.y)')
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

const (
	scrollbar_size                     = 10
	scroolbar_thumb_color              = gx.rgb(87, 153, 245)
	scrollbar_background_color         = gx.rgb(219, 219, 219)
	scrollbar_button_color             = gx.rgb(100, 100, 100)
	scrollbar_focused_background_color = gx.rgb(255, 0, 0)
)

// type ScrollViewChangedFn = fn (arg_1 voidptr, arg_2 voidptr)

[heap]
pub struct ScrollView {
pub mut:
	widget ScrollableWidget
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

fn (sv &ScrollView) point_inside(x f64, y f64) bool {
	wx, wy := sv.orig_x + sv.widget.offset_x, sv.orig_y + sv.widget.offset_y
	// println("scrollview inside ($x, $y) ($wx + $sv.width, $wy + $sv.height)")
	return x >= wx && x <= wx + sv.width && y >= wy && y <= wy + sv.height
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
			sv.btn_w, ui.scrollbar_size, ui.scrollbar_size / 3, ui.scrollbar_button_color)
	}
	if sv.active_y {
		// vertical scrollbar
		sv.ui.gg.draw_rounded_rect(sv.orig_x + sv.width - ui.scrollbar_size, sv.orig_y,
			ui.scrollbar_size, sv.sb_h, ui.scrollbar_size / 3, ui.scrollbar_background_color)
		// vertical button
		sv.ui.gg.draw_rounded_rect(sv.orig_x + sv.width - ui.scrollbar_size, sv.orig_y + sv.btn_y,
			ui.scrollbar_size, sv.btn_h, ui.scrollbar_size / 3, ui.scrollbar_button_color)
	}
}

fn scrollview_scroll(mut sv ScrollView, e &ScrollEvent, zzz voidptr) {
	if sv.is_active() && sv.point_inside(e.mouse_x, e.mouse_y) {
		if sv.active_x {
			sv.offset_x += int(e.x * 3) * 3
			if sv.offset_x > 0 {
				sv.offset_x = 0
			}
			min_offset_x := -(sv.adj_width - sv.width + 2 * ui.scrollbar_size)
			if sv.offset_x < min_offset_x {
				sv.offset_x = min_offset_x
			}
			sv.btn_x = int(f32(sv.offset_x) * f32(sv.sb_w - sv.btn_w) / f32(min_offset_x))
		}

		if sv.active_y {
			sv.offset_y += int(e.y * 3) * 3
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
}

fn scrollview_key_down(mut s ScrollView, e &KeyEvent, zzz voidptr) {
	// if s.hidden {
	// 	return
	// }
	// if !s.is_focused {
	// 	return
	// }
	// match e.key {
	// 	.up, .left {
	// 		if !s.rev_min_max_pos {
	// 			if int(s.val) > s.min {
	// 				s.val--
	// 			}
	// 		} else {
	// 			if int(s.val) < s.max {
	// 				s.val++
	// 			}
	// 		}
	// 	}
	// 	.down, .right {
	// 		if !s.rev_min_max_pos {
	// 			if int(s.val) < s.max {
	// 				s.val++
	// 			}
	// 		} else {
	// 			if int(s.val) > s.min {
	// 				s.val--
	// 			}
	// 		}
	// 	}
	// 	else {}
	// }
	// if s.on_value_changed != voidptr(0) {
	// 	parent := s.parent
	// 	state := parent.get_state()
	// 	s.on_value_changed(state, s)
	// }
}

fn scrollview_click(mut s ScrollView, e &MouseEvent, zzz voidptr) {
	// if s.hidden {
	// 	return
	// }
	// if !s.point_inside_thumb(e.x, e.y) && (!s.point_inside(e.x, e.y) || s.focus_on_thumb_only) {
	// 	s.is_focused = false
	// 	return
	// }
	// if !s.focus_on_thumb_only {
	// 	s.change_value(e.x, e.y)
	// }
	// s.is_focused = true
}

fn scrollview_touch_move(mut s ScrollView, e &MouseMoveEvent, zzz voidptr) {
	// if s.hidden {
	// 	return
	// }
	// if s.entering && s.point_inside_thumb(e.x, e.y) {
	// 	// println('scrollview touch move DRAGGING')
	// 	s.dragging = true
	// }
	// if s.dragging {
	// 	s.change_value(int(e.x), int(e.y))
	// }
}

fn scrollview_mouse_down(mut s ScrollView, e &MouseEvent, zzz voidptr) {
	// if s.hidden {
	// 	return
	// }
	// // println('scrollview touchup  NO MORE DRAGGING')
	// if s.point_inside_thumb(e.x, e.y) {
	// 	// println('scrollview touch move DRAGGING')
	// 	s.dragging = true
	// }
}

fn scrollview_mouse_up(mut s ScrollView, e &MouseEvent, zzz voidptr) {
	// // println('scrollview touchup  NO MORE DRAGGING')
	// s.dragging = false
}

fn scrollview_mouse_move(mut s ScrollView, e &MouseMoveEvent, zzz voidptr) {
	// println("scrollview: $s.dragging ${e.mouse_button} ${int(e.mouse_button)}")
	// if int(e.mouse_button) == 0 {
	// 	// left: 0, right: 1, middle: 2
	// 	if s.entering && s.point_inside_thumb(e.x, e.y) {
	// 		// println("scrollview DRAGGING")
	// 		s.dragging = true
	// 	}
	// } else {
	// 	s.dragging = false
	// }
	// if s.dragging {
	// 	s.change_value(int(e.x), int(e.y))
	// }
}

/*
fn (s &ScrollView) draw_thumb() {
	axis := if s.orientation == .horizontal { s.x } else { s.y }
	rev_axis := if s.orientation == .horizontal { s.y } else { s.x }
	rev_dim := if s.orientation == .horizontal { s.height } else { s.width }
	rev_thumb_dim := if s.orientation == .horizontal { s.thumb_height } else { s.thumb_width }
	dim := if s.orientation == .horizontal { s.width } else { s.height }
	mut pos := f32(dim) * ((s.val - f32(s.min)) / f32(s.max - s.min))
	if s.rev_min_max_pos {
		pos = -pos + f32(dim)
	}
	pos += f32(axis)
	if pos > axis + dim {
		pos = f32(dim) + f32(axis)
	}
	if pos < axis {
		pos = f32(axis)
	}
	middle := f32(rev_axis) - (f32(rev_thumb_dim - rev_dim) / 2)
	if s.orientation == .horizontal {
		s.ui.gg.draw_rect(pos - f32(s.thumb_width) / 2, middle, s.thumb_width, s.thumb_height,
			ui.thumb_color)
	} else {
		s.ui.gg.draw_rect(middle, pos - f32(s.thumb_height) / 2, s.thumb_width, s.thumb_height,
			ui.thumb_color)
	}
}

fn (mut s ScrollView) set_pos(x int, y int) {
	s.x = x
	s.y = y
}

fn (mut s ScrollView) set_thumb_size() {
	if !s.thumb_in_track {
		s.thumb_height = if s.orientation == .horizontal { s.height + 10 } else { 10 }
		s.thumb_width = if s.orientation == .horizontal { 10 } else { s.width + 10 }
	} else {
		s.thumb_height = if s.orientation == .horizontal { s.height - 3 } else { 10 }
		s.thumb_width = if s.orientation == .horizontal { 10 } else { s.width - 3 }
	}
}

fn (mut s ScrollView) size() (int, int) {
	if s.orientation == .horizontal {
		return s.width, s.thumb_height
	} else {
		return s.thumb_width, s.height
	}
}

fn (mut s ScrollView) propose_size(w int, h int) (int, int) {
	// TODO: fix
	$if debug_scrollview ? {
		println('scrollview propose_size: ($s.width,$s.height) -> ($w, $h) | s.orientation: $s.orientation')
	}
	if s.orientation == .horizontal {
		s.width = w
	} else {
		s.height = h
	}
	s.set_thumb_size()
	return s.size()
}

fn (mut s ScrollView) draw() {
	offset_start(mut s)
	// Draw the track
	s.ui.gg.draw_rect(s.x, s.y, s.width, s.height, ui.scrollview_background_color)
	if s.track_line_displayed {
		if s.orientation == .horizontal {
			s.ui.gg.draw_line(s.x + 2, s.y + s.height / 2, s.x + s.width - 4, s.y + s.height / 2,
				gx.rgb(0, 0, 0))
		} else {
			s.ui.gg.draw_line(s.x + s.width / 2, s.y + 2, s.x + s.width / 2, s.y + s.height - 4,
				gx.rgb(0, 0, 0))
		}
	}
	if !s.is_focused {
		s.ui.gg.draw_empty_rect(s.x, s.y, s.width, s.height, ui.scrollview_background_border_color)
	} else {
		s.ui.gg.draw_empty_rect(s.x, s.y, s.width, s.height, ui.scrollview_focused_background_border_color)
	}
	// Draw the thumb
	s.draw_thumb()
	$if bb ? {
		draw_bb(s, s.ui)
	}
	offset_end(mut s)
}

fn scrollview_key_down(mut s ScrollView, e &KeyEvent, zzz voidptr) {
	if s.hidden {
		return
	}
	if !s.is_focused {
		return
	}
	match e.key {
		.up, .left {
			if !s.rev_min_max_pos {
				if int(s.val) > s.min {
					s.val--
				}
			} else {
				if int(s.val) < s.max {
					s.val++
				}
			}
		}
		.down, .right {
			if !s.rev_min_max_pos {
				if int(s.val) < s.max {
					s.val++
				}
			} else {
				if int(s.val) > s.min {
					s.val--
				}
			}
		}
		else {}
	}
	if s.on_value_changed != voidptr(0) {
		parent := s.parent
		state := parent.get_state()
		s.on_value_changed(state, s)
	}
}

fn (s &ScrollView) point_inside(x f64, y f64) bool {
	return point_inside<scrollview>(s, x, y) // x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height
}

fn scrollview_click(mut s ScrollView, e &MouseEvent, zzz voidptr) {
	if s.hidden {
		return
	}
	if !s.point_inside_thumb(e.x, e.y) && (!s.point_inside(e.x, e.y) || s.focus_on_thumb_only) {
		s.is_focused = false
		return
	}
	if !s.focus_on_thumb_only {
		s.change_value(e.x, e.y)
	}
	s.is_focused = true
}

fn scrollview_touch_move(mut s ScrollView, e &MouseMoveEvent, zzz voidptr) {
	if s.hidden {
		return
	}
	if s.entering && s.point_inside_thumb(e.x, e.y) {
		// println('scrollview touch move DRAGGING')
		s.dragging = true
	}
	if s.dragging {
		s.change_value(int(e.x), int(e.y))
	}
}

fn scrollview_mouse_down(mut s ScrollView, e &MouseEvent, zzz voidptr) {
	if s.hidden {
		return
	}
	// println('scrollview touchup  NO MORE DRAGGING')
	if s.point_inside_thumb(e.x, e.y) {
		// println('scrollview touch move DRAGGING')
		s.dragging = true
	}
}

fn scrollview_mouse_up(mut s ScrollView, e &MouseEvent, zzz voidptr) {
	// println('scrollview touchup  NO MORE DRAGGING')
	s.dragging = false
}

fn scrollview_mouse_move(mut s ScrollView, e &MouseMoveEvent, zzz voidptr) {
	// println("scrollview: $s.dragging ${e.mouse_button} ${int(e.mouse_button)}")
	if int(e.mouse_button) == 0 {
		// left: 0, right: 1, middle: 2
		if s.entering && s.point_inside_thumb(e.x, e.y) {
			// println("scrollview DRAGGING")
			s.dragging = true
		}
	} else {
		s.dragging = false
	}
	if s.dragging {
		s.change_value(int(e.x), int(e.y))
	}
}

fn (mut s ScrollView) change_value(x int, y int) {
	dim := if s.orientation == .horizontal { s.width } else { s.height }
	axis := if s.orientation == .horizontal { s.x } else { s.y }
	// TODO parser bug ` - axis`
	mut pos := if s.orientation == .horizontal { x } else { y }
	pos -= axis
	if s.rev_min_max_pos {
		pos = -pos + dim
	}
	s.val = f32(s.min) + (f32(pos) * f32(s.max - s.min)) / f32(dim)
	if int(s.val) < s.min {
		s.val = f32(s.min)
	} else if int(s.val) > s.max {
		s.val = f32(s.max)
	}
	if s.on_value_changed != voidptr(0) {
		parent := s.parent
		state := parent.get_state()
		s.on_value_changed(state, s)
	}
}

fn (mut s ScrollView) set_visible(state bool) {
	s.hidden = state
}

fn (mut s ScrollView) focus() {
	parent := s.parent
	parent.unfocus_all()
	s.is_focused = true
}

fn (s &ScrollView) is_focused() bool {
	return s.is_focused
}

fn (mut s ScrollView) unfocus() {
	s.is_focused = false
}

fn (s &ScrollView) point_inside_thumb(x f64, y f64) bool {
	sx, sy := s.x + s.offset_x, s.y + s.offset_y
	axis := if s.orientation == .horizontal { sx } else { sy }
	rev_axis := if s.orientation == .horizontal { sy } else { sx }
	rev_dim := if s.orientation == .horizontal { s.height } else { s.width }
	rev_thumb_dim := if s.orientation == .horizontal { s.thumb_height } else { s.thumb_width }
	dim := if s.orientation == .horizontal { s.width } else { s.height }
	mut pos := f32(dim) * ((s.val - f32(s.min)) / f32(s.max - s.min))
	if s.rev_min_max_pos {
		pos = -pos + f32(dim)
	}
	pos += f32(axis)
	if pos > axis + dim {
		pos = f32(dim) + f32(axis)
	}
	if pos < axis {
		pos = f32(axis)
	}
	middle := f32(rev_axis) - (f32(rev_thumb_dim - rev_dim) / 2)
	$if android {
		tol := 20.
		if s.orientation == .horizontal {
			t_x := pos - f32(s.thumb_width) / 2 - tol
			t_y := middle - tol
			return x >= t_x && x <= t_x + f32(s.thumb_width) + tol * 2 && y >= t_y
				&& y <= t_y + f32(s.thumb_height) + tol * 2
		} else {
			t_x := middle - tol
			t_y := pos - f32(s.thumb_height) / 2 - tol
			// println('scrollview inside: $x >= $t_x && $x <= ${t_x + f32(s.thumb_width)} && $y >= $t_y && $y <= ${
			// 	t_y + f32(s.thumb_height)}')
			return x >= t_x && x <= t_x + f32(s.thumb_width) + tol * 2 && y >= t_y
				&& y <= t_y + f32(s.thumb_height) + tol * 2
		}
	} $else {
		if s.orientation == .horizontal {
			t_x := pos - f32(s.thumb_width) / 2
			t_y := middle
			return x >= t_x && x <= t_x + f32(s.thumb_width) && y >= t_y
				&& y <= t_y + f32(s.thumb_height)
		} else {
			t_x := middle
			t_y := pos - f32(s.thumb_height) / 2
			// println("scrollview inside: $x >= $t_x && $x <= ${t_x + f32(s.thumb_width)} && $y >= $t_y && $y <= ${t_y + f32(s.thumb_height)}")
			return x >= t_x && x <= t_x + f32(s.thumb_width) && y >= t_y
				&& y <= t_y + f32(s.thumb_height)
		}
	}
}*/
