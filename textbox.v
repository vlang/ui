// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import time
// import sokol.sapp

enum SelectionDirection {
	nil = 0
	left_to_right
	right_to_left
}

const (
	text_border_color             = gx.rgb(177, 177, 177)
	text_inner_border_color       = gx.rgb(240, 240, 240)
	text_border_accentuated_color = gx.rgb(255, 0, 0)
	textbox_padding_x             = 5
	textbox_padding_y             = 2
	// selection_color = gx.rgb(226, 233, 241)
	selection_color               = gx.rgb(186, 214, 251)
)

type TextBoxKeyDownFn = fn (voidptr, &TextBox, u32)

type TextBoxCharFn = fn (voidptr, &TextBox, u32)

// type KeyUpFn = fn (voidptr, voidptr, u32)

type TextBoxChangeFn = fn (string, voidptr)

type TextBoxEnterFn = fn (string, voidptr)

[heap]
pub struct TextBox {
pub mut:
	id         string
	height     int
	width      int
	x          int
	y          int
	offset_x   int
	offset_y   int
	z_index    int
	parent     Layout = empty_stack
	is_focused bool
	// gg &gg.GG
	ui &UI = 0
	// text               string
	text        &string = voidptr(0)
	max_len     int
	line_height int
	cursor_pos  int
	sel_start   int
	sel_end     int
	// placeholder
	placeholder      string
	placeholder_bind &string = voidptr(0)
	// multiline mode
	is_multiline bool
	tv           TextView
	is_wordwrap  bool
	is_sync      bool // if true lines are computed from text when drawing
	twosided_sel bool // if true extension selection is made from both sides
	// others
	is_numeric    bool
	is_password   bool
	read_only     bool
	borderless    bool
	fitted_height bool // if true fit height in propose_size
	on_key_down   TextBoxKeyDownFn = TextBoxKeyDownFn(0)
	on_char       TextBoxCharFn    = TextBoxCharFn(0)
	// on_key_up          KeyUpFn   = KeyUpFn(0)
	is_selectable      bool // for read_only textbox
	sel_active         bool // to deal with show cursor when selection active
	dragging           bool
	sel_direction      SelectionDirection
	border_accentuated bool
	is_error           &bool = voidptr(0)
	on_change          TextBoxChangeFn = TextBoxChangeFn(0)
	on_enter           TextBoxEnterFn  = TextBoxEnterFn(0)
	// related to text drawing
	text_cfg  gx.TextCfg
	text_size f64
	hidden    bool
	// component state for composable widget
	component voidptr
	// scrollview
	has_scrollview   bool
	scrollview       &ScrollView = 0
	on_scroll_change ScrollViewChangedFn = ScrollViewChangedFn(0)
mut:
	is_typing bool
}

pub struct TextBoxConfig {
	id               string
	width            int
	height           int = 22
	is_multiline     bool
	is_wordwrap      bool
	is_sync          bool
	twosided_sel     bool
	z_index          int
	min              int
	max              int
	val              int
	placeholder      string
	placeholder_bind &string = voidptr(0)
	max_len          int
	is_numeric       bool
	is_password      bool
	read_only        bool
	text             &string = voidptr(0)
	is_error         &bool   = voidptr(0)
	is_focused       bool
	// is_error bool
	borderless    bool
	fitted_height bool
	on_key_down   TextBoxKeyDownFn
	on_char       TextBoxCharFn
	// on_key_up          KeyUpFn
	on_change          voidptr
	on_enter           voidptr
	border_accentuated bool
	text_cfg           gx.TextCfg
	text_size          f64
	// added when user set text after declaration but before init (see colorbox component)
	text_after       bool
	scrollview       bool
	on_scroll_change ScrollViewChangedFn = ScrollViewChangedFn(0)
}

