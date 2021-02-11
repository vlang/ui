// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import time
import gg
import os
import clipboard
import eventbus

// import gx
// import sokol.sapp
const (
	version = '0.0.4'
)

const (
	cursor_show_delay = 100 // ms
)

pub struct UI {
pub mut:
	gg &gg.Context = voidptr(0)
mut:
	window      &Window = voidptr(0)
	show_cursor bool
	// just_typed           bool
	last_type_time       i64
	cb_image             gg.Image
	circle_image         gg.Image
	radio_image          gg.Image
	selected_radio_image gg.Image
	down_arrow           gg.Image
	clipboard            &clipboard.Clipboard
	redraw_requested     bool
	resource_cache       map[string]gg.Image
	closed               bool
	needs_refresh        bool = true
	ticks                int
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

pub struct MarginConfig {
	top    int
	left   int
	right  int
	bottom int
}

pub interface Widget {
	init(Layout)
	// key_down(KeyEvent)
	draw()
	// click(MouseEvent)
	// mouse_move(MouseEvent)
	point_inside(x f64, y f64) bool
	unfocus()
	focus()
	set_pos(x int, y int)
	propose_size(w int, h int) (int, int)
	size() (int, int)
	is_focused() bool
	name() string
}

// pub fn iwidget(x Widget) Widget { return x }
pub interface Layout {
	spacing int
	get_ui() &UI
	get_state() voidptr
	size() (int, int)
	get_subscriber() &eventbus.Subscriber
	// on_click(ClickFn)
	unfocus_all()
	// on_mousemove(MouseMoveFn)
	draw()
	resize(w int, h int)
	get_children() []Widget
}

pub fn ilayout(x Layout) Layout {
	return x
}

pub enum MouseAction {
	up
	down
}

// MouseButton is same to sapp.MouseButton
pub enum MouseButton {
	invalid = -1
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
	x f64
	y f64
}

pub struct MouseMoveEvent {
pub:
	x            f64
	y            f64
	mouse_button int // TODO enum
}

pub enum Cursor {
	hand
	arrow
	ibeam
}

fn (mut ui UI) idle_loop() {
	// This method is called by window.run to ensure
	// that the window will be redrawn slowly, and that
	// the cursor will blink at a rate of 1Hz, even if
	// there are no other user events.
	for {
		if time.ticks() - ui.last_type_time < cursor_show_delay {
			// Always show the cursor if the user is typing right now
			ui.show_cursor = true
		} else {
			ui.show_cursor = !ui.show_cursor
		}
		ui.needs_refresh = true
		$if macos {
			if ui.gg.native_rendering {
				C.darwin_window_refresh()
			}
		}
		ui.ticks = 0
		// glfw.post_empty_event()
		// Sleeping for a monolithic block of 500ms means, that the thread
		// in which this method is run, may react to the closing of a dialog
		// 500ms after the button for closing the dialog/window was clicked.
		// Instead, we sleep 50 times, for just 10ms each time, checking
		// in between the sleeps, whether the dialog window had been closed.
		// This guarantees that the thread will exit at most 10ms after the
		// closing event.
		for i := 0; i < 50; i++ {
			time.sleep_ms(10)
			if ui.closed {
				return
			}
		}
	}
}

pub fn run(window &Window) {
	mut ui := window.ui
	ui.window = window
	go ui.idle_loop()
	ui.gg.run()
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
		if ui.redraw_requested {
			ui.redraw_requested = false
			//glfw.post_empty_event()
		}
		ui.gg.render()
	}
	ui.window.glfw_obj.destroy()
	*/
	ui.closed = true
	// the ui.idle_loop thread checks every 10 ms if ui.closed is true;
	// waiting 2x this time should be enough to ensure the ui.loop
	// thread will exit before us, without using a waitgroup here too
	time.sleep_ms(20)
}

fn (mut ui UI) load_icos() {
	ui.cb_image = ui.gg.create_image_from_memory(bytes_check_png, bytes_check_png_len)
	$if macos {
		ui.circle_image = ui.gg.create_image_from_memory(bytes_darwin_circle_png, bytes_darwin_circle_png_len)
	} $else {
		ui.circle_image = ui.gg.create_image_from_memory(bytes_circle_png, bytes_circle_png_len)
	}
	ui.down_arrow = ui.gg.create_image_from_memory(bytes_arrow_png, bytes_arrow_png_len)
	ui.selected_radio_image = ui.gg.create_image_from_memory(bytes_selected_radio_png,
		bytes_selected_radio_png_len)
}

pub fn open_url(url string) {
	if !url.starts_with('https://') && !url.starts_with('http://') {
		return
	}
	$if macos {
		os.exec('open "$url"') or { return }
	}
	$if linux {
		os.exec('xdg-open "$url"') or { return }
	}
}

pub fn confirm(s string) bool {
	return false
}
