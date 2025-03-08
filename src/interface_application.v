module ui

import gg

pub interface Application {
mut:
	id      string
	window  &Window
	layout  &Layout
	on_init WindowFn
}

// Not related to WM only for single app mode
pub fn (mut app Application) add_window(p WindowParams) {
	// create window
	app.window = window(p)
	app.window.children = [app.layout()]
	app.window.on_init = fn [mut app] (mut win Window) {
		// delegate init to window init
		if app.on_init != unsafe { WindowFn(0) } {
			app.on_init(win)
		}
		app.window.update_layout()
	}
}

@[params]
pub struct WindowCallbackParams {
pub:
	on_click         WindowMouseFn     = unsafe { nil }
	on_mouse_down    WindowMouseFn     = unsafe { nil }
	on_mouse_up      WindowMouseFn     = unsafe { nil }
	on_files_dropped WindowMouseFn     = unsafe { nil }
	on_swipe         WindowMouseFn     = unsafe { nil }
	on_mouse_move    WindowMouseMoveFn = unsafe { nil }
	on_key_down      WindowKeyFn       = unsafe { nil }
	on_char          WindowKeyFn       = unsafe { nil }
	on_scroll        WindowScrollFn    = unsafe { nil }
	on_resize        WindowResizeFn    = unsafe { nil }
	on_iconify       WindowFn          = unsafe { nil }
	on_restore       WindowFn          = unsafe { nil }
	on_quit_request  WindowFn          = unsafe { nil }
	on_suspend       WindowFn          = unsafe { nil }
	on_resume        WindowFn          = unsafe { nil }
	on_focus         WindowFn          = unsafe { nil }
	on_unfocus       WindowFn          = unsafe { nil }
}

// add ability to complete app.window callbacks without add_window which is called only in app
pub fn (mut app Application) add_window_callback(p WindowCallbackParams) {
	app.window.click_fn = p.on_click
	app.window.mouse_down_fn = p.on_mouse_down
	app.window.mouse_up_fn = p.on_mouse_up
	app.window.files_dropped_fn = p.on_files_dropped
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

// Specific to external gg application

pub interface GGApplication {
mut:
	gg     &gg.Context
	bounds gg.Rect // bounding box where to draw
	on_init()
	on_draw()
	on_delegate(&gg.Event)
	set_bounds(gg.Rect)
	run()
}
