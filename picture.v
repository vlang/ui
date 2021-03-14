// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import os
import gg

type PictureClickFn = fn (arg_1 voidptr, arg_2 voidptr) // userptr, picture

pub struct Picture {
pub:
	offset_x int
	offset_y int
mut:
	text      string
	parent    Layout
	x         int
	y         int
	z_index   int
	width     int
	height    int
	path      string
	ui        &UI
	image     gg.Image
	on_click  PictureClickFn
	use_cache bool
	hidden    bool
}

pub struct PictureConfig {
	path      string
	width     int
	height    int
	z_index   int
	on_click  PictureClickFn
	use_cache bool     = true
	ref       &Picture = voidptr(0)
	image     gg.Image
}

fn (mut pic Picture) init(parent Layout) {
	mut ui := parent.get_ui()
	pic.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, pic_click, pic)
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
}

pub fn picture(c PictureConfig) &Picture {
	if !os.exists(c.path) {
		eprintln('V UI: picture file "$c.path" not found')
	}
	// if c.width == 0 || c.height == 0 {
	// eprintln('V UI: Picture.width/height is 0, it will not be displayed')
	// }
	mut pic := &Picture{
		width: c.width
		height: c.height
		z_index: c.z_index
		path: c.path
		use_cache: c.use_cache
		on_click: c.on_click
		image: c.image
		ui: 0
	}
	return pic
}

fn pic_click(mut pic Picture, e &MouseEvent, window &Window) {
	if pic.point_inside(e.x, e.y) {
		if int(e.action) == 0 {
			if pic.on_click != voidptr(0) {
				pic.on_click(window.state, pic)
			}
		}
	}
}

fn (mut pic Picture) set_pos(x int, y int) {
	pic.x = x
	pic.y = y
}

fn (mut pic Picture) size() (int, int) {
	return pic.width, pic.height
}

fn (mut pic Picture) propose_size(w int, h int) (int, int) {
	// pic.width = w
	// pic.height = h
	return pic.width, pic.height
}

fn (mut pic Picture) draw() {
	pic.ui.gg.draw_image(pic.x + pic.offset_x, pic.y + pic.offset_y, pic.width, pic.height,
		pic.image)
}

fn (mut pic Picture) set_visible(state bool) {
	pic.hidden = state
}

fn (pic &Picture) focus() {
}

fn (pic &Picture) is_focused() bool {
	return false
}

fn (pic &Picture) unfocus() {
}

fn (pic &Picture) point_inside(x f64, y f64) bool {
	return x >= pic.x && x <= pic.x + pic.width && y >= pic.y && y <= pic.y + pic.height
}