pub fn textbox(c TextBoxConfig) &TextBox {
	mut tb := &TextBox{
		id: c.id
		height: c.height
		width: if c.width < 30 { 30 } else { c.width }
		z_index: c.z_index
		// sel_start_i: 0
		placeholder: c.placeholder
		placeholder_bind: c.placeholder_bind
		// TODO is_focused: !c.parent.has_textbox // focus on the first textbox in the window by default
		is_numeric: c.is_numeric
		is_password: c.is_password
		max_len: c.max_len
		read_only: c.read_only
		borderless: c.borderless
		on_key_down: c.on_key_down
		on_char: c.on_char
		// on_key_up: c.on_key_up
		on_change: c.on_change
		on_enter: c.on_enter
		border_accentuated: c.border_accentuated
		ui: 0
		text: c.text
		is_focused: c.is_focused
		is_error: c.is_error
		text_cfg: c.text_cfg
		text_size: c.text_size
		is_multiline: c.is_multiline
		is_wordwrap: c.is_wordwrap
		fitted_height: c.fitted_height || c.is_multiline
		is_sync: c.is_sync
		twosided_sel: c.twosided_sel
		on_scroll_change: c.on_scroll_change
	}
	if c.text == 0 && !c.text_after {
		panic('textbox.text binding is not set')
	}
	if c.scrollview {
		scrollview_add(mut tb)
	}
	return tb
}

fn (mut tb TextBox) init(parent Layout) {
	tb.parent = parent
	ui := parent.get_ui()
	tb.ui = ui
	if is_empty_text_cfg(tb.text_cfg) && tb.text_size == 0 {
		tb.text_cfg = tb.ui.window.text_cfg
	}
	update_text_size(mut tb)
	// TODO: Maybe in a method later to allow font size update
	tb.update_line_height()

	if tb.is_multiline {
		tb.tv.init(tb)
	}
	if has_scrollview(tb) {
		tb.scrollview.init(parent)
		scrollview_update(tb)
	}
	// return widget
	mut subscriber := parent.get_subscriber()
	// subscriber.subscribe_method(events.on_click, tb_click, tb)
	subscriber.subscribe_method(events.on_key_down, tb_key_down, tb)
	subscriber.subscribe_method(events.on_char, tb_char, tb)
	// subscriber.subscribe_method(events.on_key_up, tb_key_up, tb)
	subscriber.subscribe_method(events.on_mouse_down, tb_mouse_down, tb)
	subscriber.subscribe_method(events.on_mouse_move, tb_mouse_move, tb)
	subscriber.subscribe_method(events.on_mouse_up, tb_mouse_up, tb)
}

[manualfree]
fn (mut tb TextBox) cleanup() {
	mut subscriber := tb.parent.get_subscriber()
	// subscriber.unsubscribe_method(events.on_click, tb)
	subscriber.unsubscribe_method(events.on_key_down, tb)
	subscriber.unsubscribe_method(events.on_char, tb)
	// subscriber.unsubscribe_method(events.on_key_up, tb)
	subscriber.unsubscribe_method(events.on_mouse_down, tb)
	subscriber.unsubscribe_method(events.on_mouse_move, tb)
	subscriber.unsubscribe_method(events.on_mouse_up, tb)
	unsafe { tb.free() }
}

[unsafe]
pub fn (tb &TextBox) free() {
	$if free ? {
		print('textbox $tb.id')
	}
	unsafe {
		tb.id.free()
		tb.placeholder.free()
		free(tb)
	}
	$if free ? {
		println(' -> freed')
	}
}

// fn (tb &TextBox) draw_inner_border() {
fn draw_inner_border(border_accentuated bool, gg &gg.Context, x int, y int, width int, height int, is_error bool) {
	if !border_accentuated {
		color := if is_error { gx.rgb(255, 0, 0) } else { ui.text_border_color }
		gg.draw_empty_rect(x, y, width, height, color)
		// gg.draw_empty_rect(tb.x, tb.y, tb.width, tb.height, color) //ui.text_border_color)
		// TODO this should be +-1, not 0.5, a bug in gg/opengl
		gg.draw_empty_rect(0.5 + f32(x), 0.5 + f32(y), width - 1, height - 1, ui.text_inner_border_color) // inner lighter border
	} else {
		gg.draw_empty_rect(x, y, width, height, ui.text_border_accentuated_color)
		gg.draw_empty_rect(1.5 + f32(x), 1.5 + f32(y), width - 3, height - 3, ui.text_border_accentuated_color) // inner lighter border
	}
}

