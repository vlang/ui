// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import (
	gx
	glfw
	stbi
	time
	gg
	os
	filepath
)

pub struct UI {
mut:
	gg                   &gg.GG
	ft                   &freetype.FreeType
	window               ui.Window
	show_cursor          bool
	cb_image             u32
	//circle_image         u32
	radio_image          u32
	selected_radio_image u32
	clipboard            &clipboard.Clipboard
}

// TODO rename to `Widget` once interfaces allow that :)
pub interface IWidgeter {
	key_down(KeyEvent)
	draw()
	click(MouseEvent)
	point_inside(x, y f64) bool
	unfocus()
	focus()
	idx() int
	is_focused() bool
}

pub struct KeyEvent {
	key       ui.Key
	action    int
	code      int
	mods      ui.KeyMod
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
	glfw.init_glfw()
	stbi.set_flip_vertically_on_load(true)
}

fn (ui mut UI) loop() {
	for {
		time.sleep_ms(500)
		ui.show_cursor = !ui.show_cursor
		glfw.post_empty_event()
	}
}


pub fn run(window ui.Window) {
	mut ui := window.ui
	ui.window = window
	go ui.loop()
	for !window.glfw_obj.should_close() {
		gg.clear(window.bg_color)//default_window_color)
		// The user can define a custom drawing function for the entire window (advanced mode)
		if window.draw_fn != 0 {
			window.draw_fn(window.user_ptr)
		}
		// Render all widgets, including Canvas
		for child in window.children {
			child.draw()
		}
		ui.gg.render()
	}
}


fn system_font_path() string {
	env_font := os.getenv('VUI_FONT')
	if env_font.len != 0 {
		return env_font
	}
	$if macos {
		dir := '/System/Library/Fonts/'
		if !os.exists(dir + 'SFNS.ttf') {
			return dir + 'SFNSText.ttf'
		}
		return dir + 'SFNS.ttf'
	}
	$if linux {
		searched_fonts := [
			'/usr/share/fonts/truetype/msttcorefonts/Arial.ttf',
			'/usr/share/fonts/truetype/ubuntu-font-family/Ubuntu-R.ttf',
			'/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
			'/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
			'/usr/share/fonts/truetype/freefont/FreeSans.ttf',
			'/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
			'/usr/share/fonts/dejavu/DejaVuSans.ttf'		// for Fedora 31
			]
		for f in searched_fonts {
			if os.exists( f ) {
				return f
			}
		}
		panic('Please install at least one of: $searched_fonts .')
	}
	$if windows {
		return 'C:\\Windows\\Fonts\\arial.ttf'
	}
	panic('failed to init the font')
}

fn (ui mut UI) load_icos() {
	// TODO figure out how to use load_from_memory
	tmp := filepath.join( os.tmpdir() , 'v_ui' ) + os.path_separator
	if !os.is_dir( tmp ) {
		os.mkdir( tmp ) or {
			panic(err)
		}
	}
	ui.cb_image     = gg.create_image( tmp_save_pic(tmp, 'check.png',   bytes_check_png,  bytes_check_png_len) )
	/*
	$if macos {
		ui.circle_image = gg.create_image(tmp_save_pic(tmp, 'circle.png',  bytes_darwin_circle_png,
			bytes_darwin_circle_png_len))
	} $else {
		ui.circle_image = gg.create_image(tmp_save_pic(tmp, 'circle.png',  bytes_circle_png,
			bytes_circle_png_len))
	}
	*/
	ui.selected_radio_image = gg.create_image( tmp_save_pic(tmp, 'selected_radio.png', bytes_selected_radio_png, bytes_selected_radio_png_len) )
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
