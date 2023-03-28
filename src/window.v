// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module ui

import gx
import gg
import clipboard
import eventbus
import time
import math
import os.font
import os

const (
	default_window_color = gx.rgb(236, 236, 236)
	default_font_size    = 13
)

pub type WindowFn = fn (window &Window)

pub type WindowResizeFn = fn (window &Window, w int, h int)

pub type WindowKeyFn = fn (window &Window, e KeyEvent)

pub type WindowMouseFn = fn (window &Window, e MouseEvent)

pub type WindowMouseMoveFn = fn (window &Window, e MouseMoveEvent)

pub type WindowScrollFn = fn (window &Window, e ScrollEvent)

[heap]
pub struct Window {
	id string = '_window_'
pub mut:
	// pub:
	ui                &UI = unsafe { nil }
	children          []Widget
	child_window      &Window = unsafe { nil }
	parent_window     &Window = unsafe { nil }
	has_textbox       bool // for initial focus
	just_tabbed       bool
	title             string
	width             int
	height            int
	no_fullscreen     bool
	click_fn          WindowMouseFn
	mouse_down_fn     WindowMouseFn
	mouse_up_fn       WindowMouseFn
	files_droped_fn   WindowMouseFn
	swipe_fn          WindowMouseFn
	mouse_move_fn     WindowMouseMoveFn
	scroll_fn         WindowScrollFn
	key_down_fn       WindowKeyFn
	char_fn           WindowKeyFn
	resize_fn         WindowResizeFn
	iconified_fn      WindowFn
	restored_fn       WindowFn
	quit_requested_fn WindowFn
	suspended_fn      WindowFn
	resumed_fn        WindowFn
	focused_fn        WindowFn
	unfocused_fn      WindowFn
	on_init           WindowFn
	on_draw           WindowFn
	eventbus          &eventbus.EventBus = eventbus.new()
	resizable         bool // resizable has limitation https://github.com/vlang/ui/issues/231
	mode              WindowSizeType
	root_layout       Layout = empty_stack
	top_layer         CanvasLayout // For absolute coordinates widgets located on top
	dpi_scale         f32
	// saved origin sizes
	orig_width   int
	orig_height  int
	touch        TouchInfo
	mouse        Mouse
	bg_color     gx.Color
	sample_count int
	// Text Config
	text_cfg gx.TextCfg
	// themes
	theme_style  string
	style_params WindowStyleParams
	// widgets register
	widgets        map[string]Widget
	widgets_counts map[string]int
	// drag
	dragger Dragger = Dragger{}
	// tooltip
	tooltip Tooltip = Tooltip{}
	// with message
	native_message bool
	// focus stuff
	do_focus     bool
	locked_focus string
	// event manager
	evt_mngr EventMngr
	// Top subwindows
	subwindows []&SubWindow
	is_wm_mode bool
	// ui mode on gg
	immediate          bool
	children_immediate []Widget
	needs_refresh      bool = true
	// ui settings
	// settings SettingsUI
	// shortcuts
	shortcuts Shortcuts
	mini_calc MiniCalc
	mx        f64 // do not remove this, temporary
	my        f64
}

[params]
pub struct WindowParams {
pub:
	width         int = 800
	height        int = 500
	font_path     string
	title         string = 'V UI window'
	no_fullscreen bool

	bg_color gx.Color = no_color
	theme    string   = 'default'

	on_click              WindowMouseFn
	on_mouse_down         WindowMouseFn
	on_mouse_up           WindowMouseFn
	on_files_droped       WindowMouseFn
	on_swipe              WindowMouseFn
	on_key_down           WindowKeyFn
	on_char               WindowKeyFn
	on_scroll             WindowScrollFn
	on_resize             WindowResizeFn
	on_iconify            WindowFn
	on_restore            WindowFn
	on_quit_request       WindowFn
	on_suspend            WindowFn
	on_resume             WindowFn
	on_focus              WindowFn
	on_unfocus            WindowFn
	on_mouse_move         WindowMouseMoveFn
	on_init               WindowFn
	on_draw               WindowFn
	children              []Widget
	layout                Widget = empty_stack // simplest way to fulfill children
	custom_bold_font_path string
	native_rendering      bool
	resizable             bool
	mode                  WindowSizeType = .resizable
	immediate             bool
	sample_count          int = 4
	// Text Config
	lines int = 10
	// message
	native_message bool = true
	// drag & drop
	enable_dragndrop             bool = true
	max_dropped_files            int  = 5
	max_dropped_file_path_length int  = 2048
}