pub fn (mut t TextBox) set_pos(x int, y int) {
	// xx := t.placeholder
	// println('text box $xx set pos $x, $y')
	t.x = x
	t.y = y
}

// Needed for ScrollableWidget
fn (tb &TextBox) adj_size() (int, int) {
	if tb.is_multiline {
		return tb.tv.size()
	} else {
		return text_size(tb, tb.text)
	}
}

pub fn (mut tb TextBox) size() (int, int) {
	return tb.width, tb.height
}

const max_textbox_height = 25

pub fn (mut tb TextBox) propose_size(w int, h int) (int, int) {
	tb.width, tb.height = w, h
	if tb.height > ui.max_textbox_height && !tb.fitted_height {
		tb.height = ui.max_textbox_height
	}
	update_text_size(mut tb)
	if tb.is_multiline {
		scrollview_update(tb)
		tb.tv.update_lines()
	}
	return tb.width, tb.height
}

fn (mut tb TextBox) update_line_height() {
	tb.line_height = int(f64(text_height(tb, 'W')) * 1.5)
}

fn (mut tb TextBox) draw() {
	offset_start(mut tb)
	scrollview_draw_begin(mut tb)
	// draw background
	if tb.has_scrollview {
		tb.ui.gg.draw_rect(tb.x + tb.scrollview.offset_x, tb.y + tb.scrollview.offset_y,
			tb.scrollview.width, tb.scrollview.height, gx.white)
	} else {
		tb.ui.gg.draw_rect(tb.x, tb.y, tb.width, tb.height, gx.white)
		if !tb.borderless {
			draw_inner_border(tb.border_accentuated, tb.ui.gg, tb.x, tb.y, tb.width, tb.height,
				tb.is_error != 0 && *tb.is_error)
		}
	}
	if tb.is_multiline {
		tb.tv.draw_textlines()
	} else {
		text := *(tb.text)
		text_len := text.runes().len
		mut placeholder := tb.placeholder
		if tb.placeholder_bind != 0 {
			placeholder = *(tb.placeholder_bind)
		}
		width := if text_len == 0 { 0 } else { text_width(tb, text) }
		text_y := tb.y + ui.textbox_padding_y // TODO off by 1px
		mut skip_idx := 0

		// Placeholder
		if text == '' && placeholder != '' {
			// tb.ui.gg.draw_text(tb.x + ui.textbox_padding_x, text_y, placeholder, tb.placeholder_cfg)
			// tb.draw_text(tb.x + ui.textbox_padding_x, text_y, placeholder)
			draw_text_with_color(tb, tb.x + ui.textbox_padding_x, text_y, placeholder,
				gx.gray)
		}
		// Text
		else {
			// Selection box
			tb.draw_selection()
			// The text doesn'tb fit, find the largest substring we can draw
			if width > tb.width && !tb.is_password {
				// Less useful with scrollview
				tb.ui.gg.set_cfg(tb.text_cfg)
				for i := text_len - 1; i >= 0; i-- {
					if i >= text_len {
						continue
					}
					// TODO: To fix since it fails when resizing to thin window
					// if tb.ui.gg.text_width(text[i..]) > tb.width {
					// 	skip_idx = i + 3
					// 	break
					// }
				}
				draw_text(tb, tb.x + ui.textbox_padding_x, text_y, text[skip_idx..])
			} else {
				if tb.is_password {
					draw_text(tb, tb.x + ui.textbox_padding_x, text_y, '*'.repeat(text_len))
				} else {
					draw_text(tb, tb.x + ui.textbox_padding_x, text_y, text)
				}
			}
		}
		// Draw the cursor
		// println("draw cursor: $tb.is_focused && !$tb.read_only && $tb.ui.show_cursor && ${!tb.is_sel_active()}")
		if tb.is_focused && !tb.read_only && tb.ui.show_cursor && !tb.is_sel_active() {
			// no cursor in sel mode
			mut cursor_x := tb.x + ui.textbox_padding_x
			if text_len > 0 {
				if tb.is_password {
					cursor_x += text_width(tb, '*'.repeat(tb.cursor_pos))
				} else if skip_idx > 0 {
					cursor_x += text_width(tb, text[skip_idx..])
				} else if text_len > 0 {
					// left := tb.text[..tb.cursor_pos]
					left := text.runes()[..tb.cursor_pos].string()
					cursor_x += text_width(tb, left)
				}
			}
			// tb.ui.gg.draw_line(cursor_x, tb.y+2, cursor_x, tb.y-2+tb.height-1)//, gx.Black)
			tb.ui.gg.draw_rect(cursor_x, tb.y + ui.textbox_padding_y, 1, tb.line_height,
				gx.black) // , gx.Black)
		}
	}
	$if bb ? {
		draw_bb(mut tb, tb.ui)
	}
	scrollview_draw_end(tb)
	offset_end(mut tb)
}

