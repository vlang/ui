module ui

import os
import gx

[heap]
pub struct WindowManager {
pub mut: // inside an unique sokol Window
	window  &Window = unsafe { nil }
	apps    []Application
	layout  &BoxLayout = unsafe { nil }
	windows []&SubWindow
}

// ui.Window would play the role of WindowManager

pub fn wm(cfg WindowParams) &WindowManager {
	mut wm := &WindowManager{}
	wm.layout = box_layout(id: 'wm_layout')
	wm.window = window(cfg)
	wm.window.resizable = true
	wm.window.bg_color = gx.orange
	wm.window.title = 'VWM'
	mut bg := rectangle(color: gx.orange)
	wm.layout.set_child_bounding('bg: stretch', mut bg)
	wm.window.children = [wm.layout]
	wm.window.on_init = fn [mut wm] (mut win Window) {
		for mut app in wm.apps {
			if app.on_init != WindowFn(0) {
				app.on_init(win)
			}
		}
		win.update_layout()
	}
	return wm
}

pub fn (mut wm WindowManager) run() {
	run(wm.window)
}

pub fn (mut wm WindowManager) add(key string, mut app Application) {
	wm.apps << app
	mut subw := subwindow(id: os.join_path(app.id, 'win'), layout: app.layout)
	wm.windows << subw
	wm.layout.set_child_bounding(key, mut subw)
}

pub interface Application {
mut:
	id string
	window &Window
	layout &Layout
	on_init WindowFn
}

// Not related to WM only for single app mode
pub fn (mut app Application) add_window(p WindowParams) {
	// create window
	app.window = window(p)
	app.window.children = [app.layout()]
	app.window.on_init = fn [mut app] (mut win Window) {
		// delegate init to window init
		if app.on_init != WindowFn(0) {
			app.on_init(win)
		}
		app.window.update_layout()
	}
}

[params]
pub struct WindowCallbackParams {
	on_click        WindowMouseFn
	on_mouse_down   WindowMouseFn
	on_mouse_up     WindowMouseFn
	on_files_droped WindowMouseFn
	on_swipe        WindowMouseFn
	on_mouse_move   WindowMouseMoveFn
	on_key_down     WindowKeyFn
	on_char         WindowKeyFn
	on_scroll       WindowScrollFn
	on_resize       WindowResizeFn
	on_iconify      WindowFn
	on_restore      WindowFn
	on_quit_request WindowFn
	on_suspend      WindowFn
	on_resume       WindowFn
	on_focus        WindowFn
	on_unfocus      WindowFn
}

// add ability to complete app.window callbacks without add_window which is called only in app
pub fn (mut app Application) add_window_callback(p WindowCallbackParams) {
	app.window.click_fn = p.on_click
	app.window.mouse_down_fn = p.on_mouse_down
	app.window.mouse_up_fn = p.on_mouse_up
	app.window.files_droped_fn = p.on_files_droped
	app.window.swipe_fn = p.on_swipe
	app.window.mouse_move_fn = p.on_mouse_move
	app.window.key_down_fn = p.on_key_down
	app.window.char_fn = p.on_char
	app.window.scroll_fn = p.on_scroll
	app.window.resize_fn = p.on_resize
	app.window.iconified_fn = p.on_iconify
	app.window.restored_fn = p.on_restore
	app.window.quit_requested_fn = p.on_quit_request
	app.window.suspended_fn = p.on_suspend
	app.window.resumed_fn = p.on_resume
	app.window.focused_fn = p.on_focus
	app.window.unfocused_fn = p.on_unfocus
}

// start application (not related to WM)
pub fn (mut app Application) run() {
	if app.window == unsafe { nil } {
		app.add_window()
	}
	// run window
	run(app.window)
}

// return Application layout as a Widget
pub fn (mut app Application) layout() Widget {
	if app.layout is Widget {
		layout := app.layout as Widget
		return layout
	} else {
		return empty_stack
	}
}
