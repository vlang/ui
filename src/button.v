// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import os
import math

const button_bg_color = gx.rgb(28, 28, 28)
const button_border_color = gx.rgb(200, 200, 200)
const button_focus_border_color = gx.rgb(50, 50, 50)
const button_horizontal_padding = 26
const button_vertical_padding = 8

enum ButtonState {
	normal = 1 // synchronized with .button_normal
	pressed
	hovering
}

pub type ButtonFn = fn (&Button)

pub type ButtonU32Fn = fn (&Button, u32)

pub type ButtonMouseFn = fn (&Button, &MouseEvent)

pub type ButtonMouseMoveFn = fn (&Button, &MouseMoveEvent)

@[heap]
pub struct Button {
	// init size read-only
pub:
	width_  int
	height_ int
pub mut:
	id          string
	state       ButtonState = .normal
	height      int
	width       int
	z_index     int
	x           int
	y           int
	offset_x    int
	offset_y    int
	text_width  int
	text_height int
	parent      Layout = empty_stack
	is_focused  bool
	ui          &UI      = unsafe { nil }
	on_click    ButtonFn = unsafe { nil }
	// TODO: same convention for all callback
	on_key_down    ButtonU32Fn       = unsafe { nil }
	on_mouse_down  ButtonMouseFn     = unsafe { nil }
	on_mouse_up    ButtonMouseFn     = unsafe { nil }
	on_mouse_move  ButtonMouseMoveFn = unsafe { nil }
	on_mouse_enter ButtonMouseMoveFn = unsafe { nil }
	on_mouse_leave ButtonMouseMoveFn = unsafe { nil }
	text           string
	icon_path      string
	image          gg.Image
	use_icon       bool
	alpha_mode     bool
	padding        f32
	hidden         bool
	disabled       bool
	movable        bool // drag, transition or anything allowing offset yo be updated
	just_dragged   bool
	drag_type      string = 'btn'
	hoverable      bool
	tooltip        TooltipMessage
	// style
	// radius   f32
	bg_color &gx.Color = unsafe { nil }
	// Style
	theme_style  string
	style        ButtonShapeStyle
	style_params ButtonStyleParams
	// text styles
	text_styles TextStyles
	// text_size   f64
	// // theme
	// theme_cfg ColorThemeCfg
	// theme     map[int]gx.Color = map[int]gx.Color{}
	// component state for composable widget
	component voidptr
}

@[params]
pub struct ButtonParams {
	ButtonStyleParams
pub:
	id             string
	text           string
	icon_path      string
	on_click       ButtonFn          = unsafe { nil }
	on_key_down    ButtonU32Fn       = unsafe { nil }
	on_mouse_down  ButtonMouseFn     = unsafe { nil }
	on_mouse_up    ButtonMouseFn     = unsafe { nil }
	on_mouse_move  ButtonMouseMoveFn = unsafe { nil }
	on_mouse_enter ButtonMouseMoveFn = unsafe { nil }
	on_mouse_leave ButtonMouseMoveFn = unsafe { nil }
	height         int
	width          int
	z_index        int
	movable        bool
	hoverable      bool
	tooltip        string
	tooltip_side   Side = .top
	padding        f64
	// text_size    f64
	theme string = no_style
}

pub fn button(c ButtonParams) &Button {
	mut b := &Button{
		id:             c.id
		width_:         c.width
		height_:        c.height
		z_index:        c.z_index
		movable:        c.movable
		hoverable:      c.hoverable
		text:           c.text
		icon_path:      c.icon_path
		use_icon:       c.icon_path != ''
		tooltip:        TooltipMessage{c.tooltip, c.tooltip_side}
		style_params:   c.ButtonStyleParams
		on_click:       c.on_click
		on_key_down:    c.on_key_down
		on_mouse_down:  c.on_mouse_down
		on_mouse_up:    c.on_mouse_up
		on_mouse_move:  c.on_mouse_move
		on_mouse_enter: c.on_mouse_enter
		on_mouse_leave: c.on_mouse_leave
		// text_size: c.text_size
		// radius: f32(c.radius)
		padding: f32(c.padding)
		ui:      unsafe { nil }
	}
	b.style_params.style = c.theme
	if b.use_icon && !os.exists(c.icon_path) {
		println('Invalid icon path "${c.icon_path}". The alternate text will be used.')
		b.use_icon = false
	}
	return b
}