pub fn window(cfg WindowParams) &Window {
	/*
	println('window()')
	defer {
		println('end of window()')
	}*/

	mut width, mut height := cfg.width, cfg.height
	mut resizable := cfg.resizable || cfg.mode.has(.resizable)
	mut fullscreen := cfg.mode.has(.fullscreen)
	mut no_fullscreen := cfg.no_fullscreen || cfg.mode.has(.no_fullscreen)

	mut sc_size := gg.Size{width, height}

	// before fixing gg_screen_size() for other OS: Linux, Windows
	$if macos {
		sc_size = gg.screen_size()
	}

	if cfg.mode.has(.max_size) {
		if sc_size.width > 0 {
			width, height = sc_size.width, sc_size.height
			resizable = true
		}
	} else if cfg.mode.has(.fullscreen) {
		if sc_size.width > 10 {
			width, height = sc_size.width, sc_size.height
		}
		fullscreen = true
	}

	// default text_cfg
	// m := f32(math.min(width, height))

	mut text_cfg := gx.TextCfg{
		color: gx.rgb(38, 38, 38)
		align: gx.align_left
		// vertical_align: gx.VerticalAlign.middle
		// size: int(m / cfg.lines)
	}

	children := if cfg.children.len == 0 && cfg.layout.id != empty_stack.id
		&& (cfg.layout is Stack || cfg.layout is BoxLayout || cfg.layout is CanvasLayout) {
		[cfg.layout]
	} else {
		cfg.children
	}

	fp := if os.exists(cfg.font_path) { cfg.font_path } else { '' }

	// C.printf(c'window() state =%p \n', cfg.state)
	mut window := &Window{
		title: cfg.title
		width: width
		height: height
		no_fullscreen: no_fullscreen
		theme_style: cfg.theme
		// orig_width: width // 800
		// orig_height: height // 600
		children: children
		on_init: cfg.on_init
		on_draw: cfg.on_draw
		click_fn: cfg.on_click
		key_down_fn: cfg.on_key_down
		char_fn: cfg.on_char
		scroll_fn: cfg.on_scroll
		mouse_move_fn: cfg.on_mouse_move
		mouse_down_fn: cfg.on_mouse_down
		mouse_up_fn: cfg.on_mouse_up
		files_droped_fn: cfg.on_files_droped
		swipe_fn: cfg.on_swipe
		resizable: resizable
		mode: cfg.mode
		resize_fn: cfg.on_resize
		text_cfg: text_cfg
		native_message: cfg.native_message
		immediate: cfg.immediate
		sample_count: cfg.sample_count
		iconified_fn: cfg.on_iconify
		restored_fn: cfg.on_restore
		quit_requested_fn: cfg.on_quit_request
		suspended_fn: cfg.on_suspend
		resumed_fn: cfg.on_resume
		focused_fn: cfg.on_focus
		unfocused_fn: cfg.on_unfocus
	}
	window.style_params.bg_color = cfg.bg_color
	window.top_layer = canvas_layer()
	window.mini_calc = mini_calc()
	mut dd := &DrawDeviceContext{
		Context: gg.new_context(
			width: width
			height: height
			use_ortho: true // This is needed for 2D drawing
			create_window: true // TODO: Unused ?
			window_title: cfg.title
			resizable: resizable
			fullscreen: fullscreen
			frame_fn: if cfg.immediate {
				frame_immediate
			} else if cfg.native_rendering {
				frame_native
			} else {
				frame
			}
			// native_frame_fn: frame_native
			event_fn: on_event
			user_data: window
			font_path: if fp == '' { font.default() } else { fp }
			custom_bold_font_path: cfg.custom_bold_font_path
			init_fn: gg_init
			cleanup_fn: gg_cleanup
			// keydown_fn: window_key_down
			// char_fn: window_char
			bg_color: window.bg_color // gx.rgb(230,230,230)
			// window_state: ui
			native_rendering: cfg.native_rendering
			ui_mode: !cfg.immediate
			// drag & drop
			enable_dragndrop: cfg.enable_dragndrop
			max_dropped_files: cfg.max_dropped_files
			max_dropped_file_path_length: cfg.max_dropped_file_path_length
		)
	}
	mut ui_ctx := &UI{
		dd: dd
		gg: &dd.Context
		window: window
		svg: draw_device_svg()
		bmp: draw_device_bitmap()
		clipboard: clipboard.new()
	}
	ui_ctx.load_imgs()
	ui_ctx.load_styles()
	window.ui = ui_ctx

	// once window and ui created, a build step (before init) can be applied
	window.register_children(mut window.children)
	window.build()

	// q := int(window)
	// println('created window $q.hex()')

	return window
}

pub fn (mut parent_window Window) child_window(cfg WindowParams) &Window {
	// q := int(parent_window)
	// println('child_window() q=$q.hex() parent={parent_window:p} ${cfg.on_draw:p}')

	mut window := &Window{
		parent_window: parent_window
		// state: parent_window.state
		// state: cfg.state
		ui: parent_window.ui
		// glfw_obj: parent_window.ui.gg.window
		// draw_fn: cfg.draw_fn
		on_draw: cfg.on_draw
		title: cfg.title
		bg_color: cfg.bg_color
		width: cfg.width
		height: cfg.height
		children: cfg.children
		click_fn: cfg.on_click
	}
	window.widgets = unsafe { &parent_window.widgets }
	window.widgets_counts = unsafe { &parent_window.widgets_counts }
	parent_window.child_window = window
	window.evt_mngr = unsafe { &parent_window.evt_mngr }
	for _, mut child in window.children {
		// using `parent_window` here so that all events handled by the main window are redirected
		// to parent_window.child_window.child
		parent_window.register_child(*child)
		child.init(parent_window)
	}
	// window.set_cursor()
	return window
}

//----

