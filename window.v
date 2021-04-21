// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module ui

import gx
import gg
import clipboard
import eventbus
import time
import math

const (
	default_window_color = gx.rgb(236, 236, 236)
	default_font_size    = 13
)

pub type ClickFn = fn (e MouseEvent, window &Window)

pub type KeyFn = fn (e KeyEvent, func voidptr)

pub type ScrollFn = fn (e ScrollEvent, window &Window)

pub type MouseMoveFn = fn (e MouseMoveEvent, window &Window)

pub type ResizeFn = fn (w int, h int, window &Window)

pub type InitFn = fn (window &Window)

[heap]
pub struct Window {
pub mut:
	// pub:
	ui &UI = voidptr(0)
	// glfw_obj      &glfw.Window = voidptr(0)
	children      []Widget
	child_window  &Window = voidptr(0)
	parent_window &Window = voidptr(0)
	has_textbox   bool // for initial focus
	tab_index     int
	just_tabbed   bool
	state         voidptr
	draw_fn       DrawFn
	title         string
	mx            f64
	my            f64
	width         int
	height        int
	bg_color      gx.Color
	init_fn       InitFn
	click_fn      ClickFn
	mouse_down_fn ClickFn
	mouse_up_fn   ClickFn
	scroll_fn     ScrollFn
	resize_fn     ResizeFn
	key_down_fn   KeyFn
	char_fn       KeyFn
	mouse_move_fn MouseMoveFn
	eventbus      &eventbus.EventBus = eventbus.new()
	// resizable has limitation https://github.com/vlang/ui/issues/231
	resizable   bool // currently only for events.on_resized not modify children
	mode        WindowSizeType
	root_layout Layout
	dpi_scale   f32
	// saved origin sizes
	orig_width  int
	orig_height int
	touch       TouchInfo
	// Text Config
	text_cfg gx.TextCfg
	// drag
	drag_activated bool
	drag_widget    Widget
	drag_start_x   f64
	drag_start_y   f64
	drag_pos_x     f64
	drag_pos_y     f64
	drag_time      time.Time
	// themes
	color_themes ColorThemes
	// widgets register
	widgets        map[string]Widget
	widgets_counts map[string]int
}

pub struct WindowConfig {
pub:
	width                 int
	height                int
	font_path             string
	title                 string
	always_on_top         bool
	state                 voidptr
	draw_fn               DrawFn
	bg_color              gx.Color = ui.default_window_color
	on_init               InitFn
	on_click              ClickFn
	on_mouse_down         ClickFn
	on_mouse_up           ClickFn
	on_key_down           KeyFn
	on_char               KeyFn
	on_scroll             ScrollFn
	on_resize             ResizeFn
	on_mouse_move         MouseMoveFn
	children              []Widget
	custom_bold_font_path string
	native_rendering      bool
	resizable             bool
	mode                  WindowSizeType
	// Text Config
	lines int = 10
}

