module ui

import gx
import os

pub enum WMMode {
	subwindow
	free
	tiling
}

[heap]
pub struct WindowManager {
pub mut: // inside an unique sokol Window
	window  &Window = unsafe { nil }
	apps    []Application
	layout  &BoxLayout = unsafe { nil }
	windows []&SubWindow
	kind    WMMode
}

[params]
pub struct WindowManagerParams {
	WindowParams
	scrollview bool
	kind       WMMode
	apps       map[string]Application
}

// ui.Window would play the role of WindowManager

pub fn wm(cfg WindowManagerParams) &WindowManager {
	mut wm := &WindowManager{
		kind: cfg.kind
	}
	wm.layout = box_layout(id: 'wm_layout', scrollview: cfg.scrollview)
	wm.window = window(cfg.WindowParams)
	wm.window.resizable = true
	wm.window.bg_color = gx.orange
	wm.window.title = 'VWM'
	mut bg := rectangle(color: gx.orange)
	wm.layout.set_child_bounding('bg: stretch', mut bg)
	wm.window.children = [wm.layout]
	wm.window.on_init = fn [mut wm] (mut win Window) {
		// last subwindow as active
		if wm.kind == .subwindow {
			mut subw := wm.windows.last()
			subw.as_top_subwindow()
		}
		for mut app in wm.apps {
			if app.on_init != WindowFn(0) {
				app.on_init(win)
			}
		}
		win.update_layout()
	}
	// add declared app
	for key, app in cfg.apps {
		mut mut_app := app
		wm.add(key, mut mut_app)
	}
	return wm
}

pub fn (mut wm WindowManager) run() {
	run(wm.window)
}

pub fn (mut wm WindowManager) add(key string, mut app Application) {
	wm.apps << app
	match wm.kind {
		.subwindow {
			mut subw := subwindow(id: os.join_path(app.id, 'win'), layout: app.layout)
			subw.is_top_wm = true
			wm.window.is_wm_mode = true
			wm.windows << subw
			wm.layout.set_child_bounding(key, mut subw)
		}
		.free, .tiling {
			mut l := app.layout()
			wm.layout.set_child_bounding(key, mut l)
		}
	}
}

pub fn (mut wm WindowManager) add_window_shortcuts(shortcuts map[string]WindowFn) {
	mut sc := Shortcutable(wm.window)
	for shortcut, callback in shortcuts {
		sc.add_shortcut(shortcut, callback)
	}
}

pub fn id(id string, ids ...string) string {
	return os.join_path(id, ...ids)
}