fn gg_init(mut window Window) {
	window.mouse.init(window)
	window.tooltip.init(window.ui)
	load_settings()
	window.init_text_styles()
	window.load_style()
	$if !screenshot ? {
		window.dpi_scale = gg.dpi_scale()
		window_size := gg.window_size()
		window.width, window.height = window_size.width, window_size.height
		window.orig_width, window.orig_height = window.width, window.height
	}
	// This add experimental ui message system
	if !window.native_message {
		window.add_message_dialog()
	}

	for mut child in window.children {
		// println('init <$child.id>')
		window.register_child(*child)
		child.init(window)
	}
	// then subwindows
	for mut sw in window.subwindows {
		// println('init $child.id')
		window.register_child(*sw)
		sw.init(window)
	}

	// refresh the layout
	window.update_layout()

	// top layer
	window.init_top_layer()

	// last window init
	if window.on_init != WindowFn(0) {
		window.on_init(window)
	}
	// update theme style recursively
	mut l := Layout(window)
	l.update_theme_style(window.theme_style)
}

[manualfree]
fn gg_cleanup(mut window Window) {
	// All the ckeanup goes here
	for mut child in window.children {
		// println('cleanup ${child.id()}')
		child.cleanup()
	}
	unsafe { window.free() }
}

fn frame(mut w Window) {
	if mut w.ui.dd is DrawDeviceContext {
		$if trace_ui_frame ? {
			eprintln('> ${@FN} w.ui.dd.frame: ${w.ui.dd.frame}')
		}
		w.ui.dd.begin()
	}

	// initial clipping
	w.ui.dd.reset_clipping()

	mut children := if unsafe { w.child_window == 0 } {
		w.children
	} else {
		w.child_window.children
	}

	for mut child in children {
		child.draw()
	}

	for mut sw in w.subwindows {
		sw.draw()
	}

	// draw dragger if active
	draw_dragger(mut w)
	// draw tooltip if active
	w.tooltip.draw()

	if w.on_draw != WindowFn(0) {
		w.on_draw(w)
	}

	w.top_layer.draw()

	w.mouse.draw()
	/*
	if w.child_window.on_draw != voidptr(0) {
		println('have child on_draw()')
		w.child_window.on_draw(w.child_window)
	}
	*/

	if mut w.ui.dd is DrawDeviceContext {
		w.ui.dd.end()
	}
}

fn frame_immediate(mut w Window) {
	if mut w.ui.dd is DrawDeviceContext {
		$if trace_ui_frame ? {
			eprintln('> ${@FN} w.ui.dd.frame: ${w.ui.dd.frame}')
		}
		w.ui.dd.begin()
	}

	for mut child in w.children_immediate {
		child.draw()
	}

	if !w.needs_refresh {
		// Draw 3 more frames after the "stop refresh" command
		w.ui.ticks++
		if w.ui.ticks > 3 {
			return
		}
	}

	mut children := if unsafe { w.child_window == 0 } { w.children } else { w.child_window.children }

	for mut child in children {
		child.draw()
	}
	w.tooltip.draw()

	if w.on_draw != WindowFn(0) {
		w.on_draw(w)
	}

	w.needs_refresh = false

	if mut w.ui.dd is DrawDeviceContext {
		w.ui.dd.end()
	}
}

fn frame_native(mut w Window) {
	$if trace_ui_frame ? {
		eprintln('> ${@FN}')
	}

	// println('ui.frame_native()')
	// C.printf(c'w=%p\n', w)
	// println(w)
	/*
	if !w.ui.needs_refresh {
		// Draw 3 more frames after the "stop refresh" command
		w.ui.ticks++
		if w.ui.ticks > 3 {
			return
		}
	}
	*/

	mut children := if unsafe { w.child_window == 0 } { w.children } else { w.child_window.children }
	// if w.child_window == 0 {
	// Render all widgets, including Canvas
	for mut child in children {
		child.draw()
	}
	// println('ui.frame_native() done')
	//}
	// w.ui.needs_refresh = false
}

//----