fn (mut b Button) init(parent Layout) {
	b.parent = parent
	u := parent.get_ui()
	b.ui = u
	if b.use_icon {
		if mut b.ui.dd is DrawDeviceContext {
			if img := b.ui.dd.create_image(b.icon_path) {
				b.image = img
			}
		}
	}
	b.load_style()
	b.set_text_size()
	if b.tooltip.text != '' {
		mut win := u.window
		win.tooltip.append(b, b.tooltip)
	}
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, btn_key_down, b)
	subscriber.subscribe_method(events.on_mouse_down, btn_mouse_down, b)
	subscriber.subscribe_method(events.on_click, btn_click, b)
	subscriber.subscribe_method(events.on_touch_down, btn_mouse_down, b)
	subscriber.subscribe_method(events.on_mouse_move, btn_mouse_move, b)
	subscriber.subscribe_method(events.on_mouse_up, btn_mouse_up, b)
	subscriber.subscribe_method(events.on_touch_up, btn_mouse_up, b)
	b.ui.window.evt_mngr.add_receiver(b, [events.on_mouse_down, events.on_mouse_move])
}

@[manualfree]
fn (mut b Button) cleanup() {
	mut subscriber := b.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_key_down, b)
	subscriber.unsubscribe_method(events.on_mouse_down, b)
	subscriber.unsubscribe_method(events.on_click, b)
	subscriber.unsubscribe_method(events.on_touch_down, b)
	subscriber.unsubscribe_method(events.on_mouse_move, b)
	b.ui.window.evt_mngr.rm_receiver(b, [events.on_mouse_down, events.on_mouse_move])
	unsafe { b.free() }
}

@[unsafe]
pub fn (b &Button) free() {
	$if free ? {
		print('button ${b.id}')
	}
	unsafe {
		b.id.free()
		b.text.free()
		b.icon_path.free()
		// s.on_click   ButtonClickFn
		b.tooltip.free()
		// s.theme     ColorThemeCfg = 'classic'

		// if b.component != voidptr(0) {
		// 	free(b.component)
		// }
		free(b)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn btn_key_down(mut b Button, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if btn_keydown ? {
		println('btn_keydown: ${b.id}  -> ${b.hidden} ${b.is_focused}')
	}
	if b.hidden {
		return
	}
	if !b.is_focused {
		return
	}
	if b.on_key_down != unsafe { ButtonU32Fn(0) } {
		b.on_key_down(b, e.codepoint)
	} else {
		// default behavior like click for space and enter
		if e.key in [.enter, .space] {
			// println("btn key as a click")
			if b.on_click != unsafe { ButtonFn(0) } {
				b.on_click(b)
			}
		}
	}
}

fn btn_click(mut b Button, e &MouseEvent, window &Window) {
	$if btn_click ? {
		println('btn_click ${b.id} movable ${b.movable} focused ${b.is_focused} top_widget ${b.ui.window.is_top_widget(b,
			events.on_mouse_down)}')
	}
	if b.hidden || b.disabled {
		return
	}
	$if wpir ? {
		println('btn click: ${b.id} ${b.ui.window.point_inside_receivers(events.on_mouse_down)}')
	}
	if !b.ui.window.is_top_widget(b, events.on_mouse_down) {
		return
	}
	if !b.is_focused {
		return
	}
	// unclickable if dragged
	if b.just_dragged {
		b.just_dragged = false
		return
	}
	if b.point_inside(e.x, e.y) {
		if e.action == .down {
			b.state = .pressed
		} else if e.action == .up {
			b.state = .normal
			if b.on_click != unsafe { ButtonFn(0) } && b.is_focused {
				$if btn_onclick ? {
					println('onclick ${b.id}')
				}
				b.on_click(b)
			}
		}
	}
}

fn btn_mouse_down(mut b Button, e &MouseEvent, window &Window) {
	$if btn_md ? {
		println('btn_mouse_down ${b.id} movable ${b.movable} top_widget ${b.ui.window.is_top_widget(b,
			events.on_mouse_down)}')
	}
	if b.hidden {
		return
	}
	if !b.ui.window.is_top_widget(b, events.on_mouse_down) {
		return
	}
	if b.point_inside(e.x, e.y) {
		b.focus() // IMPORTANT to not propagate event at the same position of removed widget
		if b.movable {
			b.just_dragged = drag_register(b, e)
		}
		if !b.just_dragged {
			b.state = .pressed
		}
		if b.on_mouse_down != unsafe { ButtonMouseFn(0) } {
			b.on_mouse_down(b, e)
		}
	}
}

