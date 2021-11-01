// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	radio_focus_color = gx.rgb(50, 50, 50)
)

/*
enum RadioState {
	normal
	check
}
*/
type RadioClickFn = fn (state voidptr, radio &Radio)

[heap]
pub struct Radio {
pub mut:
	id             string
	selected_index int
	values         []string
	// state      RadioState
	title string
	// items sizes except for compact mode where width is the full size
	height int
	width  int
	// real sizes (returned by size()) which is a sort of cached sizes to avoid recomputation
	real_height int = 20
	real_width  int
	// items widths for compact mode
	widths []int
	// adjusted sizes that fit the items contents
	adj_height int
	adj_width  int
	x          int
	y          int
	offset_x   int
	offset_y   int
	z_index    int
	parent     Layout = empty_stack
	is_focused bool
	is_checked bool
	ui         &UI
	text_cfg   gx.TextCfg
	text_size  f64
	hidden     bool
	horizontal bool
	compact    bool
	// component state for composable widget
	component voidptr
	// selected_value string
	on_click RadioClickFn
}

[params]
pub struct RadioParams {
	id       string
	on_click RadioClickFn
	values   []string
	title    string
	width    int
	z_index  int
	// ref       &Radio = voidptr(0)
	text_cfg   gx.TextCfg
	text_size  f64
	horizontal bool
	compact    bool
}

pub fn radio(c RadioParams) &Radio {
	mut r := &Radio{
		id: c.id
		height: 20
		z_index: c.z_index
		values: c.values
		title: c.title
		width: c.width
		text_cfg: c.text_cfg
		text_size: c.text_size
		horizontal: c.horizontal
		compact: c.compact
		ui: 0
		on_click: c.on_click
	}
	r.update_size()
	/*
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *r
		return &ref
	}
	*/
	return r
}

fn (mut r Radio) init(parent Layout) {
	r.parent = parent
	ui := parent.get_ui()
	r.ui = ui
	// Get max value text width
	if r.width == 0 {
		r.set_size_from_values()
	}
	init_text_cfg(mut r)
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, radio_key_down, r)
	subscriber.subscribe_method(events.on_click, radio_click, r)
}

[manualfree]
pub fn (mut r Radio) cleanup() {
	mut subscriber := r.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_key_down, r)
	subscriber.unsubscribe_method(events.on_click, r)
	unsafe { r.free() }
}