fn on_event(e &gg.Event, mut window Window) {
	/*
	if false && e.typ != .mouse_move {
		print('window.on_event() $e.typ ') // code=$e.char_code')
		if C.sapp_mouse_locked() {
			println('locked')
		} else {
			println('unlocked')
		}
	}
	*/
	// window.ui.needs_refresh = true
	// window.refresh()

	// delegation
	if window.evt_mngr.has_delegation(e, window.ui) {
		window.eventbus.publish(events.on_delegate, window, e)
		return
	}

	$if macos {
		if mut window.ui.dd is DrawDeviceContext {
			if window.ui.dd.native_rendering {
				C.darwin_window_refresh()
			}
		}
	}
	window.ui.ticks = 0
	// window.ui.ticks_since_refresh = 0
	// println("on_event: $e.typ")
	window.mouse.update_event(e)
	match e.typ {
		.mouse_down {
			// println("mouse down")
			window_mouse_down(e, mut window.ui)
			// IMPORTANT: No more need since inside window_handle_tap:
			//  window_click(e, window.ui)
			// touch like
			prev_time := window.touch.start.time
			window.touch.start = Touch{
				pos: Pos{
					x: int(e.mouse_x / window.dpi_scale)
					y: int(e.mouse_y / window.dpi_scale)
				}
				time: time.now()
			}
			if window.touch.start.time - prev_time < click_interval * time.millisecond {
				window.ui.nb_click += 1
			} else {
				window.ui.nb_click = 1
			}
			// println("nb_click = $window.ui.nb_click")
		}
		.mouse_up {
			// println('mouseup')
			window_mouse_up(e, mut window.ui)
			// NOT THERE since already done
			// touch-like
			window.touch.end = Touch{
				pos: Pos{
					x: int(e.mouse_x / window.dpi_scale)
					y: int(e.mouse_y / window.dpi_scale)
				}
				time: time.now()
			}
			window_click_or_touch_tap_and_swipe(e, window.ui)
		}
		.files_droped {
			window_files_droped(e, mut window.ui)
		}
		.key_down {
			// println('key down')
			window_key_down(e, window.ui)
		}
		.char {
			// println('char')
			window_char(e, window.ui)
		}
		.mouse_scroll {
			window_scroll(e, window.ui)
		}
		.mouse_move {
			// println('mod=$e.modifiers $e.num_touches $e.key_repeat $e.mouse_button')
			window_mouse_move(e, window.ui)
		}
		.resized {
			window_resize(e, window.ui)
		}
		.iconified {
			if window.iconified_fn != WindowFn(0) {
				window.iconified_fn(window)
			}
		}
		.restored {
			if window.restored_fn != WindowFn(0) {
				window.restored_fn(window)
			}
		}
		.focused {
			if window.focused_fn != WindowFn(0) {
				window.focused_fn(window)
			}
		}
		.unfocused {
			if window.unfocused_fn != WindowFn(0) {
				window.unfocused_fn(window)
			}
		}
		.quit_requested {
			if window.quit_requested_fn != WindowFn(0) {
				window.quit_requested_fn(window)
			}
		}
		.suspended {
			if window.suspended_fn != WindowFn(0) {
				window.suspended_fn(window)
			}
		}
		.resumed {
			if window.resumed_fn != WindowFn(0) {
				window.resumed_fn(window)
			}
		}
		.touches_began {
			if e.num_touches > 0 {
				t := e.touches[0]
				window.touch.start = Touch{
					pos: Pos{
						x: int(t.pos_x / window.dpi_scale)
						y: int(t.pos_y / window.dpi_scale)
					}
					time: time.now()
				}
				window.touch.button = 0
				window_touch_down(e, window.ui)
				// println("touch BEGIN: ${window.touch.start} $e")
			}
		}
		.touches_ended {
			if e.num_touches > 0 {
				t := e.touches[0]
				window.touch.end = Touch{
					pos: Pos{
						x: int(t.pos_x / window.dpi_scale)
						y: int(t.pos_y / window.dpi_scale)
					}
					time: time.now()
				}
				window.touch.button = -1
				// println("touch END: ${window.touch.end} $window.touch.button")
				window_touch_up(e, window.ui)
				window_click_or_touch_tap_and_swipe(e, window.ui)
			}
		}
		.touches_moved {
			if e.num_touches > 0 {
				t := e.touches[0]
				window.touch.move = Touch{
					pos: Pos{
						x: int(t.pos_x / window.dpi_scale)
						y: int(t.pos_y / window.dpi_scale)
					}
					time: time.now()
				}
				if e.num_touches > 1 {
					window_touch_scroll(e, window.ui)
				} else {
					// println("touch move: ${window.touch.move} $window.touch.button")
					window_touch_move(e, window.ui)
				}
			}
		}
		else {}
	}
	/*
	if e.typ == .key_down {
		game.key_down(e.key_code)
	}
	*/
}

fn window_resize(event gg.Event, ui &UI) {
	mut window := ui.window
	if !window.resizable {
		return
	}

	window_size := gg.window_size()
	window_width, window_height := window_size.width, window_size.height
	$if resize ? {
		println('window resize (${window_width} ,${window_height})')
	}
	window.resize(window_width, window_height)
	window.eventbus.publish(events.on_resize, window, unsafe { nil })

	if window.resize_fn != WindowResizeFn(0) {
		window.resize_fn(window, window_width, window_height)
	}
}

fn window_key_down(event gg.Event, ui &UI) {
	// println('keydown char=$event.char_code')
	mut window := ui.window
	// C.printf(c'g child=%p\n', child)
	// println('window_keydown $event')
	e := KeyEvent{
		key: Key(event.key_code)
		mods: unsafe { KeyMod(event.modifiers) }
		codepoint: event.char_code
		code: int(event.key_code)
		// action: action
		// mods: mod
	}
	// TODO: [Ctl]+[Tab] and [Ctl]+[Shift]+[Tab] not captured by sokol
	if e.key == .tab {
		if shift_key(e.mods) {
			window.focus_prev()
		} else {
			window.focus_next()
		}
	} else if e.key == .escape {
		// println('escape')
		if unsafe { window.child_window != 0 } {
			// Close the child window on Escape
			for mut child in window.child_window.children {
				// println('cleanup ${child.id()}')
				child.cleanup()
			}
			window.child_window = &Window(0)
		} else {
			if shift_key(e.mods) {
				// draw_device_draw_print('toto.txt', mut window)
				// println("screenshot screenshot-${os.file_name(os.executable())}.svg")
				window.svg_screenshot('screenshot-${os.file_name(os.executable())}.svg')
				window.png_screenshot('screenshot-${os.file_name(os.executable())}.png')
			}
		}
	} else if e.key == .f10 && super_key(e.mods) {
		window.layout_print()
	} else if e.key == .f11 && super_key(e.mods) {
		if !window.no_fullscreen {
			gg.toggle_fullscreen()
			window.update_layout()
		}
	} else {
		// add user shortcuts for window
		key_shortcut(e, window.shortcuts, window)
	}

	if window.key_down_fn != WindowKeyFn(0) {
		window.key_down_fn(window, e)
	}
	// TODO
	if true { // action == 2 || action == 1 {
		window.eventbus.publish(events.on_key_down, window, e)
	} else {
		window.eventbus.publish(events.on_key_up, window, e)
	}
	/*
	for child in window.children {
		is_focused := child.is_focused()
		if !is_focused {
			continue
		}
		child.key_down()
	}
	*/
}