fn (tb &TextBox) is_sel_active() bool {
	if tb.is_multiline {
		return tb.tv.is_sel_active()
	} else {
		return (tb.is_focused || tb.read_only) && tb.sel_active && tb.sel_end != -1 //&& tb.sel_start != tb.sel_end
	}
}

fn (mut tb TextBox) draw_selection() {
	if !tb.is_sel_active() {
		// println("return draw_sel")
		return
	}
	sel_from, sel_width := text_xminmax_from_pos(tb, *tb.text, tb.sel_start, tb.sel_end)
	// println("tb draw sel ($tb.sel_start, $tb.sel_end): $sel_from, $sel_width")
	tb.ui.gg.draw_rect(tb.x + ui.textbox_padding_x + sel_from, tb.y + ui.textbox_padding_y,
		sel_width, tb.line_height, ui.selection_color)
}

pub fn (mut tb TextBox) cancel_selection() {
	if tb.is_multiline {
		tb.tv.cancel_selection()
	} else {
		tb.sel_start = -1
		tb.sel_end = -1
	}
	tb.sel_active = false
}

pub fn (mut tb TextBox) delete_selection() {
	u := tb.text.runes()
	sel_start, sel_end := if tb.sel_start < tb.sel_end {
		tb.sel_start, tb.sel_end
	} else {
		tb.sel_end, tb.sel_start
	}
	if sel_start < 0 {
		return
	}
	// println("rm sel: $tb.sel_start, $tb.sel_end -> $sel_start, $sel_end")
	// println("delete_sel: $sel_start, $sel_end, u.len: $u.len")
	unsafe {
		*tb.text = u[..sel_start].string() + u[sel_end..].string()
	}
	// println('delete: <${*tb.text}>')
	tb.cursor_pos = sel_start
	tb.cancel_selection()
}

// fn (mut tb TextBox) cursor_move(direction Side) {
// 	match direction {
// 		.bottom
// 	}
// }

fn tb_char(mut tb TextBox, e &KeyEvent, window &Window) {
	//  println("tb_char")
	if tb.hidden {
		return
	}
	if !tb.is_focused {
		return
	}
	if tb.on_char != TextBoxCharFn(0) {
		tb.on_char(window.state, tb, e.codepoint)
	}
}

