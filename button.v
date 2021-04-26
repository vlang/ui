// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import os

const (
	button_bg_color           = gx.rgb(28, 28, 28)
	button_border_color       = gx.rgb(200, 200, 200)
	button_horizontal_padding = 26
	button_vertical_padding   = 8
)

enum ButtonState {
	normal = 1 // synchronized with .button_normal
	pressed
}

type ButtonClickFn = fn (voidptr, voidptr) // userptr, btn

pub struct ButtonConfig {
	id        string
	text      string
	icon_path string
	onclick   ButtonClickFn
	height    int
	width     int
	z_index   int
	movable   bool
	tooltip   string
	text_cfg  gx.TextCfg
	text_size f64
	theme     ColorThemeCfg = 'classic'
}

[heap]
pub struct Button {
	// init size read-only
	width_  int
	height_ int
mut:
	text_width  int
	text_height int
pub mut:
	id         string
	state      ButtonState = ButtonState(1)
	height     int
	width      int
	z_index    int
	x          int
	y          int
	offset_x   int
	offset_y   int
	parent     Layout
	is_focused bool
	ui         &UI = 0
	onclick    ButtonClickFn
	text       string
	icon_path  string
	image      gg.Image
	use_icon   bool
	text_cfg   gx.TextCfg
	text_size  f64
	hidden     bool
	movable    bool // drag, transition or anything allowing offset yo be updated
	tooltip    string
	// theme
	theme_ ColorThemeCfg
	theme  map[int]gx.Color = map[int]gx.Color{}
}

fn (mut b Button) init(parent Layout) {
	b.parent = parent
	ui := parent.get_ui()
	b.ui = ui
	if b.use_icon {
		b.image = b.ui.gg.create_image(b.icon_path)
	}
	init_text_cfg<Button>(mut b)
	b.set_text_size()
	b.update_theme()
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_mouse_down, btn_mouse_down, b)
	subscriber.subscribe_method(events.on_click, btn_click, b)
	subscriber.subscribe_method(events.on_mouse_move, btn_mouse_move, b)
}

pub fn button(c ButtonConfig) &Button {
	mut b := &Button{
		id: c.id
		width_: c.width
		height_: c.height
		z_index: c.z_index
		movable: c.movable
		text: c.text
		icon_path: c.icon_path
		use_icon: c.icon_path != ''
		tooltip: c.tooltip
		theme_: c.theme
		onclick: c.onclick
		text_cfg: c.text_cfg
		text_size: c.text_size
		ui: 0
	}
	if b.use_icon && !os.exists(c.icon_path) {
		println('Invalid icon path "$c.icon_path". The alternate text will be used.')
		b.use_icon = false
	}
	return b
}

fn btn_click(mut b Button, e &MouseEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	if b.point_inside(e.x, e.y) {
		if e.action == .down {
			b.state = .pressed
		} else if e.action == .up {
			b.state = .normal
			if b.onclick != voidptr(0) {
				b.onclick(window.state, b)
			}
		}
	}
}

fn btn_mouse_down(mut b Button, e &MouseEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	if b.point_inside(e.x, e.y) {
		if b.movable {
			drag_register(b, b.ui, e)
		}
		b.state = .pressed
	}
}

fn btn_mouse_move(mut b Button, e &MouseMoveEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	if b.tooltip != '' && e.mouse_button == 256 {
		if b.point_inside(e.x, e.y) {
			// println("tooltip: $b.id $b.tooltip ($e.x, $e.y, $e.mouse_button)")
			start_tooltip(mut b, b.id, b.tooltip, b.ui)
		} else {
			stop_tooltip(b, b.id, b.ui)
		}
	}
}

fn (mut b Button) set_pos(x int, y int) {
	b.x = x
	b.y = y
}

pub fn (mut b Button) size() (int, int) {
	if b.width == 0 || b.height == 0 {
		b.set_text_size()
	}
	return b.width, b.height
}

fn (mut b Button) propose_size(w int, h int) (int, int) {
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
	// println("but prop size: $w, $h => $b.width, $b.height")
	update_text_size(mut b)
	return b.width, b.height
}

