// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import time
import gg
import os
import clipboard
import eventbus

const (
	version = '0.0.4'
)

const (
	cursor_show_delay = 100 // ms
)

pub struct UI {
pub mut:
	gg             &gg.Context = voidptr(0)
	window         &Window     = voidptr(0)
	show_cursor    bool
	last_type_time i64 // used only in textbox.v
	clipboard      &clipboard.Clipboard
	btn_down       [3]bool
mut:
	cb_image             gg.Image // used only in checkbox.v
	circle_image         gg.Image // used in radio.v but no use, in idle_loop()
	selected_radio_image gg.Image // used only in radio.v
	down_arrow           gg.Image // used only in dropdown.v
	resource_cache       map[string]gg.Image // used only in picture.v
	closed               bool
	ticks                int
	// text styles and font set
	text_styles map[string]TextStyle
	fonts       FontSet
}

pub enum VerticalAlignment {
	top = 0
	center
	bottom
}

pub enum HorizontalAlignment {
	left = 0
	center
	right
}

pub interface Widget {
mut:
	id string
	x int
	y int
	z_index int
	offset_x int
	offset_y int
	hidden bool
	init(Layout)
	set_pos(x int, y int)
	size() (int, int)
	propose_size(w int, h int) (int, int)
	point_inside(x f64, y f64) bool
	set_visible(bool)
	draw()
	cleanup()
}

pub interface Layout {
	get_ui() &UI
	get_state() voidptr
	size() (int, int)
	get_children() []Widget
	get_subscriber() &eventbus.Subscriber
mut:
	resize(w int, h int)
	update_layout()
	draw()
}

pub enum MouseAction {
	up
	down
}

// MouseButton is same to sapp.MouseButton
pub enum MouseButton {
	invalid = 256
	left = 0
	right = 1
	middle = 2
}

pub struct MouseEvent {
pub:
	x      int
	y      int
	button MouseButton
	action MouseAction
	mods   KeyMod
}

pub struct ScrollEvent {
pub:
	x       f64
	y       f64
	mouse_x f64
	mouse_y f64
}

pub struct MouseMoveEvent {
pub:
	x            f64
	y            f64
	mouse_button int
	// TODO enum
}

pub enum Cursor {
	hand
	arrow
	ibeam
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

pub fn run(window &Window) {
	mut gui := window.ui
	gui.window = window
	go gui.idle_loop()
	gui.gg.run()
	gui.closed = true

	// the gui.idle_loop thread checks every 10 ms if gui.closed is true;
	// waiting 2x this time should be enough to ensure the gui.loop
	// thread will exit before us, without using a waitgroup here too
	time.sleep(20 * time.millisecond)
}

fn (mut gui UI) load_icos() {
	gui.cb_image = gui.gg.create_image_from_memory(&bytes_check_png[0], bytes_check_png.len)
	$if macos {
		gui.circle_image = gui.gg.create_image_from_memory(&bytes_darwin_circle_png[0],
			bytes_darwin_circle_png.len)
	} $else {
		gui.circle_image = gui.gg.create_image_from_memory(&bytes_circle_png[0], bytes_circle_png.len)
	}
	gui.down_arrow = gui.gg.create_image_from_memory(&bytes_arrow_png[0], bytes_arrow_png.len)
	gui.selected_radio_image = gui.gg.create_image_from_memory(&bytes_selected_radio_png[0],
		bytes_selected_radio_png.len)
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

[unsafe]
pub fn (gui &UI) free() {
	unsafe {
		// gg             &gg.Context = voidptr(0)
		// window         &Window     = voidptr(0)
		// clipboard      &clipboard.Clipboard
		// cb_image             gg.Image
		// circle_image         gg.Image
		// selected_radio_image gg.Image
		// down_arrow           gg.Image
		gui.resource_cache.free()
	}
	$if free ? {
		println('\tui -> freed')
	}
}
