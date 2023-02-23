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

// start application (not related to WM)
pub fn (mut app Application) add_window(p WindowParams) {
	// create window
	app.window = window(p)
	app.window.children = [app.layout()]
	app.window.on_init = fn [mut app] (mut win Window) {
		if app.on_init != WindowFn(0) {
			app.on_init(win)
		}
		app.window.update_layout()
	}
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
