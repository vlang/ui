// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import time
import gg
import os
import clipboard

const (
	version           = '0.0.4'
	cursor_show_delay = 100 // ms
)

pub struct UI {
pub mut:
	gg             &gg.Context       = voidptr(0)
	window         &Window           = voidptr(0)
	svg            &DrawDeviceSVG    = voidptr(0)
	bmp            &DrawDeviceBitmap = voidptr(0)
	layout_print   bool
	show_cursor    bool
	last_type_time i64 // used only in textbox.v
	clipboard      &clipboard.Clipboard
	btn_down       [3]bool
	nb_click       int
	keymods        KeyMod
	styles         map[string]Style
mut:
	cb_image             gg.Image // used only in checkbox.v
	circle_image         gg.Image // used in radio.v but no use, in idle_loop()
	selected_radio_image gg.Image // used only in radio.v
	down_arrow           gg.Image // used only in dropdown.v
	resource_cache       map[string]gg.Image // used only in picture.v
	imgs                 map[string]gg.Image
	closed               bool
	ticks                int
	// text styles and font set
	text_styles map[string]TextStyle
	fonts       FontSet
	font_paths  map[string]string
}

fn (mut gui UI) idle_loop() {
	// This method is called by window.run to ensure
	// that the window will be redrawn slowly, and that
	// the cursor will blink at a rate of 1Hz, even if
	// there are no other user events.
	for {
		if time.ticks() - gui.last_type_time < ui.cursor_show_delay {
			// Always show the cursor if the user is typing right now
			gui.show_cursor = true
		} else {
			gui.show_cursor = !gui.show_cursor
		}
		gui.gg.refresh_ui()
		$if macos {
			if gui.gg.native_rendering {
				C.darwin_window_refresh()
			}
		}
		gui.ticks = 0

		// glfw.post_empty_event()
		// Sleeping for a monolithic block of 500ms means, that the thread
		// in which this method is run, may react to the closing of a dialog
		// 500ms after the button for closing the dialog/window was clicked.
		// Instead, we sleep 50 times, for just 10ms each time, checking
		// in between the sleeps, whether the dialog window had been closed.
		// This guarantees that the thread will exit at most 10ms after the
		// closing event.
		// kek_sleep()
		// time.sleep(1 * time.second)
		for i := 0; i < 50; i++ {
			time.sleep(10 * time.millisecond)
			if gui.closed {
				return
			}
		}
	}
}

fn (mut gui UI) load_imgs() {
	// gui.cb_image = gui.gg.create_image_from_memory(&bytes_check_png[0], bytes_check_png.len)
	// gui.cb_image.path = 'assets/img/check.png'
	$if macos {
		gui.circle_image = gui.gg.create_image_from_memory(&bytes_darwin_circle_png[0],
			bytes_darwin_circle_png.len)
	} $else {
		gui.circle_image = gui.gg.create_image_from_memory(&bytes_circle_png[0], bytes_circle_png.len)
	}
	gui.down_arrow = gui.gg.create_image_from_memory(&bytes_arrow_png[0], bytes_arrow_png.len)
	// gui.selected_radio_image = gui.gg.create_image_from_memory(&bytes_selected_radio_png[0],
	// 	bytes_selected_radio_png.len)
	// gui.selected_radio_image.path = 'assets/img/selected_radio.png'
	// images
	gui.load_img('check', $embed_file('assets/img/check.png').to_bytes(), 'assets/img/check.png')
	gui.cb_image = gui.img('check')
	gui.load_img('selected_radio', $embed_file('assets/img/selected_radio.png').to_bytes(),
		'assets/img/selected_radio.png')
	gui.selected_radio_image = gui.img('selected_radio')
	// load mouse
	gui.load_img('blue', $embed_file('assets/img/cursor.png').to_bytes(), 'assets/img/cursor.png')
	gui.load_img('hand', $embed_file('assets/img/icons8-hand-cursor-50.png').to_bytes(),
		'assets/img/icons8-hand-cursor-50.png')
	gui.load_img('vmove', $embed_file('assets/img/icons8-cursor-67.png').to_bytes(), 'assets/img/icons8-cursor-67.png')
	gui.load_img('text', $embed_file('assets/img/icons8-text-cursor-50.png').to_bytes(),
		'assets/img/icons8-text-cursor-50.png')
	// v-logo
	gui.load_img('v-logo', $embed_file('examples/assets/img/logo.png').to_bytes(), 'examples/assets/img/logo.png')
}

// complete the drawing system
pub fn (mut gui UI) load_img(id string, b []u8, path string) {
	gui.imgs[id] = gui.gg.create_image_from_byte_array(b)
	gui.imgs[id].path = path
}

pub fn (gui &UI) img(id string) gg.Image {
	return gui.imgs[id]
}

pub fn (gui &UI) has_img(id string) bool {
	return id in gui.imgs.keys()
}

pub fn (gui &UI) draw_device_img(d DrawDevice, id string, x int, y int, w int, h int) {
	if gui.has_img(id) {
		d.draw_image(x, y, w, h, gui.img(id))
	}
}

[unsafe]
pub fn (gui &UI) free() {
	unsafe {
		// gg             &gg.Context = voidptr(0)
		// window         &Window     = voidptr(0)
		// clipboard      &clipboard.Clipboard
		// cb_image             gg.Image
		// circle_image         gg.Image
		// radio_image          gg.Image
		// selected_radio_image gg.Image
		// down_arrow           gg.Image
		gui.resource_cache.free()
	}
	$if free ? {
		println('\tui -> freed')
	}
}

pub fn run(window &Window) {
	$if screenshot ? {
		mut w := window
		gg_init(mut w)
		w.svg_screenshot('screenshot-${os.file_name(os.executable())}.svg')
	} $else {
		mut gui := window.ui
		gui.window = window // TODO: this can be removed since now in the window constructor
		go gui.idle_loop()
		gui.gg.run()
		gui.closed = true

		// the gui.idle_loop thread checks every 10 ms if gui.closed is true;
		// waiting 2x this time should be enough to ensure the gui.loop
		// thread will exit before us, without using a waitgroup here too
		time.sleep(20 * time.millisecond)
	}
}

pub fn open_url(url string) {
	if !url.starts_with('https://') && !url.starts_with('http://') {
		return
	}
	$if windows {
		os.execute('start "$url"')
	}
	$if macos {
		os.execute('open "$url"')
	}
	$if linux {
		os.execute('xdg-open "$url"')
	}
}

pub fn confirm(s string) bool {
	return false
}
