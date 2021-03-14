// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	check_mark_size = 14
	cb_border_color = gx.rgb(76, 145, 244)
	cb_image        = u32(0)
)

/*
enum CheckBoxState {
	normal
	check
}
*/
type CheckChangedFn = fn (voidptr, bool)

[heap]
pub struct CheckBox {
pub mut:
	// state      CheckBoxState
	height           int
	width            int
	x                int
	y                int
	z_index          int
	parent           Layout
	is_focused       bool
	checked          bool
	ui               &UI
	on_check_changed CheckChangedFn
	text             string
	disabled         bool
	text_cfg         gx.TextCfg
	text_size        f64
	hidden           bool
}

pub struct CheckBoxConfig {
	x                int
	y                int
	z_index          int
	parent           Layout
	text             string
	on_check_changed CheckChangedFn
	checked          bool
	disabled         bool
	text_cfg         gx.TextCfg
	text_size        f64
}

fn (mut cb CheckBox) init(parent Layout) {
	cb.parent = parent
	cb.ui = parent.get_ui()
	cb.width = text_width<CheckBox>(cb, cb.text) + 5 + ui.check_mark_size
	if is_empty_text_cfg(cb.text_cfg) {
		cb.text_cfg = cb.ui.window.text_cfg
	}
	if cb.text_size > 0 {
		_, win_height := cb.ui.window.size()
		cb.text_cfg = gx.TextCfg{
			...cb.text_cfg
			size: text_size_as_int(cb.text_size, win_height)
		}
	}
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, cb_click, cb)
}

pub fn checkbox(c CheckBoxConfig) &CheckBox {
	mut cb := &CheckBox{
		height: 20 // TODO
		z_index: c.z_index
		ui: 0
		text: c.text
		on_check_changed: c.on_check_changed
		checked: c.checked
		disabled: c.disabled
		text_cfg: c.text_cfg
		text_size: c.text_size
	}
	return cb
}

fn cb_click(mut cb CheckBox, e &MouseEvent, window &Window) {
	if cb.point_inside(e.x, e.y) { // && e.action == 0 {
		cb.checked = !cb.checked
		// println("checked: $cb.checked")
		if cb.on_check_changed != voidptr(0) {
			cb.on_check_changed(window.state, cb.checked)
		}
	}
}

fn (mut cb CheckBox) set_pos(x int, y int) {
	cb.x = x
	cb.y = y
}

fn (mut cb CheckBox) size() (int, int) {
	return cb.width, cb.height
}

fn (mut cb CheckBox) propose_size(w int, h int) (int, int) {
	// cb.width = w
	// cb.height = h
	// width := check_mark_size + 5 + cb.ui.ft.text_width(cb.text)
	return cb.width, ui.check_mark_size
}

fn (mut cb CheckBox) draw() {
	cb.ui.gg.draw_rect(cb.x, cb.y, ui.check_mark_size, ui.check_mark_size, gx.white) // progress_bar_color)
	// cb.ui.gg.draw_empty_rect(cb.x, cb.y, check_mark_size, check_mark_size, cb_border_color)
	draw_inner_border(false, cb.ui.gg, cb.x, cb.y, ui.check_mark_size, ui.check_mark_size,
		false)
	// Draw X (TODO draw a check mark instead)
	if cb.checked {
		cb.ui.gg.draw_rect(cb.x + 3, cb.y + 3, 2, 2, gx.black)
		/*
		x0 := cb.x +2
		y0 := cb.y +2
		cb.ui.gg.draw_line_c(x0, y0, x0+check_mark_size -4, y0 + check_mark_size-4, gx.black)
		cb.ui.gg.draw_line_c(0.5+x0, y0, -3.5 +x0+check_mark_size , y0 + check_mark_size-4, gx.black)
		//
		y1 := cb.y + check_mark_size - 2
		cb.ui.gg.draw_line_c(x0, y1, x0+check_mark_size -4, y0, gx.black)
		cb.ui.gg.draw_line_c(0.5+x0, y1, -3.5+x0+check_mark_size, y0, gx.black)
		*/
		cb.ui.gg.draw_image(cb.x + 3, cb.y + 3, 8, 8, cb.ui.cb_image)
	}
	// Text
	cb.ui.gg.draw_text(cb.x + ui.check_mark_size + 5, cb.y, cb.text, cb.text_cfg)
	$if bb ? {
		draw_bb(cb, cb.ui)
	}
}

fn (cb &CheckBox) point_inside(x f64, y f64) bool {
	return x >= cb.x && x <= cb.x + cb.width && y >= cb.y && y <= cb.y + cb.height
}

fn (mut cb CheckBox) mouse_move(e MouseEvent) {
}

fn (mut cb CheckBox) set_visible(state bool) {
	cb.hidden = state
}

fn (mut cb CheckBox) focus() {
	cb.is_focused = true
}

fn (mut cb CheckBox) unfocus() {
	cb.is_focused = false
}

fn (cb &CheckBox) is_focused() bool {
	return cb.is_focused
}