fn (mut b Button) draw() {
	offset_start(mut b)
	w2 := b.text_width / 2
	h2 := b.text_height / 2
	bcenter_x := b.x + b.width / 2
	bcenter_y := b.y + b.height / 2
	bg_color := color(b.theme, ColorType(b.state))
	// println(bg_color)
	b.ui.gg.draw_rect(b.x, b.y, b.width, b.height, bg_color) // gx.white)
	b.ui.gg.draw_empty_rect(b.x, b.y, b.width, b.height, ui.button_border_color)
	mut y := bcenter_y - h2 - 1
	// if b.ui.gg.scale == 2 {
	// $if macos { // TODO
	// 	y -= 2
	// }
	if b.use_icon {
		b.ui.gg.draw_image(b.x, b.y, b.width, b.height, b.image)
	} else {
		// b.ui.gg.draw_text(bcenter_x - w2, y, b.text, b.text_cfg.as_text_cfg())
		// b.draw_text(bcenter_x - w2, y, b.text)
		// draw_text<Button>(b, bcenter_x - w2, y, b.text)
		draw_text_line(b, bcenter_x - w2, y, b.text)
	}
	$if tbb ? {
		println('button: w2($w2) = b.text_width ($b.text_width) / 2')
		println('    h2($h2) = b.text_height($b.text_height) / 2')
		println('    bcenter_x($bcenter_x) = b.x($b.x) + b.width($b.width) / 2')
		println('    bcenter_y($bcenter_y) = b.y($b.y) + b.height($b.height) / 2')
		println('draw_text<Button>(b, bcenter_x($bcenter_x) - w2($w2), y($y), b.text($b.text))')
		println('draw_rect(b.x($b.x), b.y($b.y), b.width($b.width), b.height($b.height), bg_color)')
		draw_text_bb(bcenter_x - w2, y, b.text_width, b.text_height, b.ui)
	}
	$if bb ? {
		draw_bb(mut b, b.ui)
	}
	// b.ui.gg.draw_empty_rect(bcenter_x-w2, bcenter_y-h2, text_width, text_height, ui.button_border_color)
	offset_end(mut b)
}

pub fn (mut b Button) set_text(text string) {
	b.text = text
	b.set_text_size()
}

fn (mut b Button) set_text_size() {
	if b.use_icon {
		b.width = b.image.width
		b.height = b.image.height
	} else {
		b.text_width, b.text_height = text_size<Button>(b, b.text)
		b.text_width = int(f32(b.text_width))
		b.text_height = int(f32(b.text_height))
		b.width = b.text_width + ui.button_horizontal_padding
		if b.width_ > b.width {
			b.width = b.width_
		}
		b.height = b.text_height + ui.button_vertical_padding
		if b.height_ > b.height {
			b.height = b.height_
		}
	}
}

// fn (b &Button) key_down(e KeyEvent) {}

fn (b &Button) point_inside(x f64, y f64) bool {
	// bx , by := b.x + b.offset_x, b.y + b.offset_y
	// return x >= bx && x <= bx + b.width && y >= by && y <= by + b.height
	// println("point_inside button: ($b.x $b.offset_x, $b.y $b.offset_y) ($x, $y) ($b.width, $b.height)")
	return point_inside<Button>(b, x, y)
}

fn (mut b Button) set_visible(state bool) {
	b.hidden = state
}

// fn (mut b Button) mouse_move(e MouseEvent) {}
fn (mut b Button) focus() {
	b.is_focused = true
}

fn (mut b Button) unfocus() {
	b.is_focused = false
	b.state = .normal
}

fn (b &Button) is_focused() bool {
	return b.is_focused
}

pub fn (mut b Button) set_theme(theme_cfg ColorThemeCfg) {
	b.theme_ = theme_cfg
}

pub fn (mut b Button) update_theme() {
	mut theme := map[int]gx.Color{}
	theme_ := b.theme_
	if theme_ is string {
		theme = b.ui.window.color_themes[theme_]
	}
	if theme_ is ColorTheme {
		theme = theme_
	}
	update_colors_from(mut b.theme, theme, [.button_normal, .button_pressed])
}