fn btn_mouse_up(mut b Button, e &MouseEvent, window &Window) {
	$if btn_mu ? {
		println('btn_mu ${b.id}')
	}
	if b.hidden {
		return
	}
	b.state = .normal
	if b.on_mouse_up != unsafe { ButtonMouseFn(0) } {
		b.on_mouse_up(b, e)
	}
}

fn btn_mouse_move(mut b Button, e &MouseMoveEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	if e.mouse_button == 256 {
		if b.point_inside(e.x, e.y) {
			if b.hoverable && b.state != .hovering {
				if b.state != .pressed {
					b.state = .hovering
				}
			}
		} else {
			b.state = .normal
		}
	} else {
		// to use button as a splitter (no test point_inside)
		if b.on_mouse_move != unsafe { ButtonMouseMoveFn(0) } {
			b.on_mouse_move(b, e)
		}
	}
}

pub fn (mut b Button) mouse_enter(e &MouseMoveEvent) {
	if b.on_mouse_enter != unsafe { ButtonMouseMoveFn(0) } {
		b.on_mouse_enter(b, e)
	}
}

pub fn (mut b Button) mouse_leave(e &MouseMoveEvent) {
	if b.on_mouse_leave != unsafe { ButtonMouseMoveFn(0) } {
		b.on_mouse_leave(b, e)
	}
}

pub fn (mut b Button) set_pos(x int, y int) {
	b.x = x
	b.y = y
}

pub fn (b &Button) size() (int, int) {
	return b.width, b.height
}

pub fn (mut b Button) propose_size(w int, h int) (int, int) {
	// println('prop size $w $h')
	if w != 0 {
		b.width = w
	}
	if h != 0 {
		b.height = h
	}
	// b.height = h
	// b.width = b.ui.ft.text_width(b.text) + ui.button_horizontal_padding
	// b.height = 20 // vertical padding
	// println("but $b.id prop size: $w, $h => $b.width, $b.height")
	// update_text_size(mut b)
	return b.width, b.height
}

fn (mut b Button) draw() {
	b.draw_device(mut b.ui.dd)
}

