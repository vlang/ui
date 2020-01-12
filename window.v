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
import clipboard

const (
	NR_COLS = 3
	CELL_HEIGHT = 25
	CELL_WIDTH = 100
	TABLE_WIDTH = CELL_WIDTH * NR_COLS
)

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
}

struct UI {
mut:
	gg                   &gg.GG
	ft                   &freetype.FreeType
	window               ui.Window
	show_cursor          bool
	cb_image             u32
	circle_image         u32
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

pub fn new_window(cfg WindowConfig) &Window {
	mut ctx := &UI{
		gg: gg.new_context(gg.Cfg{
			width: cfg.width
			height: cfg.height
			use_ortho: true // This is needed for 2D drawing

			create_window: true
			window_title: cfg.title
			// window_user_ptr: ctx

		})
		ft: freetype.new_context(gg.Cfg{
			width: cfg.width
			height: cfg.height
			use_ortho: true
			font_size: 13
			scale: 2
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
	window := &Window{
		user_ptr: cfg.user_ptr
		ctx: ctx
		glfw_obj: ctx.gg.window
		draw_fn: cfg.draw_fn
	}
	// window.set_cursor()
	return window
}

fn init() {
	glfw.init_glfw()
	stbi.set_flip_vertically_on_load(true)
}

pub fn run(window Window) {
	mut ctx := window.ctx
	ctx.window = window
	go ctx.loop()
	for {
		gg.clear(default_window_color)
		window.draw_fn(window.user_ptr)
		for child in window.children {
			child.draw()
		}
		ctx.gg.render()
	}
}

fn (window &Window) unfocus_all() {
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

fn (w mut Window) focus_next() {
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

fn (w &Window) focus_previous() {
	for i, child in w.children {
		is_focused := child.is_focused()
		if is_focused && i > 0 {
			prev := w.children[i - 1]
			prev.focus()
			// w.children[i - 1].focus()
		}
	}
}

pub fn (w &Window) set_cursor() {
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
}


fn system_font_path() string {
	$if macos {
		dir := '/System/Library/Fonts/'
		if !os.exists(dir + 'SFNS.ttf') {
			return dir + 'SFNSText.ttf'
		}
		return dir + 'SFNS.ttf'
	}
	$if linux {
		return '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
	}
	$if windows {
		return 'C:\\Windows\\Fonts\\arial.ttf'
	}
	panic('font')
}


fn (ctx mut UI) load_icos() {
	// TODO figure out how to use load_from_memory
	mut f := os.create(os.tmpdir() + 'check.png') or {
		panic(err)
	}
	f.write_bytes(bytes_check_png, bytes_check_png_len)
	f.close()
	tmp := os.tmpdir()
	ctx.cb_image = gg.create_image(tmp + 'check.png')
	ctx.circle_image = gg.create_image(tmp + 'circle.png')
	ctx.selected_radio_image = gg.create_image(tmp + 'selected_radio.png')
}

