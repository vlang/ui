// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import oldgg as gg
import glfw
import freetype
import clipboard
import eventbus

const (
	default_window_color = gx.rgb(236, 236, 236)
	default_font_size = 13
)

pub type DrawFn fn(voidptr)

pub type ClickFn fn(e MouseEvent, func voidptr)
pub type KeyFn fn(e KeyEvent, func voidptr)

pub type ScrollFn fn(e ScrollEvent, func voidptr)

pub type MouseMoveFn fn(e MouseEvent, func voidptr)

[ref_only]
pub struct Window {
pub:
	ui            &UI = voidptr(0)
pub mut:
	glfw_obj      &glfw.Window = voidptr(0)
	children      []Widget
	child_window  &Window = voidptr(0)
	parent_window &Window = voidptr(0)
	has_textbox   bool // for initial focus
	tab_index     int
	just_tabbed   bool
	state      voidptr
	draw_fn       DrawFn
	title         string
	mx            int
	my            int
	width         int
	height        int
	bg_color      gx.Color
	click_fn      ClickFn
	scroll_fn     ScrollFn
	key_down_fn     KeyFn
	mouse_move_fn MouseMoveFn
	eventbus      &eventbus.EventBus = eventbus.new()
}

pub struct WindowConfig {
pub:
	width         int
	height        int
	resizable     bool
	title         string
	always_on_top bool
	state      voidptr
	draw_fn       DrawFn
	bg_color      gx.Color=default_window_color
	on_click ClickFn
	on_key_down KeyFn
	on_scroll ScrollFn
	children []Widget
//pub mut:
	//parent_window &Window
}

/*
pub fn window2(cfg WindowConfig) &Window {
	return window(cfg, cfg.children)
}
*/

pub fn window(cfg WindowConfig, children []Widget) &Window {
	println('window()')
	fpath := system_font_path()
	gcontext := gg.new_context(gg.Cfg{
		width: cfg.width
		height: cfg.height
		use_ortho: true // This is needed for 2D drawing

		create_window: true
		window_title: cfg.title
		resizable: cfg.resizable
		// window_state: ui

	})
	wsize := gcontext.window.get_window_size()
	fsize := gcontext.window.get_framebuffer_size()
	scale := if wsize.width == fsize.width { 1 } else { 2 } // detect high dpi displays
	ft := freetype.new_context(gg.Cfg{
			width: cfg.width
			height: cfg.height
			use_ortho: true
			font_size: default_font_size
			scale: scale
			window_user_ptr: 0
			font_path: fpath
		})
	mut ui_ctx := &UI{
		gg: gcontext
		ft: ft
		clipboard: clipboard.new()
	}
	ui_ctx.load_icos()
	ui_ctx.gg.window.set_user_ptr(ui_ctx)
	ui_ctx.gg.window.onkeydown(window_key_down)
	ui_ctx.gg.window.onchar(window_char)
	ui_ctx.gg.window.onmousemove(window_mouse_move)
	ui_ctx.gg.window.on_click(window_click)
	ui_ctx.gg.window.on_resize(window_resize)
	ui_ctx.gg.window.on_scroll(window_scroll)
	mut window := &Window{
		state: cfg.state
		ui: ui_ctx
		glfw_obj: ui_ctx.gg.window
		draw_fn: cfg.draw_fn
		title: cfg.title
		bg_color: cfg.bg_color
		width: cfg.width
		height: cfg.height
		children: children
		click_fn: cfg.on_click
		key_down_fn: cfg.on_key_down
		scroll_fn: cfg.on_scroll
	}
	//q := int(window)
	//println('created window $q.hex()')
	for _, child in window.children {
		//if child is Stack {

		//}
		/*
		match child {
			Stack {
				println('column')
			}
			TextBox {
				println('textbox')
			}
			else{}
		}
		*/
		child.init(window)
	}
	// window.set_cursor()
	return window
}

pub fn child_window(cfg WindowConfig, mut parent_window  Window, children []Widget) &Window {
	//q := int(parent_window)
	//println('child_window() parent=$q.hex()')
	mut window := &Window{
		parent_window: parent_window
		//state: parent_window.state
		state: cfg.state
		ui: parent_window.ui
		glfw_obj: parent_window.ui.gg.window
		draw_fn: cfg.draw_fn
		title: cfg.title
		bg_color: cfg.bg_color
		width: cfg.width
		height: cfg.height
		children: children
		click_fn: cfg.on_click
	}
	parent_window.child_window = window
	for _, child in window.children {
		// using `parent_window` here so that all events handled by the main window are redirected
		// to parent_window.child_window.child
		child.init(parent_window)
	}
	// window.set_cursor()
	return window
}

fn window_mouse_move(glfw_wnd voidptr, x, y f64) {
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	mut window := ui.window
	x0,y0 := glfw.get_cursor_pos(glfw_wnd)
	window.mx = int(x0)
	window.my = int(y0)
	e := MouseEvent{
		x: int(x0)
		y: int(y0)
	}
	/* if window.mouse_move_fn != 0 {
		window.mouse_move_fn(e, &ui.window)
	}
	for child in window.children {
		inside := child.point_inside(x, y) // TODO if ... doesn't work with interface calls
		if inside {
			child.mouse_move(e)
		}
	} */

	window.eventbus.publish(events.on_mouse_move, &window, e)
}