fn window_char(event gg.Event, ui &UI) {
	// println('keychar char=$event.char_code')
	// println("window_char: $event")
	window := ui.window
	e := KeyEvent{
		codepoint: event.char_code
		mods: unsafe { KeyMod(event.modifiers) }
	}
	if window.char_fn != WindowKeyFn(0) {
		window.char_fn(window, e)
	}
	char_shortcut(e, window.shortcuts, window)

	window.eventbus.publish(events.on_char, window, e)
}

fn window_mouse_down(event gg.Event, mut ui UI) {
	// println("typ mouse down $event.typ")
	mut window := ui.window
	e := MouseEvent{
		action: .down
		x: int(event.mouse_x / window.dpi_scale)
		y: int(event.mouse_y / window.dpi_scale)
		button: MouseButton(event.mouse_button)
		mods: unsafe { KeyMod(event.modifiers) }
	}
	ui.keymods = unsafe { KeyMod(event.modifiers) }
	if int(event.mouse_button) < 3 {
		ui.btn_down[int(event.mouse_button)] = true
	}
	if window.mouse_down_fn != WindowMouseFn(0) { // && action == voidptr(0) {
		window.mouse_down_fn(window, e)
	}
	/*
	for child in window.children {
		inside := child.point_inside(x, y) // TODO if ... doesn't work with interface calls
		if inside {
			child.click(e)
		}
	}
	*/

	window.evt_mngr.point_inside_receivers_mouse_event(e, events.on_mouse_down)
	if unsafe { window.child_window != 0 } {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_mouse_down, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_mouse_down, window, e)
	}
}

fn window_mouse_move(event gg.Event, ui &UI) {
	// println("typ mouse move $event.typ")
	mut window := ui.window
	e := MouseMoveEvent{
		x: event.mouse_x / window.dpi_scale
		y: event.mouse_y / window.dpi_scale
		mouse_button: int(event.mouse_button)
	}

	if window.dragger.activated {
		$if drag ? {
			println('drag child (${e.x}, ${e.y})')
		}
		drag_child(mut window, e.x, e.y)
	}

	window.evt_mngr.point_inside_receivers_mouse_move(e)
	if window.mouse_move_fn != WindowMouseMoveFn(0) {
		window.mouse_move_fn(window, e)
	}

	window.tooltip.update(e)

	window.eventbus.publish(events.on_mouse_move, window, e)
}

fn window_mouse_up(event gg.Event, mut ui UI) {
	// println("typ mouse up $event.typ")
	mut window := ui.window
	e := MouseEvent{
		action: .up
		x: int(event.mouse_x / window.dpi_scale)
		y: int(event.mouse_y / window.dpi_scale)
		button: MouseButton(event.mouse_button)
		mods: unsafe { KeyMod(event.modifiers) }
	}

	if unsafe { window.child_window == 0 } && window.mouse_up_fn != WindowMouseFn(0) { // && action == voidptr(0) {
		window.mouse_up_fn(window, e)
	}
	/*
	for child in window.children {
		inside := child.point_inside(x, y) // TODO if ... doesn't work with interface calls
		if inside {
			child.click(e)
		}
	}
	*/
	if unsafe { window.child_window != 0 } {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_mouse_up, window.child_window, e)
		// window.eventbus.unsubscribe()
	} else {
		window.eventbus.publish(events.on_mouse_up, window, e)
	}
	if window.dragger.activated {
		$if drag ? {
			println('drop child (${e.x}, ${e.y})')
		}
		drag_child_dropped(mut window)
	}
	mut gui := unsafe { ui }
	gui.keymods = unsafe { KeyMod(0) }
}

// OBSOLETE see window_click_or_touch_pad
/*
fn window_click(event gg.Event, mut ui UI) {
	window := ui.window
	// println("typ click $event.typ")
	e := MouseEvent{
		action: if event.typ == .mouse_up { MouseAction.up } else { MouseAction.down }
		x: int(event.mouse_x / window.dpi_scale)
		y: int(event.mouse_y / window.dpi_scale)
		button: MouseButton(event.mouse_button)
		mods: KeyMod(event.modifiers)
	}
	if window.click_fn != voidptr(0) { // && action == voidptr(0) {
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
}*/

fn window_scroll(event gg.Event, ui &UI) {
	mut window := ui.window
	// println('title =$window.title')
	e := ScrollEvent{
		mouse_x: event.mouse_x / window.dpi_scale
		mouse_y: event.mouse_y / window.dpi_scale
		x: event.scroll_x / window.dpi_scale
		y: event.scroll_y / window.dpi_scale
	}
	if window.scroll_fn != WindowScrollFn(0) {
		window.scroll_fn(window, e)
	}
	window.evt_mngr.point_inside_receivers_scroll_event(e)
	window.eventbus.publish(events.on_scroll, window, e)
}