fn tb_key_down(mut tb TextBox, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if tb_keydown ? {
		println('tb_keydown: $tb.id  -> $tb.hidden $tb.is_focused')
	}
	if tb.hidden {
		return
	}
	if !tb.is_focused && !tb.read_only {
		// println('textbox.key_down on an unfocused textbox, this should never happen')
		return
	}
	if tb.is_error != voidptr(0) {
		unsafe {
			*tb.is_error = false
		}
	}
	if e.key == .tab || (e.codepoint == 25 && e.mods == .shift) { // .tab used for focus and .invalid
		return
	}
	tb.is_typing = true
	if tb.on_key_down != TextBoxKeyDownFn(0) {
		tb.on_key_down(window.state, tb, e.codepoint)
	}
	tb.ui.last_type_time = time.ticks() // TODO perf?
	// Entering text
	if tb.is_multiline {
		tb.tv.key_down(e)
	} else {
		mut text := *tb.text
		if text.len == 0 {
			tb.cursor_pos = 0
		}
		s := utf32_to_str(e.codepoint)
		// println("key_down: $s $e.mods")
		if int(e.codepoint) !in [0, 9, 13, 27, 127] && e.mods !in [.ctrl, .super] { // skip enter and escape // && e.key !in [.enter, .escape] {
			if tb.read_only {
				return
			}
			if tb.max_len > 0 && text.runes().len >= tb.max_len {
				return
			}
			// if (tb.is_numeric && (s.len > 1 || !s[0].is_digit()  ) {
			if tb.is_numeric && (s.len > 1 || (!s[0].is_digit() && ((s[0] != `-`)
				|| ((text.runes().len > 0) && (tb.cursor_pos > 0))))) {
				return
			}
			// println('inserting codepoint=$e.codepoint mods=$e.mods ..')
			tb.insert(s)
			if tb.on_change != TextBoxChangeFn(0) {
				tb.on_change(*tb.text, window.state)
			}
			return
		} else if e.mods in [.ctrl, .super] {
			match s {
				'a' {
					if tb.read_only && !tb.is_selectable {
						return
					}
					tb.sel_start = 0
					tb.sel_end = text.runes().len
					tb.sel_active = true
				}
				'c' {
					if tb.is_sel_active() {
						ustr := tb.text.runes()
						sel_start, sel_end := if tb.sel_start < tb.sel_end {
							tb.sel_start, tb.sel_end
						} else {
							tb.sel_end, tb.sel_start
						}
						tb.ui.clipboard.copy(ustr[sel_start..sel_end].string())
					}
				}
				'v' {
					if tb.read_only {
						return
					}
					// println("paste ${tb.ui.clipboard.paste()}")
					tb.insert(tb.ui.clipboard.paste())
				}
				'x' {
					if tb.read_only {
						return
					}
					if tb.is_sel_active() {
						ustr := tb.text.runes()
						sel_start, sel_end := if tb.sel_start < tb.sel_end {
							tb.sel_start, tb.sel_end
						} else {
							tb.sel_end, tb.sel_start
						}
						tb.ui.clipboard.copy(ustr[sel_start..sel_end].string())
						tb.delete_selection()
					}
				}
				'-' {
					if tb.read_only && !tb.is_selectable {
						return
					}
					if tb.fitted_height {
						// TODO: propose_size
						tb.text_size -= 2
						if tb.text_size < 8 {
							tb.text_size = 8
						}
						update_text_size(mut tb)
						tb.update_line_height()
					}
				}
				'=', '+' {
					if tb.read_only && !tb.is_selectable {
						return
					}
					if tb.fitted_height {
						tb.text_size += 2
						if tb.text_size > 48 {
							tb.text_size = 48
						}
						update_text_size(mut tb)
						tb.update_line_height()
					}
				}
				else {}
			}
		}
		// println(e.key)
		// println('mods=$e.mods')
		defer {
			if tb.on_change != TextBoxChangeFn(0) {
				if e.key == .backspace {
					tb.on_change(*tb.text, window.state)
				}
			}
		}
		// println("tb key_down $e.key ${int(e.codepoint)}")
		match e.key {
			.enter {
				if tb.on_enter != TextBoxEnterFn(0) {
					println('tb_enter: <${*tb.text}>')
					tb.on_enter(*tb.text, window.state)
				}
			}
			.backspace {
				tb.ui.show_cursor = true
				if text != '' {
					if tb.cursor_pos == 0 {
						return
					}
					// Delete the entire selection
					if tb.is_sel_active() {
						tb.delete_selection()
					} else if e.mods in [.super, .ctrl] {
						// Delete until previous whitespace
						mut i := tb.cursor_pos
						for {
							if i > 0 {
								i--
							}
							if text[i].is_space() || i == 0 {
								// unsafe { *tb.text = u[..i) + u.right(tb.cursor_pos]}
								break
							}
						}
						tb.cursor_pos = i
					} else {
						u := text.runes()
						// Delete just one character
						unsafe {
							*tb.text = u[..tb.cursor_pos - 1].string() + u[tb.cursor_pos..].string()
						}
						tb.cursor_pos--
					}
					// u.free() // TODO remove
					// tb.text = tb.text[..tb.cursor_pos - 1] + tb.text[tb.cursor_pos..]
				}
				// RO REMOVE?
				// tb.update_text()
				if tb.on_change != TextBoxChangeFn(0) {
					// tb.on_change(*tb.text, window.state)
				}
			}
			.delete {
				tb.ui.show_cursor = true
				if tb.cursor_pos == text.len || text == '' {
					return
				}
				u := text.runes()
				unsafe {
					*tb.text = u[..tb.cursor_pos].string() + u[tb.cursor_pos + 1..].string()
				}
				// tb.text = tb.text[..tb.cursor_pos] + tb.text[tb.cursor_pos + 1..]
				// u.free() // TODO remove
				if tb.on_change != TextBoxChangeFn(0) {
					// tb.on_change(*tb.text, window.state)
				}
			}
			.left {
				if tb.sel(e.mods, e.key) {
					return
				}
				tb.cancel_selection()
				tb.ui.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
				tb.cursor_pos--
				if tb.cursor_pos < 0 {
					tb.cursor_pos = 0
				}
			}
			.right {
				if tb.sel(e.mods, e.key) {
					return
				}
				tb.cancel_selection()
				tb.ui.show_cursor = true
				tb.cursor_pos++
				text_len := text.runes().len
				if tb.cursor_pos > text_len {
					tb.cursor_pos = text_len
				}
				// println("right: $tb.cursor_posj")
			}
			.tab {
				// tb.ui.show_cursor = false
				/*
				TODO if tb.parent.just_tabbed {
					tb.parent.just_tabbed = false
					return
				}
				*/
				// println('TAB $tb.id')
				/*
				if e.mods == .shift {
					tb.parent.focus_previous()
				}
				else {
					tb.parent.focus_next()
				}
				*/
			}
			else {}
		}
	}
}

