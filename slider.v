module ui

import gx

const (
	thumb_color                            = gx.rgb(87, 153, 245)
	slider_background_color                = gx.rgb(219, 219, 219)
	slider_background_border_color         = gx.rgb(191, 191, 191)
	slider_focused_background_border_color = gx.rgb(255, 0, 0)
)

type SliderValueChangedFn = fn (arg_1 voidptr, arg_2 voidptr)

pub enum Orientation {
	vertical = 0
	horizontal = 1
}

[heap]
pub struct Slider {
pub mut:
	id                   string
	height               int // track width
	width                int // track height
	thumb_width          int
	thumb_height         int
	orientation          Orientation = Orientation.horizontal
	x                    int
	y                    int
	offset_x             int
	offset_y             int
	z_index              int
	parent               Layout = empty_stack
	ui                   &UI
	val                  f32
	min                  int
	max                  int = 100
	is_focused           bool
	dragging             bool
	on_value_changed     SliderValueChangedFn
	focus_on_thumb_only  bool
	rev_min_max_pos      bool
	thumb_in_track       bool
	track_line_displayed bool
	entering             bool
	hidden               bool
	// component state for composable widget
	component voidptr
}

[params]
pub struct SliderParams {
	id                   string
	width                int
	height               int
	z_index              int
	min                  int
	max                  int
	val                  f32
	orientation          Orientation
	on_value_changed     SliderValueChangedFn
	focus_on_thumb_only  bool = true
	rev_min_max_pos      bool
	thumb_in_track       bool
	track_line_displayed bool = true
	entering             bool
}

pub fn slider(c SliderParams) &Slider {
	mut s := &Slider{
		id: c.id
		height: c.height
		width: c.width
		min: c.min
		max: c.max
		val: c.val
		orientation: c.orientation
		on_value_changed: c.on_value_changed
		focus_on_thumb_only: c.focus_on_thumb_only
		rev_min_max_pos: c.rev_min_max_pos
		thumb_in_track: c.thumb_in_track
		track_line_displayed: c.track_line_displayed
		ui: 0
		z_index: c.z_index
		entering: c.entering
	}
	s.set_thumb_size()
	// if !c.thumb_in_track {
	// 	s.thumb_height = if s.orientation == .horizontal { s.height + 10 } else { 10 }
	// 	s.thumb_width = if s.orientation == .horizontal { 10 } else { s.width + 10 }
	// } else {
	// 	s.thumb_height = if s.orientation == .horizontal { s.height - 3 } else { 10 }
	// 	s.thumb_width = if s.orientation == .horizontal { 10 } else { s.width - 3 }
	// }

	if s.min > s.max {
		tmp := s.max
		s.max = s.min
		s.min = tmp
	}
	return s
}

fn (mut s Slider) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	s.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, slider_click, s)
	subscriber.subscribe_method(events.on_key_down, slider_key_down, s)
	subscriber.subscribe_method(events.on_mouse_down, slider_mouse_down, s)
	subscriber.subscribe_method(events.on_mouse_up, slider_mouse_up, s)
	subscriber.subscribe_method(events.on_mouse_move, slider_mouse_move, s)
	s.ui.window.evt_mngr.add_receiver(s, [events.on_mouse_down])
	$if android {
		subscriber.subscribe_method(events.on_touch_down, slider_mouse_down, s)
		subscriber.subscribe_method(events.on_touch_up, slider_mouse_up, s)
		subscriber.subscribe_method(events.on_touch_move, slider_touch_move, s)
	}
}

[manualfree]
pub fn (mut s Slider) cleanup() {
	mut subscriber := s.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, s)
	subscriber.unsubscribe_method(events.on_key_down, s)
	subscriber.unsubscribe_method(events.on_mouse_down, s)
	subscriber.unsubscribe_method(events.on_mouse_up, s)
	subscriber.unsubscribe_method(events.on_mouse_move, s)
	$if android {
		subscriber.unsubscribe_method(events.on_touch_down, s)
		subscriber.unsubscribe_method(events.on_touch_up, s)
		subscriber.unsubscribe_method(events.on_touch_move, s)
	}
	s.ui.window.evt_mngr.rm_receiver(s, [events.on_mouse_down])
	unsafe { s.free() }
}