fn window_touch_down(event gg.Event, ui &UI) {
	mut window := ui.window
	e := MouseEvent{
		action: .down
		x: window.touch.start.pos.x
		y: window.touch.start.pos.y
	}
	window.evt_mngr.point_inside_receivers_mouse_event(e, events.on_mouse_down)
	if window.mouse_down_fn != WindowMouseFn(0) {
		window.mouse_down_fn(window, e)
	}
	window.eventbus.publish(events.on_touch_down, window, e)
}

fn window_touch_move(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseMoveEvent{
		x: f64(window.touch.move.pos.x)
		y: f64(window.touch.move.pos.y)
		mouse_button: window.touch.button
	}
	if window.mouse_move_fn != WindowMouseMoveFn(0) {
		window.mouse_move_fn(window, e)
	}
	window.eventbus.publish(events.on_touch_move, window, e)
}

fn window_touch_up(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseEvent{
		action: .up
		x: window.touch.end.pos.x
		y: window.touch.end.pos.y
	}
	if window.mouse_up_fn != WindowMouseFn(0) {
		window.mouse_up_fn(window, e)
	}
	window.eventbus.publish(events.on_touch_up, window, e)
}

fn window_click_or_touch_tap(event gg.Event, ui &UI) {
	// println("typ on_tap $event.typ")
	window := ui.window
	e := MouseEvent{
		action: MouseAction.up // if event.typ == .mouse_up { MouseAction.up } else { MouseAction.down }
		x: window.touch.end.pos.x
		y: window.touch.end.pos.y
		// button: MouseButton(event.mouse_button)
		// mods: KeyMod(event.modifiers)
	}
	if window.click_fn != WindowMouseFn(0) && unsafe { window.child_window == 0 } { // && action == voidptr(0) {
		window.click_fn(window, e)
	}
	if unsafe { window.child_window != 0 } {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_click, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_click, window, e)
	}

	mut gui := unsafe { ui }
	if int(event.mouse_button) < 3 {
		gui.btn_down[int(event.mouse_button)] = false
	}
}

fn window_touch_scroll(event gg.Event, ui &UI) {
	mut window := ui.window
	// println('title =$window.title')
	s, m := window.touch.start, window.touch.move
	adx, ady := m.pos.x - s.pos.x, m.pos.y - s.pos.y
	e := ScrollEvent{
		mouse_x: f64(m.pos.x)
		mouse_y: f64(m.pos.y)
		x: f64(adx) / 30.0
		y: f64(ady) / 30.0
	}
	window.touch.start = window.touch.move
	if window.scroll_fn != WindowScrollFn(0) {
		window.scroll_fn(window, e)
	}
	window.eventbus.publish(events.on_scroll, window, e)
}

fn window_touch_swipe(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseEvent{
		action: MouseAction.up // if event.typ == .mouse_up { MouseAction.up } else { MouseAction.down }
		x: window.touch.end.pos.x
		y: window.touch.end.pos.y
		// button: MouseButton(event.mouse_button)
		// mods: KeyMod(event.modifiers)
	}
	if window.swipe_fn != WindowMouseFn(0) && unsafe { window.child_window == 0 } { // && action == voidptr(0) {
		window.swipe_fn(window, e)
	}
	if unsafe { window.child_window != 0 } {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_swipe, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_swipe, window, e)
	}
	mut gui := unsafe { ui }
	if int(event.mouse_button) < 3 {
		gui.btn_down[int(event.mouse_button)] = false
	}
}

fn window_click_or_touch_tap_and_swipe(event gg.Event, ui &UI) {
	window := ui.window
	s, e := window.touch.start, window.touch.end
	adx, ady := math.abs(e.pos.x - s.pos.x), math.abs(e.pos.y - s.pos.y)
	if math.max(adx, ady) < 10 {
		window_click_or_touch_tap(event, ui)
	} else {
		window_touch_swipe(event, ui)
	}
}

fn window_files_droped(event gg.Event, mut ui UI) {
	mut window := ui.window
	e := MouseEvent{
		action: .down
		x: int(event.mouse_x / window.dpi_scale)
		y: int(event.mouse_y / window.dpi_scale)
		button: MouseButton(event.mouse_button)
		mods: unsafe { KeyMod(event.modifiers) }
	}
	if window.files_droped_fn != WindowMouseFn(0) { // && action == voidptr(0) {
		window.files_droped_fn(window, e)
	}
	// window.evt_mngr.point_inside_receivers_mouse_event(e, events.on_files_droped)
	if unsafe { window.child_window != 0 } {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_files_droped, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_files_droped, window, e)
	}
}

//----

pub fn (mut w Window) set_title(title string) {
	w.title = title
	/*
	$if macos {
		x := C.sapp_macos_get_window()
		C.objc_msg(x, C.sel_getUid("setTitle:"), C.objc_cls_msg(C.objc_getClass("NSString"),
			C.sel_getUid("stringWithUTF8String:"),"Pure C App"))
		println('SETTING')
		#[nsw setTitlee:"test string"];
	}
	*/
	C.sapp_set_window_title(title.str)
}

pub fn (mut w Window) refresh() {
	w.ui.refresh()
}

pub fn (w &Window) mouse_inside(x int, y int, width int, height int) bool {
	return false
}

pub fn (mut w Window) on_click(func WindowMouseFn) {
	w.click_fn = func
}

