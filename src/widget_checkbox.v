// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import math

const (
	check_mark_size = 14
	cb_border_color = gx.rgb(50, 50, 50) // gx.rgb(76, 145, 244)
)

// type CheckChangedFn = fn (voidptr, bool)

type CheckBoxFn = fn (&CheckBox)

[heap]
pub struct CheckBox {
pub mut:
	id               string
	height           int
	width            int
	adj_height       int
	adj_width        int
	x                int
	y                int
	offset_x         int
	offset_y         int
	z_index          int
	parent           Layout = empty_stack
	is_focused       bool
	checked          bool
	ui               &UI = unsafe { nil }
	on_click         CheckBoxFn
	on_check_changed CheckBoxFn
	text             string
	// Adjustable
	justify  []f64
	ax       int
	ay       int
	disabled bool
	// Style
	theme_style  string
	style        CheckBoxShapeStyle
	style_params CheckBoxStyleParams
	// text styles
	text_styles TextStyles
	// text_size   f64
	hidden bool
	// bg_color    gx.Color = no_color
	// component state for composable widget
	component voidptr
}

[params]
pub struct CheckBoxParams {
	CheckBoxStyleParams
	id               string
	x                int
	y                int
	z_index          int
	text             string
	on_click         CheckBoxFn
	on_check_changed CheckBoxFn
	checked          bool
	disabled         bool
	justify          []f64  = [0.0, 0.0]
	theme            string = no_style
}

pub fn checkbox(c CheckBoxParams) &CheckBox {
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
		style_params: c.CheckBoxStyleParams
		justify: c.justify
	}
	cb.style_params.style = c.theme
	return cb
}

pub fn (mut cb CheckBox) init(parent Layout) {
	cb.parent = parent
	cb.ui = parent.get_ui()
	mut dtw := DrawTextWidget(cb)
	dtw.load_style()
	cb.width = dtw.text_width(cb.text) + 5 + ui.check_mark_size
	cb.load_style()
	// cb.init_style()
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
		print('checkbox ${cb.id}')
	}
	unsafe { free(cb) }
	$if free ? {
		println(' -> freed')
	}
}

// fn (mut cb CheckBox) init_style() {
// 	mut dtw := DrawTextWidget(cb)
// 	dtw.init_style()
// 	dtw.update_text_size(cb.text_size)
// }

fn cb_key_down(mut cb CheckBox, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if cb_keydown ? {
		println('cb_keydown: ${cb.id}  -> ${cb.hidden} ${cb.is_focused}')
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
		if cb.on_check_changed != CheckBoxFn(0) {
			cb.on_check_changed(cb)
		}
		if cb.on_click != CheckBoxFn(0) {
			cb.on_click(cb)
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
		if cb.on_check_changed != CheckBoxFn(0) {
			cb.on_check_changed(cb)
		}
		if cb.on_click != CheckBoxFn(0) {
			cb.on_click(cb)
		}
	}
}

pub fn (mut cb CheckBox) set_pos(x int, y int) {
	cb.x = x
	cb.y = y
}

pub fn (mut cb CheckBox) adj_size() (int, int) {
	if cb.adj_width == 0 || cb.adj_height == 0 {
		mut dtw := DrawTextWidget(cb)
		dtw.load_style()
		mut w, mut h := 0, 0
		w, h = dtw.text_size(cb.text)
		cb.adj_width, cb.adj_height = w + ui.check_mark_size, math.max(h, ui.check_mark_size)
	}
	return cb.adj_width, cb.adj_height
}

pub fn (cb &CheckBox) size() (int, int) {
	return cb.width, cb.height
}

pub fn (mut cb CheckBox) propose_size(w int, h int) (int, int) {
	// println("propose_size $cb.id ($w, $h)")
	cb.width = w
	// TODO: fix height
	cb.height = h
	// width := check_mark_size + 5 + cb.ui.ft.text_width(cb.text)
	return cb.width, cb.height
}

pub fn (mut cb CheckBox) draw() {
	cb.draw_device(mut cb.ui.dd)
}

pub fn (mut cb CheckBox) draw_device(mut d DrawDevice) {
	offset_start(mut cb)
	$if layout ? {
		if cb.ui.layout_print {
			println('CheckBox(${cb.id}): (${cb.x}, ${cb.y}, ${cb.width}, ${cb.height})')
		}
	}
	adj_pos_x, adj_pos_y := AdjustableWidget(cb).get_adjusted_pos()
	// if cb.style.bg_color != no_color {
	d.draw_rect_filled(adj_pos_x - (cb.width - cb.adj_width) / 2, adj_pos_y - (cb.height - cb.adj_height) / 2,
		cb.width, cb.height, cb.parent.bg_color()) // cb.ui.window.bg_color) // cb.style.bg_color)
	// }
	d.draw_rect_filled(adj_pos_x, adj_pos_y, ui.check_mark_size, ui.check_mark_size, cb.style.bg_color) // progress_bar_color)
	draw_device_inner_border(false, d, adj_pos_x, adj_pos_y, ui.check_mark_size, ui.check_mark_size,
		false)
	if cb.is_focused {
		d.draw_rect_empty(adj_pos_x, adj_pos_y, ui.check_mark_size, ui.check_mark_size,
			cb.style.border_color)
	}
	// Draw X (TODO draw a check mark instead)
	if cb.checked {
		// cb.ui.dd.draw_rect_filled(cb.x + 3, cb.y + 3, 2, 2, gx.black)
		/*
		x0 := cb.x +2
		y0 := cb.y +2
		cb.ui.dd.draw_line_c(x0, y0, x0+check_mark_size -4, y0 + check_mark_size-4, gx.black)
		cb.ui.dd.draw_line_c(0.5+x0, y0, -3.5 +x0+check_mark_size , y0 + check_mark_size-4, gx.black)
		//
		y1 := cb.y + check_mark_size - 2
		cb.ui.dd.draw_line_c(x0, y1, x0+check_mark_size -4, y0, gx.black)
		cb.ui.dd.draw_line_c(0.5+x0, y1, -3.5+x0+check_mark_size, y0, gx.black)
		*/
		d.draw_image(adj_pos_x + 3, adj_pos_y + 3, 8, 8, cb.ui.cb_image)
	}
	// Text
	mut dtw := DrawTextWidget(cb)
	dtw.draw_device_load_style(d)
	dtw.draw_device_text(d, adj_pos_x + ui.check_mark_size + 5, adj_pos_y, cb.text)
	$if bb ? {
		debug_draw_bb_widget(mut cb, cb.ui)
	}
	offset_end(mut cb)
}

fn (cb &CheckBox) point_inside(x f64, y f64) bool {
	return point_inside(cb, x, y)
}

fn (mut cb CheckBox) mouse_move(e MouseEvent) {
}

pub fn (mut cb CheckBox) set_visible(state bool) {
	cb.hidden = !state
}

pub fn (mut cb CheckBox) focus() {
	mut f := Focusable(cb)
	f.set_focus()
}

fn (mut cb CheckBox) unfocus() {
	cb.is_focused = false
}
