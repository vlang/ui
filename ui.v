// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import glfw
import stbi
import time
import gg
import os
import freetype
import clipboard
import eventbus
import gx

const (
	version = '0.0.2'
)

pub struct UI {
pub:
	ft                   &freetype.FreeType
	gg                   &gg.GG
mut:
	window               &Window
	show_cursor          bool
	cb_image             u32
	//circle_image         u32
	radio_image          u32
	selected_radio_image u32
	down_arrow           u32
	clipboard            &clipboard.Clipboard
	redraw_requested     bool
	resource_cache       map[string]u32
	closed               bool = false
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
	top int
	left int
	right int
	bottom int
}

pub interface Widget {
	init(Layout)
	//key_down(KeyEvent)
	draw()
	//click(MouseEvent)
	//mouse_move(MouseEvent)
	point_inside(x, y f64) bool
	unfocus()
	focus()
	set_pos(x,y int)
	propose_size(w, h int) (int,int)
	size() (int, int)
	is_focused() bool
}
//pub fn iwidget(x Widget) Widget { return x }

pub interface Layout {
	get_ui() &UI
	get_user_ptr() voidptr
	size() (int, int)
	get_subscriber() &eventbus.Subscriber
	//on_click(ClickFn)
	unfocus_all()
	//on_mousemove(MouseMoveFn)
	draw()
	resize(w,h int)
}
pub fn ilayout(x Layout) Layout { return x }

pub struct KeyEvent {
pub:
	key       Key
	action    int
	code      int
	mods      KeyMod
	codepoint u32
}

pub struct MouseEvent {
pub:
	x      int
	y      int
	button int
	action int
	mods   int
}

pub enum Cursor {
	hand
	arrow
	ibeam
}

fn init() {
	println('ui.init()')
	glfw.init_glfw()
	stbi.set_flip_vertically_on_load(true)
}

fn (ui mut UI) idle_loop() {
	// This method is called by window.run to ensure
	// that the window will be redrawn slowly, and that
	// the cursor will blink at a rate of 1Hz, even if
	// there are no other user events.
	for {
		ui.show_cursor = !ui.show_cursor
		glfw.post_empty_event()

		// Sleeping for a monolithic block of 500ms means, that the thread
		// in which this method is run, may react to the closing of a dialog
		// 500ms after the button for closing the dialog/window was clicked.
		// Instead, we sleep 50 times, for just 10ms each time, checking
		// in between the sleeps, whether the dialog window had been closed.
		// This guarantees that the thread will exit at most 10ms after the
		// closing event.
		for i:=0; i<50; i++ {
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
	for !window.glfw_obj.should_close() {
		if window.child_window != 0 {
			gg.clear(gx.rgb(230,230,230))
			for child in window.child_window.children {
				child.draw()
			}
		}
		else {
			gg.clear(window.bg_color)
			// The user can define a custom drawing function for the entire window (advanced mode)
			if window.draw_fn != 0 {
				window.draw_fn(window.user_ptr)
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
			glfw.post_empty_event()
		}
		ui.gg.render()
	}
	ui.window.glfw_obj.destroy()
	ui.closed = true
	// the ui.idle_loop thread checks every 10 ms if ui.closed is true;
	// waiting 2x this time should be enough to ensure the ui.loop
	// thread will exit before us, without using a waitgroup here too
	time.sleep_ms(20)
}


fn system_font_path() string {
	env_font := os.getenv('VUI_FONT')
	if env_font != '' && os.exists(env_font) {
		return env_font
	}
	$if windows {
		return 'C:\\Windows\\Fonts\\arial.ttf'
	}
	mut fonts := ['Ubuntu-R.ttf', 'Arial.ttf', 'LiberationSans-Regular.ttf', 'NotoSans-Regular.ttf',
	'FreeSans.ttf', 'DejaVuSans.ttf']
	$if macos {
		fonts = ['SFNS.ttf', 'SFNSText.ttf']
	}
	s := os.exec('fc-list') or { panic('failed to fetch system fonts') }
	system_fonts := s.output.split('\n')
	for line in system_fonts {
		for font in fonts {
			if line.contains(font) && line.contains(':') {
				res := line.all_before(':')
				println('Using font $res')
				return res
			}
		}
	}
	panic('failed to init the font')
}

fn (ui mut UI) load_icos() {
	// TODO figure out how to use load_from_memory
	tmp := os.join_path(os.temp_dir() , 'v_ui') + os.path_separator
	if !os.is_dir(tmp) {
		os.mkdir(tmp) or {
			panic(err)
		}
	}
	ui.cb_image = gg.create_image(tmp_save_pic(tmp, 'check.png',   bytes_check_png,  bytes_check_png_len))
	/*
	$if macos {
		ui.circle_image = gg.create_image(tmp_save_pic(tmp, 'circle.png',  bytes_darwin_circle_png,
			bytes_darwin_circle_png_len))
	} $else {
		ui.circle_image = gg.create_image(tmp_save_pic(tmp, 'circle.png',  bytes_circle_png,
			bytes_circle_png_len))
	}
	*/
	ui.down_arrow = gg.create_image(tmp_save_pic(tmp, 'arrow.png', bytes_arrow_png, bytes_arrow_png_len))
	ui.selected_radio_image = gg.create_image(tmp_save_pic(tmp, 'selected_radio.png', bytes_selected_radio_png, bytes_selected_radio_png_len))
}

fn tmp_save_pic(tmp string, picname string, bytes byteptr, bytes_len int) string {
	tmp_path := tmp + picname
	mut f := os.create( tmp_path ) or {
		panic(err)
	}
	f.write_bytes(bytes, bytes_len)
	f.close()
	return tmp_path
}

pub fn open_url(url string) {

}

pub fn confirm(s string) bool {
	return false
}
