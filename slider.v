module ui

import gx

const (
	thumb_color = gx.rgb(87, 153, 245)
	slider_background_color = gx.rgb(219, 219, 219)
	slider_background_border_color = gx.rgb(191, 191, 191)
	slider_focused_background_border_color = gx.rgb(255, 0, 0)
)

type SliderValueChangedFn fn(voidptr, voidptr)

pub enum Orientation {
	vertical = 0
	horizontal = 1
}

[ref_only]
pub struct Slider {
pub mut:
	track_height         int
	track_width          int
	thumb_width          int
	thumb_height         int
	orientation          Orientation=Orientation.horizontal
	x                    int
	y                    int
	parent               Layout
	ui                   &UI
	val                  f32
	min                  int=0
	max                  int=100
	is_focused           bool
	dragging             bool
	on_value_changed     SliderValueChangedFn
	focus_on_thumb_only  bool
	rev_min_max_pos      bool
	thumb_in_track       bool
	track_line_displayed bool
}

pub struct SliderConfig {
	width                int
	height               int
	min                  int
	max                  int
	val                  f32
	orientation          Orientation
	on_value_changed     SliderValueChangedFn
	focus_on_thumb_only  bool=true
	rev_min_max_pos      bool=false
	thumb_in_track       bool=false
	track_line_displayed bool=true
}

fn (mut s Slider) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	s.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, slider_click, s)
	subscriber.subscribe_method(events.on_key_down, slider_key_down, s)
	subscriber.subscribe_method(events.on_mouse_move, slider_mouse_move, s)
}

pub fn slider(c SliderConfig) &Slider {
	mut p := &Slider{
		track_height: c.height
		track_width: c.width
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
	}
	if !c.thumb_in_track {
		p.thumb_height = if p.orientation == .horizontal { p.track_height + 10 } else { 10 }
		p.thumb_width = if p.orientation == .horizontal { 10 } else { p.track_width + 10 }
	}
	else {
		p.thumb_height = if p.orientation == .horizontal { p.track_height - 3 } else { 10 }
		p.thumb_width = if p.orientation == .horizontal { 10 } else { p.track_width - 3 }
	}
	if p.min > p.max {
		tmp := p.max
		p.max = p.min
		p.min = tmp
	}
	return p
}

fn (b &Slider) draw_thumb() {
	axis := if b.orientation == .horizontal { b.x } else { b.y }
	rev_axis := if b.orientation == .horizontal { b.y } else { b.x }
	rev_dim := if b.orientation == .horizontal { b.track_height } else { b.track_width }
	rev_thumb_dim := if b.orientation == .horizontal { b.thumb_height } else { b.thumb_width }
	dim := if b.orientation == .horizontal { b.track_width } else { b.track_height }
	mut pos := f32(dim) * ((b.val - f32(b.min)) / f32(b.max - b.min))
	if b.rev_min_max_pos {
		pos = -pos + f32(dim)
	}
	pos += f32(axis)
	if  pos > axis + dim {
		pos = f32(dim) + f32(axis)
	}
	if  pos < axis {
		pos = f32(axis)
	}
	middle := f32(rev_axis) - (f32(rev_thumb_dim - rev_dim) / 2)
	if b.orientation == .horizontal {
		b.ui.gg.draw_rect(pos - f32(b.thumb_width) / 2, middle, b.thumb_width, b.thumb_height, thumb_color)
	}
	else {
		b.ui.gg.draw_rect(middle, pos - f32(b.thumb_height) / 2, b.thumb_width, b.thumb_height, thumb_color)
	}
}

fn (mut b Slider) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (mut b Slider) size() (int,int) {
	if b.orientation == .horizontal {
		return b.track_width,b.thumb_height
	}
	else {
		return b.thumb_width,b.track_height
	}
}

fn (mut b Slider) propose_size(w, h int) (int,int) {
	/* p.track_width = w
	p.track_height = h
	if p.track_height > 20 {p.track_height = 20} //TODO constrain
	p.thumb_height = if p.orientation == .horizontal {p.track_height + 10} else {10}
	p.thumb_width = if p.orientation == .horizontal { 10 } else {p.track_width + 10}
	return w, p.thumb_height */
	if b.orientation == .horizontal {
		return b.track_width,b.thumb_height
	}
	else {
		return b.thumb_width,b.track_height
	}
}

