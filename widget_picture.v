// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import os
import gg

type PictureClickFn = fn (arg_1 voidptr, arg_2 voidptr) // userptr, picture

[heap]
pub struct Picture {
pub mut:
	id       string
	offset_x int
	offset_y int
	hidden   bool
	// component state for composable widget
	component voidptr
	width     int
	height    int
mut:
	text      string
	parent    Layout = empty_stack
	x         int
	y         int
	z_index   int
	movable   bool
	drag_type string = 'pic'
	path      string
	ui        &UI
	image     gg.Image
	on_click  PictureClickFn
	use_cache bool
	tooltip   TooltipMessage
}

[params]
pub struct PictureParams {
	id           string
	path         string
	width        int
	height       int
	z_index      int
	movable      bool
	on_click     PictureClickFn
	use_cache    bool     = true
	ref          &Picture = voidptr(0)
	image        gg.Image
	tooltip      string
	tooltip_side Side = .top
}

pub fn picture(c PictureParams) &Picture {
	if !os.exists(c.path) {
		eprintln('V UI: picture file "$c.path" not found')
	}
	// if c.width == 0 || c.height == 0 {
	// eprintln('V UI: Picture.width/height is 0, it will not be displayed')
	// }
	mut pic := &Picture{
		id: c.id
		width: c.width
		height: c.height
		z_index: c.z_index
		movable: c.movable
		path: c.path
		use_cache: c.use_cache
		on_click: c.on_click
		image: c.image
		tooltip: TooltipMessage{c.tooltip, c.tooltip_side}
		ui: 0
	}
	return pic
}

fn (mut pic Picture) init(parent Layout) {
	pic.parent = parent
	mut ui := parent.get_ui()
	pic.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, pic_click, pic)
	subscriber.subscribe_method(events.on_mouse_down, pic_mouse_down, pic)
	pic.ui.window.evt_mngr.add_receiver(pic, [events.on_mouse_down])
	/*
	if pic.image.width > 0 {
		// .image was set by the user, skip path  TODO
		ui.resource_cache[pic.path] = pic.image
		return
	}
	*/
	if !pic.use_cache && pic.path in ui.resource_cache {
		pic.image = ui.resource_cache[pic.path]
	} else {
		pic.image = pic.ui.gg.create_image(pic.path)
		ui.resource_cache[pic.path] = pic.image
	}
	$if android {
		byte_ary := os.read_apk_asset(pic.path) or { panic(err) }
		pic.image = pic.ui.gg.create_image_from_byte_array(byte_ary)
	}
	// If the user didn't set width or height, use the image's dimensions, otherwise it won't be displayed
	if pic.width == 0 || pic.height == 0 {
		pic.width = pic.image.width
		pic.height = pic.image.height
	}
	if pic.tooltip.text != '' {
		mut win := ui.window
		win.append_tooltip(pic, pic.tooltip)
	}
}

[manualfree]
pub fn (mut p Picture) cleanup() {
	mut subscriber := p.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, p)
	subscriber.unsubscribe_method(events.on_mouse_down, p)
	p.ui.window.evt_mngr.rm_receiver(p, [events.on_mouse_down])
	unsafe { p.free() }
}

[unsafe]
pub fn (p &Picture) free() {
	$if free ? {
		print('picture $p.id')
	}
	unsafe {
		// p.image.free()
		free(p)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn pic_click(mut pic Picture, e &MouseEvent, window &Window) {
	if pic.hidden {
		return
	}
	if pic.point_inside(e.x, e.y) {
		if int(e.action) == 0 {
			if pic.on_click != voidptr(0) {
				pic.on_click(window.state, pic)
			}
		}
	}
}

fn pic_mouse_down(mut pic Picture, e &MouseEvent, window &Window) {
	if pic.hidden {
		return
	}
	if pic.point_inside(e.x, e.y) {
		if pic.movable {
			drag_register(pic, e)
		}
	}
}

pub fn (mut pic Picture) set_pos(x int, y int) {
	pic.x = x
	pic.y = y
}

pub fn (pic &Picture) size() (int, int) {
	return pic.width, pic.height
}

pub fn (mut pic Picture) propose_size(w int, h int) (int, int) {
	// pic.width = w
	// pic.height = h
	return pic.width, pic.height
}

fn (mut pic Picture) draw() {
	pic.ui.gg.draw_image(pic.x + pic.offset_x, pic.y + pic.offset_y, pic.width, pic.height,
		pic.image)
}

fn (mut pic Picture) set_visible(state bool) {
	pic.hidden = !state
}

fn (pic &Picture) point_inside(x f64, y f64) bool {
	return point_inside(pic, x, y)
}

// method implemented in Draggable
fn (pic &Picture) get_window() &Window {
	return pic.ui.window
}

fn (pic &Picture) drag_type() string {
	return pic.drag_type
}
