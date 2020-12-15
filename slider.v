module ui

import gx
import math

const (
	thumb_color                            = gx.rgb(87, 153, 245)
	thumb_border_color                     = gx.rgb(80, 139, 222)
	slider_background_color                = gx.rgb(219, 219, 219)
	slider_background_border_color         = gx.rgb(191, 191, 191)
	slider_focused_background_border_color = gx.rgb(180, 180, 180)
)

type SliderValueChangedFn = fn (arg_1 voidptr, arg_2 voidptr)

pub enum Orientation {
	vertical = 0
	horizontal = 1
}

[ref_only]
pub struct Slider {
pub mut:
	track_height         int
	track_width          int
	thumb_size           int
	orientation          Orientation = Orientation.horizontal
	x                    int
	y                    int
	parent               Layout
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
}

pub struct SliderConfig {
	length               int
	min                  int
	max                  int
	val                  f32
	orientation          Orientation
	on_value_changed     SliderValueChangedFn
	focus_on_thumb_only  bool = true
	rev_min_max_pos      bool
	thumb_in_track       bool
}

fn (mut s Slider) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	s.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_mouse_down, slider_mouse_button, s)
	subscriber.subscribe_method(events.on_mouse_up, slider_mouse_button, s)
	subscriber.subscribe_method(events.on_key_down, slider_key_down, s)
	subscriber.subscribe_method(events.on_mouse_move, slider_mouse_move, s)
}

pub fn slider(c SliderConfig) &Slider {
	mut s := &Slider{
		track_height: if c.orientation == .horizontal { 7 } else { c.length }
		track_width: if c.orientation == .vertical { 7 } else { c.length }
		min: c.min
		max: c.max
		val: c.val
		orientation: c.orientation
		on_value_changed: c.on_value_changed
		focus_on_thumb_only: c.focus_on_thumb_only
		rev_min_max_pos: c.rev_min_max_pos
		thumb_in_track: c.thumb_in_track
		ui: 0
	}

	s.thumb_size = 6

	if s.min > s.max {
		tmp := s.max
		s.max = s.min
		s.min = tmp
	}
	return s
}

fn (s &Slider) draw_thumb() {
	axis := if s.orientation == .horizontal { s.x } else { s.y }
	dim := if s.orientation == .horizontal { s.track_width } else { s.track_height }
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
	if s.orientation == .horizontal {
		s.ui.gg.draw_circle_with_segments(pos, s.y + 3, s.thumb_size, 16, thumb_border_color)
		s.ui.gg.draw_circle_with_segments(pos, s.y + 3, s.thumb_size-1, 16, thumb_color)
	} else {
		s.ui.gg.draw_circle_with_segments(s.x + 3, pos, s.thumb_size, 16, thumb_border_color)
		s.ui.gg.draw_circle_with_segments(s.x + 3, pos, s.thumb_size-1, 16, thumb_color)
	}
}

fn (mut s Slider) set_pos(x int, y int) {
	s.x = x
	s.y = y
}

fn (mut s Slider) size() (int, int) {
	if s.orientation == .horizontal {
		return s.track_width, s.thumb_size
	} else {
		return s.thumb_size, s.track_height
	}
}

fn (mut s Slider) propose_size(w int, h int) (int, int) {
	/*
	s.track_width = w
	s.track_height = h
	if s.track_height > 20 {s.track_height = 20} //TODO constrain
	s.thumb_size = if s.orientation == .horizontal {s.track_height + 10} else {10}
	s.thumb_size = if s.orientation == .horizontal { 10 } else {s.track_width + 10}
	return w, s.thumb_size
	*/
	if s.orientation == .horizontal {
		return s.track_width, s.thumb_size
	} else {
		return s.thumb_size, s.track_height
	}
}

fn (s &Slider) draw() {
	// Draw the track
	cap := if s.orientation == .horizontal { s.track_height / 2 } else { s.track_width / 2 }
	s.ui.gg.draw_rounded_rect(s.x, s.y, s.track_width / 2, s.track_height / 2, cap, slider_background_color)
	if !s.is_focused {
		s.ui.gg.draw_empty_rounded_rect(s.x, s.y, s.track_width / 2, s.track_height / 2, cap, slider_background_border_color)
	} else {
		s.ui.gg.draw_empty_rounded_rect(s.x, s.y, s.track_width / 2, s.track_height / 2, cap, slider_focused_background_border_color)
	}
	// Draw the thumb
	s.draw_thumb()
}

fn slider_key_down(mut s Slider, e &KeyEvent, zzz voidptr) {
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
	return x >= s.x && x <= s.x + s.track_width && y >= s.y && y <= s.y + s.track_height
}

fn slider_mouse_button(mut s Slider, e &MouseEvent, zzz voidptr) {
	if !s.point_inside_thumb(e.x, e.y) && (!s.point_inside(e.x, e.y) || s.focus_on_thumb_only) {
		s.dragging = false
		s.is_focused = false
		return
	}
	if !s.focus_on_thumb_only {
		s.change_value(e.x, e.y)
	}
	s.is_focused = true
	s.dragging = e.action == .down
}

fn slider_mouse_move(mut s Slider, e &MouseMoveEvent, zzz voidptr) {
	if s.dragging {
		s.change_value(e.x, e.y)
	}
}

fn (mut s Slider) change_value(x int, y int) {
	dim := if s.orientation == .horizontal { s.track_width } else { s.track_height }
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

fn (mut s Slider) focus() {
	parent := s.parent
	parent.unfocus_all()
	s.is_focused = true
}

fn (s &Slider) is_focused() bool {
	return s.is_focused
}

fn (mut s Slider) unfocus() {
	s.is_focused = false
}

fn (s &Slider) point_inside_thumb(x f64, y f64) bool {
	axis := if s.orientation == .horizontal { s.x } else { s.y }
	dim := if s.orientation == .horizontal { s.track_width } else { s.track_height }
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
	px := if s.orientation == .horizontal { pos } else { f32(s.x + 3) }
	py := if s.orientation == .horizontal { f32(s.y + 3) } else { pos }

	return math.sqrt(math.pow((x - px), 2) + math.pow((y - py), 2)) <= s.thumb_size
}
