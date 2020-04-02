// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	check_mark_size = 14
	cb_border_color = gx.rgb(76, 145, 244)
	cb_image = u32(0)
)

/*
enum CheckBoxState {
	normal
	check
}
*/

type CheckChangedFn fn(voidptr, bool)

pub struct CheckBox {
pub mut:

	//state      CheckBoxState
	height     int
	width      int
	x          int
	y          int
	parent ILayouter
	is_focused bool
	checked bool
	ui         &UI
	on_check_changed CheckChangedFn
	text       string
}

pub struct CheckBoxConfig {
	x       int
	y       int
	parent ILayouter
	text    string
	on_check_changed CheckChangedFn
	checked bool
}

fn (cb mut CheckBox)init(parent ILayouter) {
	cb.parent = parent
	ui := parent.get_ui()
	cb.ui = ui
	cb.width = cb.ui.ft.text_width(cb.text) + 5 + check_mark_size

	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, cb_click, cb)
}

pub fn checkbox(c CheckBoxConfig) &CheckBox {
	mut cb := &CheckBox{
		height: 20 //TODO
		text: c.text
		on_check_changed: c.on_check_changed
		checked: c.checked
	}
	return cb
}

fn cb_click(cb mut CheckBox, e &MouseEvent, window &Window) {
	if cb.point_inside(e.x, e.y) && e.action == 0 {
		cb.checked = !cb.checked
		if cb.on_check_changed != 0 {
			cb.on_check_changed(window.user_ptr, cb.checked)
		}
	}
}

fn (b mut CheckBox) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut CheckBox) size() (int, int) {
	return b.width, b.height
}

fn (b mut CheckBox) propose_size(w, h int) (int, int) {
	//b.width = w
	//b.height = h
	//width := check_mark_size + 5 + b.ui.ft.text_width(b.text)
	return b.width, check_mark_size
}

fn (b mut CheckBox) draw() {
	b.ui.gg.draw_rect(b.x, b.y, check_mark_size, check_mark_size, gx.white) // progress_bar_color)
	// b.ui.gg.draw_empty_rect(b.x, b.y, check_mark_size, check_mark_size, cb_border_color)
	draw_inner_border(b.ui.gg, b.x, b.y, check_mark_size, check_mark_size)
	// Draw X (TODO draw a check mark instead)
	if b.checked {
		/*
		x0 := b.x +2
		y0 := b.y +2
		b.ui.gg.draw_line_c(x0, y0, x0+check_mark_size -4, y0 + check_mark_size-4, gx.black)
		b.ui.gg.draw_line_c(0.5+x0, y0, -3.5 +x0+check_mark_size , y0 + check_mark_size-4, gx.black)
		//
		y1 := b.y + check_mark_size - 2
		b.ui.gg.draw_line_c(x0, y1, x0+check_mark_size -4, y0, gx.black)
		b.ui.gg.draw_line_c(0.5+x0, y1, -3.5+x0+check_mark_size, y0, gx.black)
		*/
		b.ui.gg.draw_image(b.x + 3, b.y + 3, 8, 8, b.ui.cb_image)
	}
	// Text
	b.ui.ft.draw_text(b.x + check_mark_size + 5, b.y, b.text, btn_text_cfg)
}

fn (t &CheckBox) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b mut CheckBox) mouse_move(e MouseEvent) {}

fn (b mut CheckBox) focus() {
	b.is_focused = true
}

fn (b mut CheckBox) unfocus() {
	b.is_focused = false
}


fn (t &CheckBox) is_focused() bool {
	return t.is_focused
}