[unsafe]
pub fn (r &Radio) free() {
	$if free ? {
		print('radio $r.id')
	}
	unsafe {
		r.id.free()
		for v in r.values {
			v.free()
		}
		r.values.free()
		r.title.free()
		free(r)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn radio_key_down(mut r Radio, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if radio_keydown ? {
		println('radio_keydown: $r.id  -> $r.hidden $r.is_focused')
	}
	if r.hidden {
		return
	}
	if !r.is_focused {
		return
	}
	// default behavior like click for space and enter
	match e.key {
		.enter, .space, .right, .down {
			r.select_next_value()
		}
		.left, .up {
			r.select_prev_value()
		}
		else {}
	}
}

fn radio_click(mut r Radio, e &MouseEvent, window &Window) {
	if r.hidden {
		return
	}
	if !r.point_inside(e.x, e.y) {
		return
	}
	if r.horizontal {
		x := e.x - r.x
		if r.compact {
			mut w := 0
			r.selected_index = r.values.len - 1
			for i in 0 .. (r.values.len - 1) {
				w += r.widths[i]
				if x <= w {
					r.selected_index = i
					break
				}
			}
		} else {
			dx := if r.title == '' { 0 } else { 5 }
			r.selected_index = x / (r.width + dx)
			if r.selected_index == r.values.len {
				r.selected_index = r.values.len - 1
			}
		}
	} else {
		// println('e.y=$e.y r.y=$r.y')
		dy := if r.title == '' { 15 } else { 0 }
		y := e.y - r.y + dy
		r.selected_index = y / (r.height + 5)
		if r.selected_index == r.values.len {
			r.selected_index = r.values.len - 1
		}
	}
	if r.on_click != voidptr(0) {
		r.on_click(window.state, r)
	}
	// println(r.selected_index)
}

pub fn (mut r Radio) set_pos(x int, y int) {
	r.x = x
	r.y = y
}

pub fn (r &Radio) size() (int, int) {
	if r.horizontal {
		if r.compact {
			// r.width is here the sum of r.widths
			return r.width, r.height + 15
		} else {
			return r.values.len * r.width, r.height + 15
		}
	} else {
		return r.width, r.values.len * (r.height + 5)
	}
}

pub fn (mut r Radio) propose_size(w int, h int) (int, int) {
	if r.horizontal {
		if r.compact {
			if r.real_width > w {
				// TODO: would need a scrollview
			}
		} else {
			r.width = w / r.values.len
		}
	} else {
		r.width = w
	}
	r.update_size()
	// r.height = 20//default_font_size
	return r.real_width, r.real_height
}

pub fn (mut r Radio) set_size_from_values() {
	mut max := 0
	if r.horizontal {
		r.adj_width, r.adj_height = 0, r.height + 15
	} else {
		r.adj_width, r.adj_height = 0, (r.height + 5) * r.values.len
	}
	for value in r.values {
		width := text_width(r, value)
		if r.horizontal {
			if r.compact {
				w := width + check_mark_size + 10
				r.widths << w
				r.adj_width += w
			}
		} else {
			if width > max {
				max = width
			}
		}
	}
	if !r.horizontal {
		r.width = max + check_mark_size + 10
		r.adj_width = r.width
	}
}

pub fn (mut r Radio) update_size() {
	if r.horizontal {
		if r.compact {
			// r.width is here the sum of r.widths
			r.real_width, r.real_height = r.adj_width, r.height + 15
		} else {
			r.real_width, r.real_height = r.values.len * r.width, r.height + 15
		}
	} else {
		r.real_width, r.real_height = r.width, r.values.len * (r.height + 5)
	}
}

fn (mut r Radio) draw() {
	offset_start(mut r)
	if r.title != '' {
		// Border
		r.ui.gg.draw_empty_rect(r.x, r.y, r.real_width, r.real_height, if r.is_focused {
			ui.radio_focus_color
		} else {
			gx.gray
		})
		// Title
		r.ui.gg.draw_rect(r.x + check_mark_size, r.y - 5, r.ui.gg.text_width(r.title) + 5,
			10, default_window_color)
		// r.ui.gg.draw_text(r.x + check_mark_size + 3, r.y - 7, r.title, r.text_cfg.as_text_cfg())
		// r.draw_text(r.x + check_mark_size + 3, r.y - 7, r.title)
		draw_text(r, r.x + check_mark_size + 3, r.y - 7, r.title)
	}
	// Values
	dy := if r.title == '' { 0 } else { 15 }
	mut x, mut y := r.x + 5, r.y + dy
	for i, val in r.values {
		if i > 0 {
			if r.horizontal {
				x += if r.compact { r.widths[i - 1] } else { r.width }
			} else {
				y += r.height
			}
		}
		r.ui.gg.draw_image(x, y - 1, 16, 16, r.ui.selected_radio_image)
		if i != r.selected_index {
			r.ui.gg.draw_rect(x + 4, y + 3, 8, 8, gx.white) // hide the black circle
			// r.ui.gg.draw_image(x, y-3, 16, 16, r.ui.circle_image)
		}
		// Text
		// r.ui.gg.draw_text(r.x + check_mark_size + 10, y, val, r.text_cfg.as_text_cfg())
		// r.draw_text(r.x + check_mark_size + 10, y, val)
		draw_text(r, x + check_mark_size + 5, y, val)
	}
	$if bb ? {
		draw_bb(mut r, r.ui)
	}
	offset_end(mut r)
}

fn (r &Radio) point_inside(x f64, y f64) bool {
	rx, ry := r.x + r.offset_x, r.y + r.offset_y
	return x >= rx && x <= rx + r.real_width && y >= ry && y <= ry + r.real_height
}

fn (mut r Radio) set_visible(state bool) {
	r.hidden = !state
}

fn (mut r Radio) focus() {
	mut f := Focusable(r)
	f.set_focus()
}

fn (mut r Radio) unfocus() {
	r.is_focused = false
}

pub fn (r &Radio) selected_value() string {
	return r.values[r.selected_index]
}

pub fn (mut r Radio) select_next_value() {
	r.selected_index++
	if r.selected_index >= r.values.len {
		r.selected_index = 0
	}
}

pub fn (mut r Radio) select_prev_value() {
	r.selected_index--
	if r.selected_index < 0 {
		r.selected_index = r.values.len - 1
	}
}
