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

const (
	default_window_color = gx.rgb(236, 236, 236)
)

pub type DrawFn fn(voidptr)

pub struct Window {
mut:
	glfw_obj    &glfw.Window
	ui &UI
	children    []IWidgeter
	has_textbox bool // for initial focus
	tab_index   int
	just_tabbed bool
	user_ptr    voidptr
	draw_fn     DrawFn
	title string
	mx int
	my int
	width int
	height int
	bg_color gx.Color
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
	bg_color gx.Color = default_window_color
}

pub fn new_window(cfg WindowConfig) &ui.Window {
	gcontext := gg.new_context(gg.Cfg{
		width: cfg.width
		height: cfg.height
		use_ortho: true // This is needed for 2D drawing
		create_window: true
		window_title: cfg.title
		// window_user_ptr: ui
	})
	wsize := gcontext.window.get_window_size()
	fsize := gcontext.window.get_framebuffer_size()
	scale := if wsize.width == fsize.width { 1 } else { 2 } // detect high dpi displays
	mut ui_ctx := &UI{
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
	ui_ctx.load_icos()
	ui_ctx.gg.window.set_user_ptr(ui_ctx)
	ui_ctx.gg.window.onkeydown(gkey_down)
	ui_ctx.gg.window.onchar(onchar)
	ui_ctx.gg.window.on_click(onclick)
	window := &ui.Window{
		user_ptr: cfg.user_ptr
		ui: ui_ctx
		glfw_obj: ui_ctx.gg.window
		draw_fn: cfg.draw_fn
		title: cfg.title
		bg_color: cfg.bg_color
	}
	// window.set_cursor()
	return window
}

fn (window &ui.Window) unfocus_all() {
	for child in window.children {
		child.unfocus()
	}
}

fn onclick(glfw_wnd voidptr, button, action, mods int) {
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
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

fn gkey_down(glfw_wnd voidptr, key, code, action, mods int) {
	// println("key down")
	if action != 2 && action != 1 {
		return
	}
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
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
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
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

pub fn (w &ui.Window) set_cursor(cursor Cursor) {
	// glfw.set_cursor(.ibeam)
	// w.glfw_obj.set_cursor(.ibeam)
}

pub fn (w &ui.Window) close() {
}

pub fn (w &ui.Window) refresh() {
}

pub fn (w &ui.Window) onmousedown(cb voidptr) {
}
pub fn (w &ui.Window) onkeydown(cb voidptr) {
	}

pub fn (w &ui.Window) mouse_inside(x, y, width, height int) bool {
	return false
}

pub fn (b &Window) focus() {
}
pub fn (b &Window) always_on_top(val bool) {
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

pub fn (w mut ui.Window) set_title(title string) {

}