fn (mut b Button) draw_device(mut d DrawDevice) {
	offset_start(mut b)
	defer {
		offset_end(mut b)
	}
	$if layout ? {
		if b.ui.layout_print {
			println('Button(${b.id}): (${b.x}, ${b.y}, ${b.width}, ${b.height})')
		}
	}

	bcenter_x := b.x + b.width / 2
	bcenter_y := b.y + b.height / 2
	padding := relative_size(b.padding, b.width, b.height)
	x, y, width, height := b.x + padding, b.y + padding, b.width - 2 * padding, b.height - 2 * padding
	mut state := b.state
	if b.disabled {
		state = .normal
	}
	mut bg_color := match state {
		.normal {
			if b.bg_color != unsafe { nil } { *b.bg_color } else { b.style.bg_color }
		}
		.hovering {
			b.style.bg_color_hover
		}
		.pressed {
			b.style.bg_color_pressed
		}
	}
	if b.disabled {
		bg_color.a = 50
	}
	if b.style.radius > 0 {
		radius := relative_size(b.style.radius, int(width), int(height))
		// println("draw $b.id ${bg_color}")
		d.draw_rounded_rect_filled(x, y, width, height, radius, bg_color) // gx.white)
		d.draw_rounded_rect_empty(x, y, width, height, radius, if b.is_focused {
			button_focus_border_color
		} else {
			b.style.border_color
		})
	} else {
		if b.alpha_mode && bg_color.a < 255 { // draw a background to see alpha color
			n := 5
			dx, dy := width / n, height / n
			for k1 in 0 .. n {
				for k2 in 0 .. n {
					if math.mod(k1 + k2, 2) < 0.1 {
						d.draw_rect_filled(x + k1 * dx, y + k2 * dy, width / n, height / n,
							gx.light_gray)
					}
				}
			}
		}
		d.draw_rect_filled(x, y, width, height, bg_color) // gx.white)
		d.draw_rect_empty(x, y, width, height, if b.is_focused {
			button_focus_border_color
		} else {
			b.style.border_color
		})
	}
	if b.use_icon {
		d.draw_image(x, y, width, height, b.image)
	} else {
		mut dtw := DrawTextWidget(b)
		dtw.draw_device_load_style(d)
		dtw.draw_device_text(d, bcenter_x, bcenter_y, b.text)
	}
	$if tbb ? {
		println('bcenter_x(${bcenter_x}) = b.x(${b.x}) + b.width(${b.width}) / 2')
		println('bcenter_y(${bcenter_y}) = b.y(${b.y}) + b.height(${b.height}) / 2')
		println('draw_text(b, bcenter_x(${bcenter_x}), bcenter_y(${bcenter_y}), b.text(${b.text}))')
		println('draw_rect(b.x(${b.x}), b.y(${b.y}), b.width(${b.width}), b.height(${b.height}), bg_color)')
		debug_draw_bb_text(bcenter_x, y, b.text_width, b.text_height, b.ui)
	}
	$if bb ? {
		debug_draw_bb_widget(mut b, b.ui)
	}
}

pub fn (mut b Button) set_text(text string) {
	b.text = text
	b.set_text_size()
}

pub fn (mut b Button) set_text_size() {
	if b.use_icon {
		b.width = b.image.width
		b.height = b.image.height
	} else {
		mut dtw := DrawTextWidget(b)
		dtw.load_style()
		b.text_width, b.text_height = dtw.text_size(b.text)
		if b.id == 'hi' {
			println('${b.text_width}')
		}
		// b.text_width, b.text_height = text_size(b, b.text)

		// b.text_width = int(f32(b.text_width))
		// b.text_height = int(f32(b.text_height))
		b.width = b.text_width + button_horizontal_padding
		if b.width_ > b.width {
			b.width = b.width_
		}
		b.height = b.text_height + button_vertical_padding
		if b.height_ > b.height {
			b.height = b.height_
		}
	}
}

fn (b &Button) point_inside(x f64, y f64) bool {
	// println("point_inside button: ($b.x $b.offset_x, $b.y $b.offset_y) ($x, $y) ($b.width, $b.height)")
	return point_inside(b, x, y)
}

fn (mut b Button) set_visible(state bool) {
	b.hidden = !state
}

fn (mut b Button) focus() {
	mut f := Focusable(b)
	f.force_focus()
}

fn (mut b Button) unfocus() {
	b.is_focused = false
	b.state = .normal
}

// method implemented in Draggable
fn (b &Button) get_window() &Window {
	return b.ui.window
}

fn (b &Button) drag_type() string {
	return b.drag_type
}

fn (b &Button) drag_bounds() gg.Rect {
	w, h := b.size()
	return gg.Rect{b.x + b.offset_x, b.y + b.offset_y, w, h}
}
