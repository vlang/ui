// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	check_mark_size = 14
	cb_border_color = gx.rgb(50, 50, 50) // gx.rgb(76, 145, 244)
	cb_image        = u32(0)
)

/*
enum CheckBoxState {
	normal
	check
}
*/
type CheckChangedFn = fn (voidptr, bool)

type CheckBowClickFn = fn (&CheckBox, voidptr)

[heap]
pub struct CheckBox {
pub mut:
	id string
	// state      CheckBoxState
	height           int
	width            int
	x                int
	y                int
	offset_x         int
	offset_y         int
	z_index          int
	parent           Layout = empty_stack
	is_focused       bool
	checked          bool
	ui               &UI
	on_click         CheckBowClickFn
	on_check_changed CheckChangedFn
	text             string
	disabled         bool
	text_cfg         gx.TextCfg
	text_size        f64
	hidden           bool
	// component state for composable widget
	component voidptr
}

pub struct CheckBoxConfig {
	id               string
	x                int
	y                int
	z_index          int
	text             string
	on_click         CheckBowClickFn
	on_check_changed CheckChangedFn
	checked          bool
	disabled         bool
	text_cfg         gx.TextCfg
	text_size        f64
}

pub fn checkbox(c CheckBoxConfig) &CheckBox {
	mut cb := &CheckBox{
		id: c.id
		height: ui.check_mark_size + 5 // TODO
		z_index: c.z_index
		ui: 0
		text: c.text
		on_click: c.on_click
		on_check_changed: c.on_check_changed
		checked: c.checked
		disabled: c.disabled
		text_cfg: c.text_cfg
		text_size: c.text_size
	}
	return cb
}

fn (mut cb CheckBox) init(parent Layout) {
	cb.parent = parent
	cb.ui = parent.get_ui()
	cb.width = text_width(cb, cb.text) + 5 + ui.check_mark_size
	init_text_cfg(mut cb)
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, cb_key_down, cb)
	subscriber.subscribe_method(events.on_click, cb_click, cb)
}

[manualfree]
pub fn (mut cb CheckBox) cleanup() {
	mut subscriber := cb.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_key_down, cb)
	subscriber.unsubscribe_method(events.on_click, cb)
	unsafe { cb.free() }
}

[unsafe]
pub fn (cb &CheckBox) free() {
	$if free ? {
		print('checkbox $cb.id')
	}
	unsafe { free(cb) }
	$if free ? {
		println(' -> freed')
	}
}

fn cb_key_down(mut cb CheckBox, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if cb_keydown ? {
		println('cb_keydown: $cb.id  -> $cb.hidden $cb.is_focused')
	}
	if cb.hidden {
		return
	}
	if !cb.is_focused {
		return
	}
	// default behavior like click for space and enter
	if e.key in [.enter, .space] {
		cb.checked = !cb.checked
		// println("checked: $cb.checked")
		if cb.on_check_changed != CheckChangedFn(0) {
			cb.on_check_changed(window.state, cb.checked)
		}
		if cb.on_click != CheckBowClickFn(0) {
			cb.on_click(cb, window.state)
		}
	}
}

fn cb_click(mut cb CheckBox, e &MouseEvent, window &Window) {
	if cb.hidden {
		return
	}
	if cb.point_inside(e.x, e.y) { // && e.action == 0 {
		cb.checked = !cb.checked
		// println("checked: $cb.checked")
		if cb.on_check_changed != CheckChangedFn(0) {
			cb.on_check_changed(window.state, cb.checked)
		}
		if cb.on_click != CheckBowClickFn(0) {
			cb.on_click(cb, window.state)
		}
	}
}

pub fn (mut cb CheckBox) set_pos(x int, y int) {
	cb.x = x
	cb.y = y
}

pub fn (mut cb CheckBox) size() (int, int) {
	return cb.width, cb.height
}

pub fn (mut cb CheckBox) propose_size(w int, h int) (int, int) {
	cb.width = w
	// TODO: fix height
	// cb.height = h
	// width := check_mark_size + 5 + cb.ui.ft.text_width(cb.text)
	return cb.width, cb.height
}

fn (mut cb CheckBox) draw() {
	offset_start(mut cb)
	cb.ui.gg.draw_rect(cb.x, cb.y, ui.check_mark_size, ui.check_mark_size, gx.white) // progress_bar_color)
	draw_inner_border(false, cb.ui.gg, cb.x, cb.y, ui.check_mark_size, ui.check_mark_size,
		false)
	if cb.is_focused {
		cb.ui.gg.draw_empty_rect(cb.x, cb.y, ui.check_mark_size, ui.check_mark_size, ui.cb_border_color)
	}
	// Draw X (TODO draw a check mark instead)
	if cb.checked {
		// cb.ui.gg.draw_rect(cb.x + 3, cb.y + 3, 2, 2, gx.black)
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
		draw_bb(mut cb, cb.ui)
	}
	offset_end(mut cb)
}

fn (cb &CheckBox) point_inside(x f64, y f64) bool {
	return point_inside(cb, x, y)
}

fn (mut cb CheckBox) mouse_move(e MouseEvent) {
}

fn (mut cb CheckBox) set_visible(state bool) {
	cb.hidden = !state
}

fn (mut cb CheckBox) focus() {
	// cb.is_focused = true
	set_focus(cb.ui.window, mut cb)
}

fn (mut cb CheckBox) unfocus() {
	cb.is_focused = false
}

fn (cb &CheckBox) is_focused() bool {
	return cb.is_focused
}