/*
pub fn window2(cfg WindowConfig) &Window {
	return window(cfg, cfg.children)
}
*/
fn C.sapp_mouse_locked() bool

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
	$if macos {
		if window.ui.gg.native_rendering {
			if e.typ in [.key_down, .mouse_scroll, .mouse_up] {
				C.darwin_window_refresh()
			} else {
				C.darwin_window_refresh()
			}
		}
	}
	window.ui.ticks = 0
	// window.ui.ticks_since_refresh = 0
	// println("on_event: $e.typ")
	match e.typ {
		.mouse_down {
			// println("mouse down")
			window_mouse_down(e, mut window.ui)
			// IMPORTANT: No more need since inside window_handle_tap:
			//  window_click(e, window.ui)
			// touch like
			window.touch.start = {
				pos: {
					x: int(e.mouse_x / window.ui.gg.scale)
					y: int(e.mouse_y / window.ui.gg.scale)
				}
				time: time.now()
			}
		}
		.mouse_up {
			// println('mouseup')
			window_mouse_up(e, mut window.ui)
			// NOT THERE since already done
			// touch-like
			window.touch.end = {
				pos: {
					x: int(e.mouse_x / window.ui.gg.scale)
					y: int(e.mouse_y / window.ui.gg.scale)
				}
				time: time.now()
			}
			window_touch_tap_and_swipe(e, window.ui)
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
		.resized, .restored, .resumed {
			window_resize(e, window.ui)
		}
		.touches_began {
			if e.num_touches > 0 {
				t := e.touches[0]
				window.touch.start = {
					pos: {
						x: int(t.pos_x / window.ui.gg.scale)
						y: int(t.pos_y / window.ui.gg.scale)
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
				window.touch.end = {
					pos: {
						x: int(t.pos_x / window.ui.gg.scale)
						y: int(t.pos_y / window.ui.gg.scale)
					}
					time: time.now()
				}
				window.touch.button = -1
				// println("touch END: ${window.touch.end} $window.touch.button")
				window_touch_up(e, window.ui)
				window_touch_tap_and_swipe(e, window.ui)
			}
		}
		.touches_moved {
			if e.num_touches > 0 {
				t := e.touches[0]
				window.touch.move = {
					pos: {
						x: int(t.pos_x / window.ui.gg.scale)
						y: int(t.pos_y / window.ui.gg.scale)
					}
					time: time.now()
				}
				// println("touch move: ${window.touch.move} $window.touch.button")
				window_touch_move(e, window.ui)
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

fn gg_init(mut window Window) {
	window.dpi_scale = gg.dpi_scale()
	window_size := gg.window_size_real_pixels()
	w := int(f32(window_size.width) / window.dpi_scale)
	h := int(f32(window_size.height) / window.dpi_scale)
	window.width, window.height = w, h
	window.orig_width, window.orig_height = w, h
	// println('gg_init: $w, $h')
	for _, mut child in window.children {
		// println('init $child.type_name()')
		child.init(window)
		window.register_child(*child)
	}
	// refresh the layout
	window.update_layout()
	if window.init_fn != voidptr(0) {
		window.init_fn(window)
	}
}

pub fn window(cfg WindowConfig, children []Widget) &Window {
	/*
	println('window()')
	defer {
		println('end of window()')
	}
	*/

	mut width, mut height := cfg.width, cfg.height
	mut resizable := cfg.resizable
	mut fullscreen := false

	mut sc_size := gg.Size{width, height}

	// before fixing gg_screen_size() for other OS: Linux, Windows
	$if macos {
		sc_size = gg.screen_size()
	}

	match cfg.mode {
		.max_size {
			if sc_size.width > 0 {
				width, height = sc_size.width, sc_size.height
				resizable = true
			}
		}
		.fullscreen {
			if sc_size.width > 10 {
				width, height = sc_size.width, sc_size.height
			}
			fullscreen = true
		}
		.resizable {
			resizable = true
		}
		else {}
	}

	// default text_cfg
	// m := f32(math.min(width, height))

	mut text_cfg := gx.TextCfg{
		color: gx.rgb(38, 38, 38)
		align: gx.align_left
		// size: int(m / cfg.lines)
	}

	// C.printf('window() state =%p \n', cfg.state)
	mut window := &Window{
		state: cfg.state
		draw_fn: cfg.draw_fn
		title: cfg.title
		bg_color: cfg.bg_color
		width: width
		height: height
		// orig_width: width // 800
		// orig_height: height // 600
		children: children
		init_fn: cfg.on_init
		click_fn: cfg.on_click
		key_down_fn: cfg.on_key_down
		char_fn: cfg.on_char
		scroll_fn: cfg.on_scroll
		mouse_move_fn: cfg.on_mouse_move
		mouse_down_fn: cfg.on_mouse_down
		mouse_up_fn: cfg.on_mouse_up
		resizable: resizable
		mode: cfg.mode
		resize_fn: cfg.on_resize
		text_cfg: text_cfg
	}

	// register default color themes
	window.register_default_color_themes()

	mut font_path := ''
	$if android {
		font_path = 'fonts/RobotoMono-Regular.ttf'
	} $else {
		font_path = if cfg.font_path == '' { gg.system_font_path() } else { cfg.font_path }
	}

	gcontext := gg.new_context(
		width: width
		height: height
		use_ortho: true // This is needed for 2D drawing
		create_window: true
		window_title: cfg.title
		resizable: resizable
		fullscreen: fullscreen
		frame_fn: if cfg.native_rendering { native_frame } else { frame }
		// native_frame_fn: native_frame
		event_fn: on_event
		user_data: window
		font_path: font_path
		custom_bold_font_path: cfg.custom_bold_font_path
		init_fn: gg_init
		// keydown_fn: window_key_down
		// char_fn: window_char
		bg_color: cfg.bg_color // gx.rgb(230,230,230)
		// window_state: ui
		native_rendering: cfg.native_rendering
		ui_mode: true
	)
	// wsize := gcontext.window.get_window_size()
	// fsize := gcontext.window.get_framebuffer_size()
	// scale := 2 //if wsize.width == fsize.width { 1 } else { 2 } // detect high dpi displays
	mut ui_ctx := &UI{
		gg: gcontext
		clipboard: clipboard.new()
	}
	ui_ctx.load_icos()
	/*
	ui_ctx.gg.window.set_user_ptr(ui_ctx)
	ui_ctx.gg.window.onkeydown(window_key_down)
	ui_ctx.gg.window.onchar(window_char)
	ui_ctx.gg.window.onmousemove(window_mouse_move)
	ui_ctx.gg.window.on_click(window_click)
	ui_ctx.gg.window.on_resize(window_resize)
	ui_ctx.gg.window.on_scroll(window_scroll)
	*/
	window.ui = ui_ctx

	/*
	mut window := &Window{
		state: cfg.state
		ui: ui_ctx
		//glfw_obj: ui_ctx.gg.window
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
	*/
	// q := int(window)
	// println('created window $q.hex()')

	return window
}

pub fn child_window(cfg WindowConfig, mut parent_window Window, children []Widget) &Window {
	// q := int(parent_window)
	// println('child_window() parent=$q.hex()')
	mut window := &Window{
		parent_window: parent_window
		// state: parent_window.state
		state: cfg.state
		ui: parent_window.ui
		// glfw_obj: parent_window.ui.gg.window
		draw_fn: cfg.draw_fn
		title: cfg.title
		bg_color: cfg.bg_color
		width: cfg.width
		height: cfg.height
		children: children
		click_fn: cfg.on_click
	}
	parent_window.child_window = window
	for _, mut child in window.children {
		// using `parent_window` here so that all events handled by the main window are redirected
		// to parent_window.child_window.child
		child.init(parent_window)
	}
	// window.set_cursor()
	return window
}

/*
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
*/
// fn window_resize(glfw_wnd voidptr, width int, height int) {
fn window_resize(event gg.Event, ui &UI) {
	mut window := ui.window
	$if resize ? {
		println('window resize ($event.window_width ,$event.window_height)')
	}
	if !window.resizable {
		return
	}

	window.resize(event.window_width, event.window_height)
	window.eventbus.publish(events.on_resize, window, voidptr(0))

	if window.resize_fn != voidptr(0) {
		window.resize_fn(event.window_width, event.window_height, window)
	}
}

fn window_mouse_move(event gg.Event, ui &UI) {
	mut window := ui.window
	e := MouseMoveEvent{
		x: event.mouse_x / ui.gg.scale
		y: event.mouse_y / ui.gg.scale
		mouse_button: int(event.mouse_button)
	}
	if window.drag_activated {
		$if drag ? {
			println('drag child ($e.x, $e.y)')
		}
		drag_child(mut window, e.x, e.y)
	}
	if window.mouse_move_fn != voidptr(0) {
		window.mouse_move_fn(e, window)
	}
	window.eventbus.publish(events.on_mouse_move, window, e)
}

fn window_scroll(event gg.Event, ui &UI) {
	window := ui.window
	// println('title =$window.title')
	e := ScrollEvent{
		x: event.scroll_x
		y: event.scroll_y
	}
	if window.scroll_fn != voidptr(0) {
		window.scroll_fn(e, window)
	}
	window.eventbus.publish(events.on_scroll, window, e)
}

fn window_mouse_down(event gg.Event, mut ui UI) {
	window := ui.window
	e := MouseEvent{
		action: .down
		x: int(event.mouse_x / ui.gg.scale)
		y: int(event.mouse_y / ui.gg.scale)
		button: MouseButton(event.mouse_button)
		mods: KeyMod(event.modifiers)
	}
	if int(event.mouse_button) < 3 {
		ui.btn_down[int(event.mouse_button)] = true
	}
	if window.mouse_down_fn != voidptr(0) { // && action == voidptr(0) {
		// window.mouse_down_fn(e, window)
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
		window.eventbus.publish(events.on_mouse_down, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_mouse_down, window, e)
	}
}

fn window_mouse_up(event gg.Event, mut ui UI) {
	mut window := ui.window
	e := MouseEvent{
		action: .up
		x: int(event.mouse_x / ui.gg.scale)
		y: int(event.mouse_y / ui.gg.scale)
		button: MouseButton(event.mouse_button)
		mods: KeyMod(event.modifiers)
	}
	if int(event.mouse_button) < 3 {
		ui.btn_down[int(event.mouse_button)] = false
	}

	if window.drag_activated {
		$if drag ? {
			println('drag child ($e.x, $e.y)')
		}
		drop_child(mut window)
	}

	if window.child_window == 0 && window.mouse_up_fn != voidptr(0) { // && action == voidptr(0) {
		window.mouse_up_fn(e, window)
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
		window.eventbus.publish(events.on_mouse_up, window.child_window, e)
		// window.eventbus.unsubscribe()
	} else {
		window.eventbus.publish(events.on_mouse_up, window, e)
	}
}

fn window_touch_tap_and_swipe(event gg.Event, ui &UI) {
	window := ui.window
	s, e := window.touch.start, window.touch.end
	adx, ady := math.abs(e.pos.x - s.pos.x), math.abs(e.pos.y - s.pos.y)
	if math.max(adx, ady) < 10 {
		window_touch_tap(event, ui)
	} else {
		window_touch_swipe(event, ui)
	}
}

fn window_touch_tap(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseEvent{
		action: MouseAction.up // if event.typ == .mouse_up { MouseAction.up } else { MouseAction.down }
		x: window.touch.end.pos.x
		y: window.touch.end.pos.y
		// button: MouseButton(event.mouse_button)
		// mods: KeyMod(event.modifiers)
	}
	if window.click_fn != voidptr(0) && window.child_window == 0 { // && action == voidptr(0) {
		window.click_fn(e, window)
	}
	if window.child_window != 0 {
		// If there's a child window, use it, so that the widget receives correct user pointer
		window.eventbus.publish(events.on_click, window.child_window, e)
	} else {
		window.eventbus.publish(events.on_click, window, e)
	}
}

fn window_touch_swipe(event gg.Event, ui &UI) {
	// window := ui.window
}

fn window_touch_down(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseEvent{
		x: window.touch.start.pos.x
		y: window.touch.start.pos.y
	}
	if window.mouse_down_fn != voidptr(0) {
		window.mouse_down_fn(e, window)
	}
	window.eventbus.publish(events.on_touch_down, window, e)
}

fn window_touch_up(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseEvent{
		x: window.touch.end.pos.x
		y: window.touch.end.pos.y
	}
	if window.mouse_up_fn != voidptr(0) {
		window.mouse_up_fn(e, window)
	}
	window.eventbus.publish(events.on_touch_up, window, e)
}

fn window_touch_move(event gg.Event, ui &UI) {
	window := ui.window
	e := MouseMoveEvent{
		x: f64(window.touch.move.pos.x)
		y: f64(window.touch.move.pos.y)
		mouse_button: window.touch.button
	}
	if window.mouse_move_fn != voidptr(0) {
		window.mouse_move_fn(e, window)
	}
	window.eventbus.publish(events.on_touch_move, window, e)
}

fn window_click(event gg.Event, ui &UI) {
	window := ui.window
	// println("typ $event.typ")
	e := MouseEvent{
		action: if event.typ == .mouse_up { MouseAction.up } else { MouseAction.down }
		x: int(event.mouse_x / ui.gg.scale)
		y: int(event.mouse_y / ui.gg.scale)
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
}

fn window_key_down(event gg.Event, ui &UI) {
	// println('keydown char=$event.char_code')
	mut window := ui.window
	// C.printf('g child=%p\n', child)
	e := KeyEvent{
		key: Key(event.key_code)
		mods: KeyMod(event.modifiers)
		codepoint: 0 // event.char_code
		// code: code
		// action: action
		// mods: mod
	}
	if e.key == .escape {
		println('escape')
	}
	if e.key == .escape && window.child_window != 0 {
		// Close the child window on Escape
		window.child_window = &Window(0)
	}
	if window.key_down_fn != voidptr(0) {
		window.key_down_fn(e, window.state)
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

// fn window_char(glfw_wnd voidptr, codepoint u32) {
fn window_char(event gg.Event, ui &UI) {
	// println('keychar char=$event.char_code')
	window := ui.window
	e := KeyEvent{
		codepoint: event.char_code
		mods: KeyMod(event.modifiers)
	}
	if window.key_down_fn != voidptr(0) {
		window.key_down_fn(e, window.state)
	}
	window.eventbus.publish(events.on_key_down, window, e)
	if window.char_fn != voidptr(0) {
		window.char_fn(e, window.state)
	}
	// window.eventbus.publish(events.on_char, window, e)
	window.eventbus.publish(events.on_char, window, e)
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

fn (mut w Window) focus_next() {
	mut doit := false
	for mut child in w.children {
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
	for i, mut child in w.children {
		is_focused := child.is_focused()
		if is_focused && i > 0 {
			mut prev := w.children[i - 1]
			prev.focus()
			// w.children[i - 1].focus()
		}
	}
}

pub fn (w &Window) set_cursor(cursor Cursor) {
	// glfw.set_cursor(.ibeam)
	// w.glfw_obj.set_cursor(.ibeam)
}

pub fn (w &Window) close() {
}

pub fn (mut w Window) refresh() {
	// println('ui: window.refres()')
	// w.ui.needs_refresh = true
	w.ui.gg.refresh_ui()
	$if macos {
		C.darwin_window_refresh()
	}
}

pub fn (w &Window) onmousedown(cb voidptr) {
}

pub fn (w &Window) onkeydown(cb voidptr) {
}

pub fn (mut w Window) on_click(func ClickFn) {
	w.click_fn = func
}

pub fn (mut w Window) on_mousemove(func MouseMoveFn) {
	w.mouse_move_fn = func
}

pub fn (mut w Window) on_scroll(func ScrollFn) {
	w.scroll_fn = func
}

pub fn (w &Window) mouse_inside(x int, y int, width int, height int) bool {
	return false
}

pub fn (w &Window) focus() {
}

pub fn (w &Window) always_on_top(val bool) {
}

// TODO remove this once interfaces are smarter
fn foo(w Widget) {
}

fn foo2(l Layout) {
}

fn bar() {
	// foo(&TextBox{
	// 	ui: 0
	// })
	// foo(&Button{
	// 	ui: 0
	// })
	// foo(&ProgressBar{
	// 	ui: 0
	// })
	// foo(&Slider{
	// 	ui: 0
	// })
	// foo(&CheckBox{
	// 	ui: 0
	// })
	// foo(&Label{
	// 	ui: 0
	// })
	// foo(&Radio{
	// 	ui: 0
	// })
	// foo(&Picture{
	// 	ui: 0
	// })
	// foo(&Canvas{})
	// foo(&Menu{
	// 	ui: 0
	// })
	// foo(&Dropdown{
	// 	ui: 0
	// })
	foo(&Transition{
		ui: 0
		animated_value: 0
	})
	// foo(&Stack{
	// 	ui: 0
	// })
	// foo(&Switch{
	// 	ui: 0
	// })
	// foo(&Rectangle{
	// 	ui: 0
	// })
	// foo(&Group{
	// 	ui: 0
	// })
	// foo(&Grid{
	// 	ui: 0
	// })
}

fn (w &Window) draw() {
}

fn frame(mut w Window) {
	// Commented to make timer.v fluid and working on android at the same time
	// if !w.ui.needs_refresh {
	// 	// Draw 3 more frames after the "stop refresh" command
	// 	w.ui.ticks++
	// 	if w.ui.ticks > 3 {
	// 		return
	// 	}
	// }

	// println('frame() needs_refresh=$w.ui.needs_refresh $w.ui.ticks nr children=$w.children.len')
	// game.frame_sw.restart()
	// game.ft.flush()
	w.ui.gg.begin()
	// draw_scene()

	mut children := if w.child_window == 0 { w.children } else { w.child_window.children }

	for mut child in children {
		child.draw()
	}
	w.ui.gg.end()
}

fn native_frame(mut w Window) {
	// println('ui.native_frame()')
	/*
	if !w.ui.needs_refresh {
		// Draw 3 more frames after the "stop refresh" command
		w.ui.ticks++
		if w.ui.ticks > 3 {
			return
		}
	}
	*/
	mut children := if w.child_window == 0 { w.children } else { w.child_window.children }
	// if w.child_window == 0 {
	// Render all widgets, including Canvas
	for mut child in children {
		child.draw()
	}
	//}
	// w.ui.needs_refresh = false
}

// fn C.sapp_macos_get_window() voidptr
fn C.sapp_set_window_title(&char)

// #define cls objc_getClass
// #define sel sel_getUid
#define objc_msg ((id (*)(id, SEL, ...))objc_msgSend)
#define objc_cls_msg ((id (*)(Class, SEL, ...))objc_msgSend)

fn C.objc_msg()

fn C.objc_cls_msg()

fn C.sel_getUid()

fn C.objc_getClass()

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

// Layout Interface Methods
pub fn (w &Window) get_ui() &UI {
	return w.ui
}

pub fn (w &Window) get_state() voidptr {
	return w.state
}

pub fn (w &Window) get_subscriber() &eventbus.Subscriber {
	return w.eventbus.subscriber
}

pub fn (w &Window) size() (int, int) {
	return w.width, w.height
}

fn (mut window Window) resize(w int, h int) {
	window.width, window.height = w, h
	window.ui.gg.resize(w, h)
	for mut child in window.children {
		if mut child is Stack {
			child.resize(w, h)
		}
	}
}

pub fn (window &Window) unfocus_all() {
	// println('window.unfocus_all()')
	for mut child in window.children {
		child.unfocus()
	}
}

pub fn (w &Window) get_children() []Widget {
	return w.children
}

// Experimental: attempt to register child to get it by id from window
fn (mut w Window) register_child(child Widget) {
	if child is Button {
		// println("register Button")
		if child.id == '' {
			mode := 'button'
			w.widgets_counts[mode] += 1
			mut child2 := child
			child2.id = 'ui_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child2.id] = child2
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered $child.id')
			}
		} $else { // required to avoid confusion with next else
		}
	} else if child is ListBox {
		// println("register ListBox")
		if child.id != '' {
			w.widgets[child.id] = child
		}
	} else if child is Label {
		// println("register Label")
		if child.id != '' {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered $child.id')
			}
		} $else {
		}
	} else if mut child is Stack {
		// println("register Stack")
		if child.id == '' {
			mode := if child.direction == .row { 'row' } else { 'column' }
			w.widgets_counts[mode] += 1
			child.id = 'ui_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered $child.id')
			}
		}
		for child2 in child.children {
			w.register_child(child2)
		}
	} else if mut child is Group {
		// println("register Group")
		if child.id == '' {
			mode := 'group'
			w.widgets_counts[mode] += 1
			child.id = 'ui_${mode}_${w.widgets_counts[mode]}'
			w.widgets[child.id] = child
		} else {
			w.widgets[child.id] = child
		}
		$if register ? {
			if child.id != '' {
				println('registered $child.id')
			}
		}
		for child2 in child.children {
			w.register_child(child2)
		}
	}
}

// direct access of registered widget by id
pub fn (w Window) button(id string) &Button {
	widget := w.widgets[id] or { panic('widget with id  $id does not exist') }
	if widget is Button {
		return widget
	} else {
		return button({})
	}
}

pub fn (w Window) label(id string) &Label {
	widget := w.widgets[id] or { panic('widget with id  $id does not exist') }
	if widget is Label {
		return widget
	} else {
		return label({})
	}
}

pub fn (w Window) listbox(id string) &ListBox {
	widget := w.widgets[id] or { panic('widget with id  $id does not exist') }
	if widget is ListBox {
		return widget
	} else {
		return listbox({}, map{})
	}
}

pub fn (w Window) stack(id string) &Stack {
	widget := w.widgets[id] or { panic('widget with id  $id does not exist') }
	if widget is Stack {
		return widget
	} else {
		return stack({}, [])
	}
}

pub fn (w Window) group(id string) &Group {
	widget := w.widgets[id] or { panic('widget with id  $id does not exist') }
	if widget is Group {
		return widget
	} else {
		return group({}, [])
	}
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
						children = widget.children
					} else if widget is Group {
						children = widget.children
					} else if widget is CanvasLayout {
						children = widget.children
					} else {
						eprintln('(ui warning) $from uncorrect: $from[$i]=$ind does not correspond to a Layout')
						root := w.root_layout
						if root is Stack {
							return root
						}
					}
				} else if i == -1 {
					widget := children[children.len - 1]
					if widget is Stack {
						children = widget.children
					} else if widget is Group {
						children = widget.children
					}
				} else {
					eprintln('(ui warning) $from uncorrect: $from[$i]=$ind out of bounds')
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
					eprintln('(ui warning) $from uncorrect: $from[$i]=$ind out of bounds')
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

// ask for an update to restructure the whole children tree from root layout
pub fn (w &Window) update_layout() {
	// update root_layout
	mut s := w.root_layout
	if mut s is Stack {
		s.update_all_children_recursively(w)
	}
}
