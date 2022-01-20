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
	gg             &gg.Context = voidptr(0)
	window         &Window     = voidptr(0)
	show_cursor    bool
	last_type_time i64
	clipboard      &clipboard.Clipboard
	btn_down       [3]bool
mut:
	// just_typed           bool
	cb_image             gg.Image
	circle_image         gg.Image
	radio_image          gg.Image
	selected_radio_image gg.Image
	down_arrow           gg.Image
	redraw_requested     bool
	resource_cache       map[string]gg.Image
	closed               bool
	ticks                int
	// text styles and font set
	text_styles map[string]TextStyle
	fonts       FontSet
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
	mut gui := window.ui
	gui.window = window
	go gui.idle_loop()
	gui.gg.run()
	/*
	for !window.glfw_obj.should_close() {
		if window.child_window != 0 {
			//gg.clear(gx.rgb(230,230,230))
			if window.child_window.draw_fn != voidptr(0) {
				window.child_window.draw_fn(window.child_window.state)
			}
			for child in window.child_window.children {
				child.draw()
			}
		}
		else {
			//gg.clear(window.bg_color)
			// The user can define a custom drawing function for the entire window (advanced mode)
			if window.draw_fn != voidptr(0) {
				window.draw_fn(window.state)
			}
			// Render all widgets, including Canvas
			for child in window.children {
				child.draw()
			}
		}
		// Triggers a re-render in case any function requests it.
		// Transitions & animations, for example.
		if gui.redraw_requested {
			gui.redraw_requested = false
			//glfw.post_empty_event()
		}
		gui.gg.render()
	}
	gui.window.glfw_obj.destroy()
	*/
	gui.closed = true

	// the gui.idle_loop thread checks every 10 ms if gui.closed is true;
	// waiting 2x this time should be enough to ensure the gui.loop
	// thread will exit before us, without using a waitgroup here too
	time.sleep(20 * time.millisecond)
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