[unsafe]
pub fn (s &Slider) free() {
	$if free ? {
		print('slider $s.id')
	}
	unsafe {
		s.id.free()
		free(s)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (s &Slider) draw_thumb() {
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
		s.ui.gg.draw_rect_filled(pos - f32(s.thumb_width) / 2, middle, s.thumb_width,
			s.thumb_height, ui.thumb_color)
	} else {
		s.ui.gg.draw_rect_filled(middle, pos - f32(s.thumb_height) / 2, s.thumb_width,
			s.thumb_height, ui.thumb_color)
	}
}

pub fn (mut s Slider) set_pos(x int, y int) {
	s.x = x
	s.y = y
}

fn (mut s Slider) set_thumb_size() {
	if !s.thumb_in_track {
		s.thumb_height = if s.orientation == .horizontal { s.height + 10 } else { 10 }
		s.thumb_width = if s.orientation == .horizontal { 10 } else { s.width + 10 }
	} else {
		s.thumb_height = if s.orientation == .horizontal { s.height - 3 } else { 10 }
		s.thumb_width = if s.orientation == .horizontal { 10 } else { s.width - 3 }
	}
}

pub fn (mut s Slider) size() (int, int) {
	// if s.orientation == .horizontal {
	// 	return s.width, s.thumb_height
	// } else {
	// 	return s.thumb_width, s.height
	// }
	return s.width, s.height
}

pub fn (mut s Slider) propose_size(w int, h int) (int, int) {
	// TODO: fix
	$if debug_slider ? {
		println('slider propose_size: ($s.width,$s.height) -> ($w, $h) | s.orientation: $s.orientation')
	}
	// if s.orientation == .horizontal {
	s.width = w
	// } else {
	s.height = h
	// }
	s.set_thumb_size()
	return s.size()
}

fn (mut s Slider) draw() {
	offset_start(mut s)
	// Draw the track
	s.ui.gg.draw_rect_filled(s.x, s.y, s.width, s.height, ui.slider_background_color)
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
		s.ui.gg.draw_rect_empty(s.x, s.y, s.width, s.height, ui.slider_background_border_color)
	} else {
		s.ui.gg.draw_rect_empty(s.x, s.y, s.width, s.height, ui.slider_focused_background_border_color)
	}
	// Draw the thumb
	s.draw_thumb()
	$if bb ? {
		draw_bb(mut s, s.ui)
	}
	offset_end(mut s)
}

fn slider_key_down(mut s Slider, e &KeyEvent, zzz voidptr) {
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

fn (s &Slider) point_inside(x f64, y f64) bool {
	return point_inside(s, x, y)
}

fn slider_click(mut s Slider, e &MouseEvent, zzz voidptr) {
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

fn slider_mouse_down(mut s Slider, e &MouseEvent, zzz voidptr) {
	if s.hidden {
		return
	}
	// println('slider touchup  NO MORE DRAGGING')
	if int(e.button) == 0 && s.point_inside_thumb(e.x, e.y) {
		// println('slider touch move DRAGGING ${e.button}')
		s.dragging = true
	}
}

fn slider_mouse_up(mut s Slider, e &MouseEvent, zzz voidptr) {
	// println('slider touchup  NO MORE DRAGGING')
	s.dragging = false
}

fn slider_mouse_move(mut s Slider, e &MouseMoveEvent, zzz voidptr) {
	// println("slider: $s.dragging ${e.mouse_button} ${int(e.mouse_button)}")
	if s.ui.btn_down[0] { // int(e.mouse_button) == 0 {
		// left: 0, right: 1, middle: 2
		if s.entering && s.point_inside_thumb(e.x, e.y) {
			// println("slider DRAGGING")
			s.dragging = true
		}
	} else {
		s.dragging = false
	}
	if s.dragging {
		s.change_value(int(e.x), int(e.y))
	}
}

fn slider_touch_move(mut s Slider, e &MouseMoveEvent, zzz voidptr) {
	if s.hidden {
		return
	}
	if s.entering && s.point_inside_thumb(e.x, e.y) {
		// println('slider touch move DRAGGING')
		s.dragging = true
	}
	if s.dragging {
		s.change_value(int(e.x), int(e.y))
	}
}

fn (mut s Slider) change_value(x int, y int) {
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

fn (mut s Slider) set_visible(state bool) {
	s.hidden = !state
}

fn (mut s Slider) focus() {
	mut f := Focusable(s)
	f.set_focus()
}

fn (mut s Slider) unfocus() {
	s.is_focused = false
}

fn (s &Slider) point_inside_thumb(x f64, y f64) bool {
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
		tol := 20.0
		if s.orientation == .horizontal {
			t_x := pos - f32(s.thumb_width) / 2 - tol
			t_y := middle - tol
			return x >= t_x && x <= t_x + f32(s.thumb_width) + tol * 2 && y >= t_y
				&& y <= t_y + f32(s.thumb_height) + tol * 2
		} else {
			t_x := middle - tol
			t_y := pos - f32(s.thumb_height) / 2 - tol
			// println('slider inside: $x >= $t_x && $x <= ${t_x + f32(s.thumb_width)} && $y >= $t_y && $y <= ${
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
			// println("slider inside: $x >= $t_x && $x <= ${t_x + f32(s.thumb_width)} && $y >= $t_y && $y <= ${t_y + f32(s.thumb_height)}")
			return x >= t_x && x <= t_x + f32(s.thumb_width) && y >= t_y
				&& y <= t_y + f32(s.thumb_height)
		}
	}
}
