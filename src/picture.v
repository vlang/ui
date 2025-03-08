// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import os
import gg

type PictureFn = fn (&Picture)

@[heap]
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
	ui        &UI = unsafe { nil }
	image     gg.Image
	on_click  PictureFn = unsafe { nil }
	use_cache bool
	tooltip   TooltipMessage
}

@[params]
pub struct PictureParams {
pub:
	id           string
	path         string
	width        int
	height       int
	z_index      int
	movable      bool
	on_click     PictureFn = unsafe { nil }
	use_cache    bool      = true
	ref          &Picture  = unsafe { nil }
	image        gg.Image
	tooltip      string
	tooltip_side Side = .top
}

pub fn picture(c PictureParams) &Picture {
	// if c.width == 0 || c.height == 0 {
	// eprintln('V UI: Picture.width/height is 0, it will not be displayed')
	// }
	mut pic := &Picture{
		id:        c.id
		width:     c.width
		height:    c.height
		z_index:   c.z_index
		movable:   c.movable
		path:      c.path
		use_cache: c.use_cache
		on_click:  c.on_click
		image:     c.image
		tooltip:   TooltipMessage{c.tooltip, c.tooltip_side}
		ui:        unsafe { nil }
	}
	return pic
}

fn (mut pic Picture) init(parent Layout) {
	pic.parent = parent
	mut u := parent.get_ui()
	pic.ui = u
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, pic_click, pic)
	subscriber.subscribe_method(events.on_mouse_down, pic_mouse_down, pic)
	pic.ui.window.evt_mngr.add_receiver(pic, [events.on_mouse_down])
	/*
	if pic.image.width > 0 {
		// .image was set by the user, skip path  TODO
		u.resource_cache[pic.path] = pic.image
		return
	}
	*/
	if u.has_img(pic.path) {
		pic.image = u.img(pic.path)
	} else {
		if !os.exists(pic.path) {
			eprintln('V UI: picture file "${pic.path}" not found')
		}
		if pic.use_cache && pic.path in u.resource_cache {
			pic.image = unsafe { u.resource_cache[pic.path] }
		} else if mut pic.ui.dd is DrawDeviceContext {
			mut dd := pic.ui.dd
			if img := dd.create_image(pic.path) {
				pic.image = img
				u.resource_cache[pic.path] = pic.image
			}
		}
	}
	$if android {
		byte_ary := os.read_apk_asset(pic.path) or { panic(err) }
		if mut pic.ui.dd is DrawDeviceContext {
			pic.image = pic.ui.gg.create_image_from_byte_array(byte_ary) or { panic(err) }
		}
	}
	// If the user didn't set width or height, use the image's dimensions, otherwise it won't be displayed
	if pic.width == 0 || pic.height == 0 {
		pic.width = pic.image.width
		pic.height = pic.image.height
	}
	if pic.tooltip.text != '' {
		mut win := u.window
		win.tooltip.append(pic, pic.tooltip)
	}
}

@[manualfree]
pub fn (mut p Picture) cleanup() {
	mut subscriber := p.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, p)
	subscriber.unsubscribe_method(events.on_mouse_down, p)
	p.ui.window.evt_mngr.rm_receiver(p, [events.on_mouse_down])
	unsafe { p.free() }
}

@[unsafe]
pub fn (p &Picture) free() {
	$if free ? {
		print('picture ${p.id}')
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
			if pic.on_click != unsafe { PictureFn(0) } {
				pic.on_click(pic)
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
	pic.draw_device(mut pic.ui.dd)
}

fn (mut pic Picture) draw_device(mut d DrawDevice) {
	$if layout ? {
		if pic.ui.layout_print {
			println('Picture(${pic.id}): (${pic.x}, ${pic.y}, ${pic.width}, ${pic.height})')
		}
	}
	d.draw_image(pic.x + pic.offset_x, pic.y + pic.offset_y, pic.width, pic.height, pic.image)
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

fn (pic &Picture) drag_bounds() gg.Rect {
	return gg.Rect{pic.x + pic.offset_x, pic.y + pic.offset_y, pic.width, pic.height}
}

pub fn (mut pic Picture) remove_from_cache(path string) {
	pic.ui.resource_cache.delete(path)
}