fn window_resize(glfw_wnd voidptr, width int, height int) {
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
	window.resize(width, height)
}

fn window_scroll(glfw_wnd voidptr, xoff, yoff f64) {
	//println('window scroll')
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
	//println('title =$window.title')
	e := ScrollEvent{
		xoff: xoff
		yoff: yoff
	}
	if window.scroll_fn != voidptr(0) {
		window.scroll_fn(e, window)
	}
	window.eventbus.publish(events.on_scroll, window, e)
}

fn window_click(glfw_wnd voidptr, button, action, mods int) {
	//if action != 0 {
		//return
	//}
	//println('action=$action')
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
	x,y := glfw.get_cursor_pos(glfw_wnd)
	e := MouseEvent{
		button: button
		action: action
		mods: mods
		x: int(x)
		y: int(y)
	}
	if window.click_fn != voidptr(0) && action == voidptr(0) {
		window.click_fn(e, window)
	}
	/*
	for child in window.children {
		inside := child.point_inside(x, y) // TODO if ... doesn't work with interface calls
		if inside {
			child.click(e)
		}
	}
	*/

	if window.child_window != 0 {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_click, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_click, window, e)
	}
}

fn window_key_down(glfw_wnd voidptr, key, code, action, mods int) {
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
	// C.printf('g child=%p\n', child)
	e := KeyEvent{
		key: key
		code: code
		action: action
		mods: mods
	}
	if e.key == .escape && window.child_window != 0 {
		// Close the child window on Escape
		window.child_window = 0
	}
	if window.key_down_fn != voidptr(0) {
		window.key_down_fn(e, window)
	}
	if action == 2 || action == 1 {
		window.eventbus.publish(events.on_key_down, window, e)
	}
	else {
		window.eventbus.publish(events.on_key_up, window, e)
	}
	/* for child in window.children {
		is_focused := child.is_focused()
		if !is_focused {
			continue
		}
		child.key_down()
	} */

}

fn window_char(glfw_wnd voidptr, codepoint u32) {
	ui := &UI(glfw.get_window_user_pointer(glfw_wnd))
	window := ui.window
	e := KeyEvent{
		codepoint: codepoint
	}
	window.eventbus.publish(events.on_key_down, &window, e)
	/* for child in window.children {
		is_focused := child.is_focused()
		if !is_focused {
			continue
		}
		child.key_down()
	} */

}

fn (mut w Window) focus_next() {
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

pub fn (w &Window) set_cursor(cursor Cursor) {
	// glfw.set_cursor(.ibeam)
	// w.glfw_obj.set_cursor(.ibeam)
	}

pub fn (w &Window) close() {}

pub fn (w &Window) refresh() {}

pub fn (w &Window) onmousedown(cb voidptr) {}

pub fn (w &Window) onkeydown(cb voidptr) {}

pub fn (mut w Window) on_click(func ClickFn) {
	w.click_fn = func
}

pub fn (mut w Window) on_mousemove(func MouseMoveFn) {
	w.mouse_move_fn = func
}

pub fn (mut w Window) on_scroll(func ScrollFn) {
	w.scroll_fn = func
}

pub fn (w &Window) mouse_inside(x, y, width, height int) bool {
	return false
}

pub fn (b &Window) focus() {}

pub fn (w &Window) always_on_top(val bool) {
	//w.glfw_obj.window_hint(
}

// TODO remove this
fn foo(w Widget) {}

fn foo2(l Layout) {}

fn bar() {
	foo(&TextBox{ui: 0})
	foo(&Button{ui: 0})
	foo(&ProgressBar{ui: 0})
	foo(&Slider{ui: 0})
	foo(&CheckBox{ui: 0})
	foo(&Label{ui: 0})
	foo(&Radio{ui: 0})
	foo(&Picture{ui: 0})
	foo(&Canvas{})
	foo(&Menu{ui: 0})
	foo(&Dropdown{ui: 0})
	foo(&Transition{
		ui: 0
		animated_value: 0
	})
	foo(&Stack{ui: 0})
	foo(&Switch{ui: 0})
	foo(&Rectangle{ui: 0})
	foo(&Group{ui: 0})
}

fn bar2() {
	foo2(&Window{
		ui: 0
		glfw_obj: 0
		eventbus: eventbus.new()
	})
	foo2(&Stack{ui: 0})
}

fn (w &Window) draw() {
/*
	// Render all widgets, including Canvas
	for child in w.children {
		child.draw()
	}
	if w.child_window != 0 {
		for child in w.child_window.children {
			child.draw()
		}
	}
	*/
}

pub fn (mut w Window) set_title(title string) {
	w.title = title
	w.glfw_obj.set_title(title)
}
//Layout Interface Methods



fn (w &Window) get_ui() &UI {
	return w.ui
}

fn (w &Window) get_state() voidptr {
	return w.state
}

pub fn (w &Window) get_subscriber() &eventbus.Subscriber {
	return w.eventbus.subscriber
}

fn (w &Window) size() (int,int) {
	return w.width,w.height
}

fn (window &Window) resize(width, height int) {}

fn (window &Window) unfocus_all() {
	for child in window.children {
		child.unfocus()
	}
}