fn (mut tb TextBox) set_sel(sel_start_i int, sel_end_i int, key Key) {
	if tb.sel_direction == .right_to_left {
		tb.sel_start = sel_start_i
		tb.sel_end = sel_end_i
	} else {
		tb.sel_start = sel_end_i
		tb.sel_end = sel_start_i
	}
}

fn (mut tb TextBox) sel(mods KeyMod, key Key) bool {
	mut sel_start_i := if tb.sel_direction == .right_to_left { tb.sel_start } else { tb.sel_end }
	mut sel_end_i := if tb.sel_direction == .right_to_left { tb.sel_end } else { tb.sel_start }
	text := *tb.text
	if int(mods) == int(KeyMod.shift) + int(KeyMod.ctrl) {
		mut i := tb.cursor_pos
		if sel_start_i > 0 {
			i = if key == .left { sel_start_i - 1 } else { sel_start_i + 1 }
		} else if sel_start_i == 0 && sel_end_i > 0 {
			i = 0
		} else {
			tb.sel_direction = if key == .left {
				SelectionDirection.right_to_left
			} else {
				SelectionDirection.left_to_right
			}
		}
		sel_end_i = tb.cursor_pos
		for {
			if key == .left && i > 0 {
				i--
			} else if key == .right && i < tb.text.len {
				i++
			}
			if i == 0 {
				sel_start_i = 0
				break
			} else if i == text.len {
				sel_start_i = tb.text.len
				break
			} else if text[i].is_space() {
				sel_start_i = if tb.sel_direction == .right_to_left { i + 1 } else { i }
				break
			}
		}
		tb.set_sel(sel_start_i, sel_end_i, key)
		return true
	}
	if mods == .shift {
		if (tb.sel_direction == .right_to_left && sel_start_i == 0 && sel_end_i > 0)
			|| (tb.sel_direction == .left_to_right && sel_end_i == tb.text.len) {
			return true
		}
		if sel_start_i <= 0 {
			sel_end_i = tb.cursor_pos
			sel_start_i = if key == .left { tb.cursor_pos - 1 } else { tb.cursor_pos + 1 }
			tb.sel_direction = if key == .left {
				SelectionDirection.right_to_left
			} else {
				SelectionDirection.left_to_right
			}
		} else {
			sel_start_i = if key == .left { sel_start_i - 1 } else { sel_start_i + 1 }
		}
		tb.set_sel(sel_start_i, sel_end_i, key)
		return true
	}
	return false
}

fn (tb &TextBox) point_inside(x f64, y f64) bool {
	if tb.has_scrollview {
		return tb.scrollview.point_inside(x, y, .view)
	} else {
		return point_inside(tb, x, y)
	}
}

