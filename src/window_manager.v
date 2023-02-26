module ui

import gx
import os

pub enum WMMode {
	subwindow
	free
}

[heap]
pub struct WindowManager {
pub mut: // inside an unique sokol Window
	window  &Window = unsafe { nil }
	apps    []Application
	layout  &BoxLayout = unsafe { nil }
	windows []&SubWindow
	mode    WMMode
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

pub fn wmf(cfg WindowParams) &WindowManager {
	mut wm_ := wm(cfg)
	wm_.mode = .free
	return wm_
}

pub fn (mut wm WindowManager) run() {
	run(wm.window)
}

pub fn (mut wm WindowManager) add(key string, mut app Application) {
	wm.apps << app
	match wm.mode {
		.subwindow {
			mut subw := subwindow(id: os.join_path(app.id, 'win'), layout: app.layout)
			wm.windows << subw
			wm.layout.set_child_bounding(key, mut subw)
		}
		.free {
			mut l := app.layout()
			wm.layout.set_child_bounding(key, mut l)
		}
	}
}

pub fn id(id string, ids ...string) string {
	return os.join_path(id, ...ids)
}
