module ui

import gx

const (
	thumb_color = gx.rgb(87, 153, 245)
	slider_background_color = gx.rgb(219, 219, 219)
	slider_background_border_color = gx.rgb(191, 191, 191)
)

type SliderValueChangedFn fn(voidptr, voidptr)

pub enum Orientation {
	vertical = 0,
	horizontal = 1
}

pub struct Slider {
pub mut:
	
	track_height     int
	track_width      int
	thumb_width 	 int
	thumb_height 	 int
	orientation      Orientation = Orientation.horizontal
	x          int
	y          int
	parent ILayouter
	ui         &UI
	val        f32
	min        int = 0
	max        int = 100
	is_focused bool
	dragging   bool
	on_value_changed SliderValueChangedFn
}

pub struct SliderConfig {
	width  int
	height int
	min    int
	max    int
	val    f32
	orientation      Orientation
	on_value_changed SliderValueChangedFn
	ref		&Slider
}

fn (s mut Slider)init(p &ILayouter) {
	parent := *p
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
	}
	p.thumb_height = if p.orientation == .horizontal {p.track_height + 10} else {10}
	p.thumb_width = if p.orientation == .horizontal { 10 } else {p.track_width + 10}
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *p
		return &ref
	}
	return p
}

fn (b &Slider) draw_thumb() {
	axis := if b.orientation == .horizontal {b.x} else {b.y}
	rev_axis := if b.orientation == .horizontal {b.y} else {b.x}

	rev_dim := if b.orientation == .horizontal { b.track_height } else { b.track_width }
	rev_thumb_dim := if b.orientation == .horizontal {b.thumb_height} else {b.thumb_width}

	dim := if b.orientation == .horizontal { b.track_width } else {b.track_height}

	mut pos := f32(dim) * (b.val / f32(b.max))
	pos += axis
	if (pos > axis + dim) {pos = f32(dim) + axis}
	if (pos < axis) {pos = axis}

	middle := f32(rev_axis) - ((rev_thumb_dim - rev_dim) / 2)

	if b.orientation == .horizontal {
		b.ui.gg.draw_rect(pos, middle, b.thumb_width, b.thumb_height, thumb_color)
	} else {
		b.ui.gg.draw_rect(middle, pos, b.thumb_width, b.thumb_height, thumb_color)
	}
}

fn (b mut Slider) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut Slider) size() (int, int) {
	if b.orientation == .horizontal {
		return b.track_width, b.thumb_height
	} else {
		return b.thumb_width, b.track_height
	}
}

fn (b mut Slider) propose_size(w, h int) (int, int) {
	/* p.track_width = w
	p.track_height = h
	if p.track_height > 20 {p.track_height = 20} //TODO constrain
	p.thumb_height = if p.orientation == .horizontal {p.track_height + 10} else {10}
	p.thumb_width = if p.orientation == .horizontal { 10 } else {p.track_width + 10}
	return w, p.thumb_height */
	if b.orientation == .horizontal {
		return b.track_width, b.thumb_height
	} else {
		return b.thumb_width, b.track_height
	}
}

fn (b &Slider) draw() {
	// Draw the track
	b.ui.gg.draw_rect(b.x, b.y, b.track_width, b.track_height, slider_background_color)
	b.ui.gg.draw_empty_rect(b.x, b.y, b.track_width, b.track_height, slider_background_border_color)

	// Draw the thumb
	b.draw_thumb()
}

fn slider_key_down(b mut Slider, e &KeyEvent) {
	match e.key {
		.arrow_down, .left {
			if b.val > b.min {
				b.val--
			}
		}
		.arrow_up, .right {
			if b.val < b.max {
				b.val++
			}
		} else{}
	}
}

fn (t &Slider) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.track_width && y >= t.y && y <= t.y + (t.track_height + t.thumb_height)
}

fn slider_click(b mut Slider, e &MouseEvent) {
	if !b.point_inside(e.x, e.y)  {
		b.dragging = false
		return
	}
	b.change_value(e.x, e.y)
	b.is_focused = true
	b.dragging = e.action == 1
}

fn slider_mouse_move(b mut Slider, e &MouseEvent) {
	if b.dragging {
		b.change_value(e.x, e.y)
	}
}

fn (b mut Slider) change_value(x, y int) {
	dim := if b.orientation == .horizontal {b.track_width} else {b.track_height}
	axis := if b.orientation == .horizontal {b.x} else {b.y}
	pos := if b.orientation == .horizontal {x} else {y} - axis

	b.val = (f32(pos) * f32(b.max)) / f32(dim)

	if int(b.val) < b.min {
		b.val = b.min
	} else if int(b.val) > b.max {
		b.val = b.max
	}
	if b.on_value_changed != 0 {
		parent := b.parent
		user_ptr := parent.get_user_ptr()
		b.on_value_changed(user_ptr, b)
	}
}

fn (b mut Slider) focus() {
	parent := b.parent
	parent.unfocus_all()
	b.is_focused = true
}

fn (t &Slider) is_focused() bool {
	return t.is_focused
}

fn (b mut Slider) unfocus() {
	b.is_focused = false
}
