// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import (
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
	down_arrow           u32
	clipboard            &clipboard.Clipboard
	redraw_requested     bool
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

// TODO rename to `Widget` once interfaces allow that :)
pub interface IWidgeter {
	init(ILayouter)
	//key_down(KeyEvent)
	draw()
	//click(MouseEvent)
	//mouse_move(MouseEvent)
	point_inside(x, y f64) bool
	unfocus()
	focus()
	set_pos(x,y int)
	propose_size(w, h int) (int,int)
	is_focused() bool
}

// TODO rename to `Layouter` once interfaces allow that :)
pub interface ILayouter {
	get_ui() &UI
	get_user_ptr() voidptr
	get_size() (int, int)
	get_subscriber() &eventbus.Subscriber
	//on_click(ClickFn)
	unfocus_all()
	//on_mousemove(MouseMoveFn)
	draw()
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
		// Triggers a re-render in case any function requests it.
		// Transitions & animations, for example.
		if ui.redraw_requested {
			ui.redraw_requested = false
			glfw.post_empty_event()
		}
		ui.gg.render()
	}
}


fn system_font_path() string {
	env_font := os.getenv('VUI_FONT')
	if env_font != '' && os.exists(env_font) {
		return env_font
	}
	$if windows {
		return 'C:\\Windows\\Fonts\\arial.ttf'
	}
	mut fonts := ['Ubuntu-R.ttf', 'Arial.ttf', 'LiberationSans-Regular.ttf', ' NotoSans-Regular.ttf',
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
	ui.down_arrow = gg.create_image( tmp_save_pic(tmp, 'arrow.png', bytes_arrow_png, bytes_arrow_png_len))
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