pub fn (mut w Window) on_mousemove(func WindowMouseMoveFn) {
	w.mouse_move_fn = func
}

pub fn (mut w Window) on_scroll(func WindowScrollFn) {
	w.scroll_fn = func
}

// extract child widget in the children tree by indexes
pub fn (w &Window) child(from ...int) Widget {
	if from.len > 0 {
		mut children := w.root_layout.get_children()
		for i, ind in from {
			if i < from.len - 1 {
				if ind >= 0 && ind < children.len {
					widget := children[ind]
					if widget is Stack {
						children = widget.children.clone()
					} else if widget is Group {
						children = widget.children.clone()
					} else if widget is CanvasLayout {
						children = widget.children.clone()
					} else {
						eprintln('(ui warning) ${from} uncorrect: ${from}[${i}]=${ind} does not correspond to a Layout')
						root := w.root_layout
						if root is Stack {
							return root
						}
					}
				} else if i == -1 {
					widget := children[children.len - 1]
					if widget is Stack {
						children = widget.children.clone()
					} else if widget is Group {
						children = widget.children.clone()
					}
				} else {
					eprintln('(ui warning) ${from} uncorrect: ${from}[${i}]=${ind} out of bounds')
					root := w.root_layout
					if root is Stack {
						return root
					}
				}
			} else {
				if ind >= 0 && ind < children.len {
					return children[ind]
				} else if ind == -1 {
					return children[children.len - 1]
				} else {
					eprintln('(ui warning) ${from} uncorrect: ${from}[${i}]=${ind} out of bounds')
				}
			}
		}
	}
	// by default returns root_layout
	// expected when `from` is empty
	root := w.root_layout
	if root is Stack {
		return root
	} else {
		// required but never goes here
		return &Stack{
			ui: 0
		}
	}
}

pub fn (w &Window) is_registred(widget &Widget) bool {
	return widget.id in w.widgets
}

[unsafe]
pub fn (w &Window) free() {
	$if free ? {
		println('window ${w.title}')
	}
	unsafe {
		w.ui.free()
		w.children.free()
		w.title.free()
		// w.eventbus.free()
		w.widgets.free()
		w.widgets_counts.free()
		w.tooltip.free()
		free(w)
	}
	$if free ? {
		println('window -> freed')
	}
}

//----  Layout Interface Methods

pub fn (w &Window) get_ui() &UI {
	return w.ui
}

pub fn (w &Window) size() (int, int) {
	return w.width, w.height
}

pub fn (w &Window) get_children() []Widget {
	return w.children
}

pub fn (w &Window) get_subscriber() &eventbus.Subscriber {
	return w.eventbus.subscriber
}

pub fn (mut window Window) resize(w int, h int) {
	window.width, window.height = w, h
	if mut window.ui.dd is DrawDeviceContext {
		window.ui.dd.resize(w, h)
	}
	for mut child in window.children {
		if mut child is Stack {
			child.resize(w, h)
		}
		if mut child is CanvasLayout {
			child.resize(w, h)
		}
		if mut child is BoxLayout {
			child.resize(w, h)
		}
	}
}

// ask for an update to restructure the whole children tree from root layout
pub fn (w &Window) update_layout() {
	// update root_layout
	mut r := w.root_layout
	if mut r is Stack {
		if r.id != empty_stack.id {
			$if root_layout ? {
				println('Stack ${r.id} as root layout')
			}
			r.update_layout()
		}
	} else if mut r is CanvasLayout {
		$if root_layout ? {
			println('CanvasLayout ${r.id} as root layout')
		}
		r.update_layout()
	} else if mut r is BoxLayout {
		$if root_layout ? {
			println('BoxLayout ${r.id} as root layout')
		}
		r.update_layout()
	}
}

pub fn (w &Window) update_layout_without_pos() {
	// update root_layout
	mut s := w.root_layout
	if mut s is Stack {
		if s.id != empty_stack.id {
			s.update_layout_without_pos()
		}
	}
}

fn (w &Window) draw() {}

//---- Window focusable methods

pub fn (w &Window) unlocked_focus() bool {
	$if focus ? {
		println('locked focus = <${w.locked_focus}>')
	}
	return w.locked_focus == ''
}

fn (mut w Window) focus_next() {
	w.do_focus = false
	if !Layout(w).set_focus_next() {
		Layout(w).set_focus_first()
	}
}

fn (mut w Window) focus_prev() {
	w.do_focus = false
	if !Layout(w).set_focus_prev() {
		Layout(w).set_focus_last()
	}
}

pub fn (w &Window) minimize() {
	$if macos {
		x := C.sapp_macos_get_window()
		C.vui_minimize_window(x)
	}
}

//---- unused

pub fn (w &Window) set_cursor(cursor Cursor) {}

pub fn (w &Window) onmousedown(cb voidptr) {}

pub fn (w &Window) close() {}

//---- child widgets

pub fn (mut w Window) register_children(mut children []Widget) {
	for mut child in children {
		// println('init <$child.id>')
		w.register_child(*child)
	}
}