fn (b &Slider) draw() {
	// Draw the track
	b.ui.gg.draw_rect(b.x, b.y, b.track_width, b.track_height, slider_background_color)
	if b.track_line_displayed {
		if b.orientation == .horizontal {
			b.ui.gg.draw_line(b.x + 2, b.y + b.track_height / 2, b.x + b.track_width - 4, b.y + b.track_height / 2, gx.rgb(0, 0, 0))
		}
		else {
			b.ui.gg.draw_line(b.x + b.track_width / 2, b.y + 2, b.x + b.track_width / 2, b.y + b.track_height - 4, gx.rgb(0, 0, 0))
		}
	}
	if !b.is_focused {
		b.ui.gg.draw_empty_rect(b.x, b.y, b.track_width, b.track_height, slider_background_border_color)
	}
	else {
		b.ui.gg.draw_empty_rect(b.x, b.y, b.track_width, b.track_height, slider_focused_background_border_color)
	}
	// Draw the thumb
	b.draw_thumb()
}

fn slider_key_down(mut b Slider, e &KeyEvent, zzz voidptr) {
	if !b.is_focused {
		return
	}
	match e.key {
		.arrow_up, .left {
			if !b.rev_min_max_pos {
				if int(b.val) > b.min {
					b.val--
				}
			}
			else {
				if int(b.val) < b.max {
					b.val++
				}
			}
		}
		.arrow_down, .right {
			if !b.rev_min_max_pos {
				if int(b.val) < b.max {
					b.val++
				}
			}
			else {
				if int(b.val) > b.min {
					b.val--
				}
			}
		}
		else {}
	}
	if b.on_value_changed != voidptr(0) {
		parent := b.parent
		state := parent.get_state()
		b.on_value_changed(state, b)
	}
}

fn (t &Slider) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.track_width && y >= t.y && y <= t.y + t.track_height
}

fn slider_click(mut b Slider, e &MouseEvent, zzz voidptr) {
	if !b.point_inside_thumb(e.x, e.y) && (!b.point_inside(e.x, e.y) || b.focus_on_thumb_only) {
		b.dragging = false
		b.is_focused = false
		return
	}
	if !b.focus_on_thumb_only {
		b.change_value(e.x, e.y)
	}
	b.is_focused = true
	b.dragging = e.action == 1
}

fn slider_mouse_move(mut b Slider, e &MouseEvent, zzz voidptr) {
	if b.dragging {
		b.change_value(e.x, e.y)
	}
}

fn (mut b Slider) change_value(x, y int) {
	dim := if b.orientation == .horizontal { b.track_width } else { b.track_height }
	axis := if b.orientation == .horizontal { b.x } else { b.y }
	// TODO parser bug ` - axis`
	mut pos := if b.orientation == .horizontal { x } else { y }
	pos -= axis
	if b.rev_min_max_pos {
		pos = -pos + dim
	}
	b.val = f32(b.min) + (f32(pos) * f32(b.max - b.min)) / f32(dim)
	if int(b.val) < b.min {
		b.val = f32(b.min)
	}
	else if int(b.val) > b.max {
		b.val = f32(b.max)
	}
	if b.on_value_changed != voidptr(0) {
		parent := b.parent
		state := parent.get_state()
		b.on_value_changed(state, b)
	}
}

fn (mut b Slider) focus() {
	parent := b.parent
	parent.unfocus_all()
	b.is_focused = true
}

fn (t &Slider) is_focused() bool {
	return t.is_focused
}

fn (mut b Slider) unfocus() {
	b.is_focused = false
}

fn (t &Slider) point_inside_thumb(x, y f64) bool {
	axis := if t.orientation == .horizontal { t.x } else { t.y }
	rev_axis := if t.orientation == .horizontal { t.y } else { t.x }
	rev_dim := if t.orientation == .horizontal { t.track_height } else { t.track_width }
	rev_thumb_dim := if t.orientation == .horizontal { t.thumb_height } else { t.thumb_width }
	dim := if t.orientation == .horizontal { t.track_width } else { t.track_height }
	mut pos := f32(dim) * ((t.val - f32(t.min)) / f32(t.max - t.min))
	if t.rev_min_max_pos {
		pos = -pos + f32(dim)
	}
	pos += f32(axis)
	if  pos > axis + dim {
		pos = f32(dim) + f32(axis)
	}
	if pos < axis {
		pos = f32(axis)
	}
	middle := f32(rev_axis) - (f32(rev_thumb_dim - rev_dim) / 2)
	if t.orientation == .horizontal {
		t_x := pos - f32(t.thumb_width) / 2
		t_y := middle
		return x >= t_x && x <= t_x + f32(t.thumb_width) && y >= t_y && y <= t_y + f32(t.thumb_height)
	}
	else {
		t_x := middle
		t_y := pos - f32(t.thumb_height) / 2
		return x >= t_x && x <= t_x + f32(t.thumb_width) && y >= t_y && y <= t_y + f32(t.thumb_height)
	}
}
