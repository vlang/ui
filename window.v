// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import glfw
import time
import freetype
import stbi
import os
import filepath
import clipboard

pub type DrawFn fn(voidptr)

pub struct Window {
mut:
	glfw_obj    &glfw.Window
	ctx         &UI
	children    []IWidgeter
	has_textbox bool // for initial focus
	tab_index   int
	just_tabbed bool
	user_ptr    voidptr
	draw_fn     DrawFn
	title string
}

struct UI {
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

pub struct WindowConfig {
pub:
	width         int
	height        int
	resizable     bool
	title         string
	always_on_top bool
	user_ptr      voidptr
	draw_fn       DrawFn
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

struct KeyEvent {
	key       ui.Key
	action    int
	code      int
	mods      ui.KeyMod
	codepoint u32
}

struct MouseEvent {
	x      int
	y      int
	button int
	action int
	mods   int
}

pub fn new_window(cfg WindowConfig) &ui.Window {
	gcontext := gg.new_context(gg.Cfg{
		width: cfg.width
		height: cfg.height
		use_ortho: true // This is needed for 2D drawing
		create_window: true
		window_title: cfg.title
		// window_user_ptr: ctx
	})
	wsize := gcontext.window.get_window_size()
	fsize := gcontext.window.get_framebuffer_size()
	scale := if wsize.width == fsize.width { 1 } else { 2 } // detect high dpi displays
	mut ctx := &UI{
		gg: gcontext
		ft: freetype.new_context(gg.Cfg{
			width: cfg.width
			height: cfg.height
			use_ortho: true
			font_size: 13
			scale: scale
			window_user_ptr: 0
			font_path: system_font_path()
		})
		clipboard: clipboard.new()
	}
	ctx.load_icos()
	ctx.gg.window.set_user_ptr(ctx)
	ctx.gg.window.onkeydown(gkey_down)
	ctx.gg.window.onchar(onchar)
	ctx.gg.window.on_click(onclick)
	window := &ui.Window{
		user_ptr: cfg.user_ptr
		ctx: ctx
		glfw_obj: ctx.gg.window
		draw_fn: cfg.draw_fn
		title: cfg.title
	}
	// window.set_cursor()
	return window
}

fn init() {
	glfw.init_glfw()
	stbi.set_flip_vertically_on_load(true)
}

pub fn run(window ui.Window) {
	mut ctx := window.ctx
	ctx.window = window
	go ctx.loop()
	for !window.glfw_obj.should_close() {
		gg.clear(default_window_color)
		if window.draw_fn != 0 {
			window.draw_fn(window.user_ptr)
		}
		for child in window.children {
			child.draw()
		}
		ctx.gg.render()
	}
}

fn (window &ui.Window) unfocus_all() {
	for child in window.children {
		child.unfocus()
	}
}

fn onclick(glfw_wnd voidptr, button, action, mods int) {
	ctx := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ctx.window
	x,y := glfw.get_cursor_pos(glfw_wnd)
	for child in window.children {
		q := child.point_inside(x, y) // TODO if ... doesn't work with interface calls
		if q {
			child.click(MouseEvent{
				button: button
				action: action
				mods: mods
				x: int(x)
				y: int(y)
			})
		}
	}
}

fn (ctx mut UI) loop() {
	for {
		time.sleep_ms(500)
		ctx.show_cursor = !ctx.show_cursor
		glfw.post_empty_event()
	}
}

fn gkey_down(glfw_wnd voidptr, key, code, action, mods int) {
	// println("key down")
	if action != 2 && action != 1 {
		return
	}
	ctx := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ctx.window
	// C.printf('g child=%p\n', child)
	for child in window.children {
		is_focused := child.is_focused()
		if !is_focused {
			continue
		}
		child.key_down(KeyEvent{
			key: key
			code: code
			action: action
			mods: mods
		})
	}
}

fn onchar(glfw_wnd voidptr, codepoint u32) {
	ctx := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ctx.window
	for child in window.children {
		is_focused := child.is_focused()
		if !is_focused {
			continue
		}
		child.key_down(KeyEvent{
			codepoint: codepoint
		})
	}
}

fn (w mut ui.Window) focus_next() {
	mut doit := false
	for child in w.children {
		// Focus on the next widget
		if doit {
			child.focus()
			break
		}
		is_focused := child.is_focused()
		if is_focused {
			doit = true
		}
	}
	w.just_tabbed = true
}

fn (w &ui.Window) focus_previous() {
	for i, child in w.children {
		is_focused := child.is_focused()
		if is_focused && i > 0 {
			prev := w.children[i - 1]
			prev.focus()
			// w.children[i - 1].focus()
		}
	}
}

pub fn (w &ui.Window) set_cursor() {
	// glfw.set_cursor(.ibeam)
	// w.glfw_obj.set_cursor(.ibeam)
}

// TODO remove this
fn foo(w IWidgeter) {}

fn bar() {
	foo(&TextBox{})
	foo(&Button{})
	foo(&ProgressBar{})
	foo(&CheckBox{})
	foo(&Label{})
	foo(&Radio{})
	foo(&Picture{})
	foo(&Canvas{})
	foo(&Menu{})
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

fn (ctx mut UI) load_icos() {
	// TODO figure out how to use load_from_memory
	tmp := filepath.join( os.tmpdir() , 'v_ui' ) + os.path_separator
	if !os.is_dir( tmp ) {
		os.mkdir( tmp ) or {
			panic(err)
		}
	}
	ctx.cb_image     = gg.create_image( tmp_save_pic(tmp, 'check.png',   bytes_check_png,  bytes_check_png_len) )
	/*
	$if macos {
		ctx.circle_image = gg.create_image(tmp_save_pic(tmp, 'circle.png',  bytes_darwin_circle_png,
			bytes_darwin_circle_png_len))
	} $else {
		ctx.circle_image = gg.create_image(tmp_save_pic(tmp, 'circle.png',  bytes_circle_png,
			bytes_circle_png_len))
	}
	*/
	ctx.selected_radio_image = gg.create_image( tmp_save_pic(tmp, 'selected_radio.png', bytes_selected_radio_png, bytes_selected_radio_png_len) )
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