// Register child to be obtained by id from window
pub fn (mut w Window) register_child(child_ Widget) {
	mut child := unsafe { child_ }
	if mut child is Button {
		// println("register Button")
		if child.id == '' {
			mode := 'btn'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered ${child.id}')
			}
		} $else { // required to avoid confusion with next else
		}
	} else if mut child is Canvas {
		if child.id == '' {
			mode := 'can'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is CheckBox {
		if child.id == '' {
			mode := 'cb'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Dropdown {
		if child.id == '' {
			mode := 'dd'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Grid {
		if child.id == '' {
			mode := 'grid'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Label {
		// println("register Label")
		if child.id == '' {
			mode := 'lab'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is ListBox {
		if child.id == '' {
			mode := 'lb'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Menu {
		if child.id == '' {
			mode := 'menu'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Picture {
		if child.id == '' {
			mode := 'pic'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is ProgressBar {
		if child.id == '' {
			mode := 'pb'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Radio {
		if child.id == '' {
			mode := 'rad'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Rectangle {
		if child.id == '' {
			mode := 'rec'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Slider {
		if child.id == '' {
			mode := 'sli'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Switch {
		if child.id == '' {
			mode := 'swi'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is TextBox {
		if child.id == '' {
			mode := 'tb'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Transition {
		if child.id == '' {
			mode := 'tra'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	} else if mut child is Stack {
		// println("register Stack")
		if child.id == '' {
			mode := if child.direction == .row { 'row' } else { 'col' }
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered ${child.id}')
			}
		}
		for child2 in child.children {
			w.register_child(child2)
		}
	} else if mut child is Group {
		// println("register Group")
		if child.id == '' {
			mode := 'gr'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered ${child.id}')
			}
		}
		for child2 in child.children {
			w.register_child(child2)
		}
	} else if mut child is CanvasLayout {
		// println("register CanvasLayout")
		if child.id == '' {
			mode := 'cl'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered ${child.id}')
			}
		}
		for child2 in child.children {
			w.register_child(child2)
		}
	} else if mut child is BoxLayout {
		// println("register CanvasLayout")
		if child.id == '' {
			mode := 'gl'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered ${child.id}')
			}
		}
		for child2 in child.children {
			w.register_child(child2)
		}
	} else if mut child is SubWindow {
		if child.id == '' {
			mode := 'sw'
			w.widgets_counts[mode] += 1
			child.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered ${child.id}')
			}
		}
		if child.layout is Widget {
			l := child.layout as Widget
			w.register_child(l)
		}
	} else {
		if child.id == '' {
			mode := 'unknown'
			w.widgets_counts[mode] += 1
			mut u := child
			u.id = '_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
	}
}

pub fn (w &Window) calculate(formula string) f32 {
	mut mc := w.mini_calc
	return mc.calculate(formula)
}

// get_or_panic returns the widget with the given id and type,
// or does panic if the widget is not found or the widget with the given id is of a different type.
// Example: w.get_or_panic[ui.Button]('send_button')
pub fn (w &Window) get_or_panic[T](id string) &T {
	return w.get[T](id) or { panic(err) }
}

// get returns the widget with the given id and type,
// or an error if the widget is not found or the widget with the given id is of a different type.
// Example: get[ui.Button]('send_button') or { create_button('send_button') }
pub fn (w &Window) get[T](id string) !&T {
	widget := w.widgets[id] or { return error('Widget with id `${id}` does not exist') }

	if widget is T {
		return widget
	} else {
		return error('Widget with id `${id}` is not a ${T.name} but a ${typeof(widget).name}')
	}
}

// direct access of registered widget by id
[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) button(id string) &Button {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Button {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Button', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) label(id string) &Label {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Label {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Label', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) listbox(id string) &ListBox {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is ListBox {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.ListBox', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) dropdown(id string) &Dropdown {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Dropdown {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Dropdown', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) textbox(id string) &TextBox {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is TextBox {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.TextBox', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) radio(id string) &Radio {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Radio {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Radio', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) slider(id string) &Slider {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Slider {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Slider', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) checkbox(id string) &CheckBox {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is CheckBox {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.CheckBox', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) stack(id string) &Stack {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Stack {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Stack', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) group(id string) &Group {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Group {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Group', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) canvas_layout(id string) &CanvasLayout {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is CanvasLayout {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.CanvasLayout', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) menu(id string) &Menu {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Menu {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Menu', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) rectangle(id string) &Rectangle {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is Rectangle {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.Rectangle', widget.type_name())
	}
}

[deprecated: 'use get_or_panic() instead']
[deprecated_after: '2023-01-20']
pub fn (w &Window) subwindow(id string) &SubWindow {
	widget := w.widgets[id] or { panic('widget with id `${id}` does not exist') }
	if widget is SubWindow {
		return widget
	} else {
		panic_widget_type_mismatch(id, 'ui.SubWindow', widget.type_name())
	}
}

[noreturn]
fn panic_widget_type_mismatch(id string, expected_type string, actual_type string) {
	panic('widget `${id}` is not a ${expected_type} but a ${actual_type}')
}

pub fn (w &Window) run() {
	run(w)
}

pub fn (mut w Window) svg_screenshot(filename string) {
	mut d := w.ui.svg
	d.screenshot_window(filename, mut w)
}

pub fn (mut w Window) png_screenshot(filename string) {
	mut d := w.ui.bmp
	d.png_screenshot_window(filename, mut w)
}

pub fn (mut w Window) layout_print() {
	mut d := draw_device_print()
	w.ui.layout_print = true
	mut dd := DrawDevice(d)
	dd.draw_window(mut w)
	w.ui.layout_print = false
}