fn tb_mouse_down(mut tb TextBox, e &MouseEvent, zzz voidptr) {
	// println("mouse first $tb.id")
	if tb.hidden {
		return
	}
	if tb.has_scrollview && tb.scrollview.point_inside(e.x, e.y, .bar) {
		return
	}
	if !tb.point_inside(e.x, e.y) {
		tb.dragging = false
		tb.unfocus()
		return
	} else {
		// println('mouse first $tb.id')
		tb.focus()
	}
	// Calculate cursor position
	x, y := e.x - tb.x - ui.textbox_padding_x, e.y - tb.y - ui.textbox_padding_y
	// println("($x, $y) = ($e.x - $tb.x - $ui.textbox_padding_x, $e.y - $tb.y - $ui.textbox_padding_y)")
	if shift_key(e.mods) && tb.is_sel_active() {
		if tb.is_multiline {
			tb.tv.extend_selection(x, y)
		} else {
			tb.cursor_pos = text_pos_from_x(tb, *tb.text, x)
			if tb.twosided_sel { // extend selection from both sides
				// tv.sel_start and tv.sel_end can and have to be sorted
				if tb.sel_start > tb.sel_end {
					tb.sel_start, tb.sel_end = tb.sel_end, tb.sel_start
				}
				if tb.cursor_pos < tb.sel_start {
					tb.sel_start = tb.cursor_pos
				} else if tb.cursor_pos > tb.sel_end {
					tb.sel_end = tb.cursor_pos
				}
			} else {
				tb.sel_end = tb.cursor_pos
			}
		}
	} else {
		if !tb.dragging && e.action == .down {
			// println("$tb.id $tb.dragging $e.action")
			tb.cancel_selection()
		}
		tb.ui.show_cursor = true
		tb.dragging = e.action == .down
		if tb.is_multiline {
			tb.tv.start_selection(x, y)
		} else {
			tb.cursor_pos = text_pos_from_x(tb, *tb.text, x)
			if tb.dragging {
				tb.sel_start = tb.cursor_pos
			}
		}
	}
}

fn tb_mouse_move(mut tb TextBox, e &MouseMoveEvent, zzz voidptr) {
	if tb.hidden {
		return
	}
	tb.is_selectable = tb.point_inside(e.x, e.y)
	if !(tb.is_selectable) {
		return
	}
	if tb.dragging {
		x := int(e.x - tb.x - ui.textbox_padding_x)
		if tb.is_multiline {
			y := int(e.y - tb.y - ui.textbox_padding_y)
			tb.tv.end_selection(x, y)
		} else {
			tb.sel_end = text_pos_from_x(tb, *tb.text, x)
			tb.ui.show_cursor = false
		}
		tb.sel_active = true
	}
}

fn tb_mouse_up(mut tb TextBox, e &MouseEvent, zzz voidptr) {
	if tb.hidden {
		return
	}
	if !tb.point_inside(e.x, e.y) {
		return
	}
	tb.dragging = false
}

fn (mut tb TextBox) set_visible(state bool) {
	tb.hidden = !state
}

pub fn (mut tb TextBox) focus() {
	mut f := Focusable(tb)
	f.set_focus()
}

fn (mut tb TextBox) unfocus() {
	// println('textbox $t.placeholder unfocus()')
	tb.is_focused = false
	tb.sel_active = false
	tb.sel_start = 0
	tb.sel_end = 0
}

pub fn (mut tb TextBox) hide() {
}

pub fn (mut tb TextBox) set_text(s string) {
	// tb.text = s
	// tb.update()
}

// pub fn (mut tb TextBox) on_change(func voidptr) {
// }

pub fn (mut tb TextBox) insert(s string) {
	// Remove the selection
	if tb.is_sel_active() {
		tb.delete_selection()
	}
	mut ustr := tb.text.runes()
	$if tb_insert ? {
		println('tb_insert: $tb.id $ustr $tb.cursor_pos')
	}
	// Insert s
	sr := s.runes()
	ustr.insert(tb.cursor_pos, sr)
	unsafe {
		*tb.text = ustr.string()
	}
	tb.cursor_pos += sr.len
}

// Normally useless but required for scrollview_draw_begin()
fn (tb &TextBox) set_children_pos() {}
