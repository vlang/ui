// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import strings
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

type KeyDownFn = fn (voidptr, voidptr, u32)

type CharFn = fn (voidptr, voidptr, u32)

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
	parent     Layout
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
	// is_multiline mode
	is_multiline bool
	tv           TextView
	is_wordwrap  bool
	lines        []string
	wordwrap     []int
	// others
	is_numeric    bool
	is_password   bool
	read_only     bool
	borderless    bool
	fitted_height bool // if true fit height in propose_size
	on_key_down   KeyDownFn = KeyDownFn(0)
	on_char       CharFn    = CharFn(0)
	// on_key_up          KeyUpFn   = KeyUpFn(0)
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
mut:
	is_typing bool
}

/*
struct Rect {
	x      int
	y      int
	width  int
	height int
}
*/
pub struct TextBoxConfig {
	id               string
	width            int
	height           int = 22
	is_multiline     bool
	is_wordwrap      bool
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
	on_key_down   KeyDownFn
	on_char       CharFn
	// on_key_up          KeyUpFn
	on_change          voidptr
	on_enter           voidptr
	border_accentuated bool
	text_cfg           gx.TextCfg
	text_size          f64
	// added when user set text after declaration but before init (see colorbox component)
	text_after bool
}

pub fn textbox(c TextBoxConfig) &TextBox {
	tb := &TextBox{
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
	}
	if c.text == 0 && !c.text_after {
		panic('textbox.text binding is not set')
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
	if tb.text_size > 0 {
		_, win_height := tb.ui.window.size()
		tb.text_cfg = gx.TextCfg{
			...tb.text_cfg
			size: text_size_as_int(tb.text_size, win_height)
		}
	}
	if tb.is_multiline {
		tb.tv.init(tb)
	}
	// TODO: Maybe in a method later to allow font size update
	tb.line_height = text_height(tb, 'W') + 6
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
	w, mut h := text_size(tb, tb.text)
	if tb.is_multiline {
		h = h * tb.text.split('\n').len
	}
	return w, h
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
	tb.update_textlines()
	return tb.width, tb.height
}

fn (mut tb TextBox) draw() {
	offset_start(mut tb)
	// draw background
	tb.ui.gg.draw_rect(tb.x, tb.y, tb.width, tb.height, gx.white)
	if !tb.borderless {
		draw_inner_border(tb.border_accentuated, tb.ui.gg, tb.x, tb.y, tb.width, tb.height,
			tb.is_error != 0 && *tb.is_error)
	}
	if tb.is_multiline {
		tb.draw_textlines()
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
			if !tb.is_multiline && width > tb.width {
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
					/*
					for i in 0..tb.text.len {
						// TODO drawing multiple circles is broken
						//tb.ui.gg.draw_image(tb.x + 5 + i * 12, tb.y + 5, 8, 8, tb.ui.circle_image)
					}
					*/
					// tb.ui.gg.draw_text(tb.x + ui.textbox_padding_x, text_y, strings.repeat(`*`,
					// 	text.len), tb.placeholder_cfg)
					// tb.draw_text(tb.x + ui.textbox_padding_x, text_y, strings.repeat(`*`, text.len))
					draw_text(tb, tb.x + ui.textbox_padding_x, text_y, strings.repeat(`*`,
						text_len))
				} else {
					draw_text(tb, tb.x + ui.textbox_padding_x, text_y, text)
				}
			}
		}
		// Draw the cursor
		if tb.is_focused && !tb.read_only && tb.ui.show_cursor && !tb.is_sel_active() {
			// no cursor in sel mode
			mut cursor_x := tb.x + ui.textbox_padding_x
			if tb.is_password {
				cursor_x += text_width(tb, strings.repeat(`*`, tb.cursor_pos))
			} else if skip_idx > 0 {
				cursor_x += text_width(tb, text[skip_idx..])
			} else if text_len > 0 {
				// left := tb.text[..tb.cursor_pos]
				left := text.runes()[..tb.cursor_pos].string()
				cursor_x += text_width(tb, left)
			}
			if text_len == 0 {
				cursor_x = tb.x + ui.textbox_padding_x
			}
			// tb.ui.gg.draw_line(cursor_x, tb.y+2, cursor_x, tb.y-2+tb.height-1)//, gx.Black)
			tb.ui.gg.draw_rect(cursor_x, tb.y + ui.textbox_padding_y, 1, tb.line_height,
				gx.black) // , gx.Black)
		}
	}
	$if bb ? {
		draw_bb(mut tb, tb.ui)
	}
	offset_end(mut tb)
}

fn (tb &TextBox) is_sel_active() bool {
	if !tb.is_focused {
		return false
	}
	if tb.is_multiline {
		return tb.tv.is_sel_active()
	} else {
		return tb.sel_end != -1 && tb.sel_start != tb.sel_end
	}
}

fn (tb &TextBox) draw_selection() {
	if !tb.is_sel_active() {
		// println("return draw_sel")
		return
	}
	if tb.is_multiline {
		// println("drawtl ${tb.tv.sel_start_line()} (${tb.tv.sel_start_line().runes().len}) j=$tb.tv.tlv.sel_start_j, $tb.tv.tlv.sel_end_j i=$tb.tv.tlv.sel_start_i, $tb.tv.tlv.sel_end_i")
		if tb.tv.tlv.sel_start_j == tb.tv.tlv.sel_end_j {
			sel_from, sel_width := text_xminmax_from_pos(tb, tb.tv.sel_start_line(), tb.tv.tlv.sel_start_i,
				tb.tv.tlv.sel_end_i)
			tb.ui.gg.draw_rect(tb.x + ui.textbox_padding_x + sel_from, tb.y + ui.textbox_padding_y +
				tb.tv.tlv.sel_start_j * tb.line_height, sel_width, tb.line_height, ui.selection_color)
		} else {
			start_i, end_i, start_j, end_j := if tb.tv.tlv.sel_start_j < tb.tv.tlv.sel_end_j {
				tb.tv.tlv.sel_start_i, tb.tv.tlv.sel_end_i, tb.tv.tlv.sel_start_j, tb.tv.tlv.sel_end_j
			} else {
				tb.tv.tlv.sel_end_i, tb.tv.tlv.sel_start_i, tb.tv.tlv.sel_end_j, tb.tv.tlv.sel_start_j
			}
			mut ustr := tb.tv.line(start_j)
			mut sel_from, mut sel_width := text_xminmax_from_pos(tb, ustr, start_i, ustr.len)
			tb.ui.gg.draw_rect(tb.x + ui.textbox_padding_x + sel_from, tb.y + ui.textbox_padding_y +
				start_j * tb.line_height, sel_width, tb.line_height, ui.selection_color)
			if end_j - start_j > 1 {
				for j in (start_j + 1) .. end_j {
					ustr = tb.tv.line(j)
					sel_from, sel_width = text_xminmax_from_pos(tb, ustr, 0, ustr.runes().len)
					tb.ui.gg.draw_rect(tb.x + ui.textbox_padding_x + sel_from, tb.y +
						ui.textbox_padding_y + j * tb.line_height, sel_width, tb.line_height,
						ui.selection_color)
				}
			}
			sel_from, sel_width = text_xminmax_from_pos(tb, tb.tv.sel_end_line(), 0, end_i)
			tb.ui.gg.draw_rect(tb.x + ui.textbox_padding_x + sel_from, tb.y + ui.textbox_padding_y +
				end_j * tb.line_height, sel_width, tb.line_height, ui.selection_color)
		}
	} else {
		sel_from, sel_width := text_xminmax_from_pos(tb, *tb.text, tb.sel_start, tb.sel_end)
		// println("tb draw sel ($tb.sel_start, $tb.sel_end): $sel_from, $sel_width")
		tb.ui.gg.draw_rect(tb.x + ui.textbox_padding_x + sel_from, tb.y + ui.textbox_padding_y,
			sel_width, tb.line_height, ui.selection_color)
	}
}

fn (tb &TextBox) draw_textlines() {
	tb.draw_selection()
	mut y := tb.y + ui.textbox_padding_y
	// println("draw_textlines: $tb.tv.tlv.lines")
	for line in tb.tv.tlv.lines {
		draw_text(tb, tb.x + ui.textbox_padding_x, y, line)
		y += tb.line_height
	}
	// draw cursor
	if tb.is_focused && !tb.read_only && tb.ui.show_cursor { //&& !tb.tv.is_sel_active() {
		ustr := tb.tv.current_line().runes()
		mut cursor_x := tb.x + ui.textbox_padding_x
		if ustr.len > 0 {
			// println("ici ($tb.tv.tlv.cursor_pos_i, $tb.tv.tlv.cursor_pos_j) $ustr.len")
			// cursor_pos_i := if tb.tv.tlv.cursor_pos_i > ustr.len {
			// 	ustr.len
			// } else {
			// 	tb.tv.tlv.cursor_pos_i
			// }
			left := ustr[..tb.tv.tlv.cursor_pos_i].string()
			cursor_x += text_width(tb, left)
		}
		// tb.ui.gg.draw_line(cursor_x, tb.y+2, cursor_x, tb.y-2+tb.height-1)//, gx.Black)
		tb.ui.gg.draw_rect(cursor_x, tb.y + ui.textbox_padding_y +
			tb.tv.tlv.cursor_pos_j * tb.line_height, 1, tb.line_height, gx.black) // , gx.Black)
	}
}

pub fn (mut tb TextBox) update_textlines() {
	if !tb.is_multiline {
		return
	}
	tb.tv.update_lines()
}

pub fn (mut tb TextBox) update_text() {
	if tb.is_multiline {
		// res := if tb.is_wordwrap {
		// 	word_wrap_join(tb.lines, tb.wordwrap)
		// } else {
		// 	tb.lines.join('\n')
		// }
		// unsafe {
		// 	*tb.text = res
		// }
	}
}

pub fn (mut tb TextBox) cancel_selection() {
	if tb.is_multiline {
		tb.tv.cancel_selection()
	} else {
		tb.sel_start = 0
		tb.sel_end = -1
	}
}

pub fn (mut tb TextBox) delete_selection() {
	if tb.is_multiline {
	} else {
		u := tb.text.runes()
		start_i, end_i := if tb.sel_start < tb.sel_end {
			tb.sel_start, tb.sel_end
		} else {
			tb.sel_end, tb.sel_start
		}
		// println("rm sel: $tb.sel_start, $tb.sel_end -> $start_i, $end_i")
		unsafe {
			*tb.text = u[..start_i].string() + u[end_i..].string()
		}
		tb.cursor_pos = tb.sel_start
		tb.sel_start = 0
		tb.sel_end = 0
	}
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
	if tb.on_char != voidptr(0) {
		tb.on_char(window.state, tb, e.codepoint)
	}
}

fn tb_key_down(mut tb TextBox, e &KeyEvent, window &Window) {
	// println('key down $e')
	$if tb_keydown ? {
		println('tb_keydown: $tb.id  -> $tb.hidden $tb.is_focused')
	}
	if tb.hidden {
		return
	}
	if !tb.is_focused {
		// println('textbox.key_down on an unfocused textbox, this should never happen')
		return
	}
	if tb.is_error != voidptr(0) {
		unsafe {
			*tb.is_error = false
		}
	}
	tb.is_typing = true
	if tb.on_key_down != voidptr(0) {
		tb.on_key_down(window.state, tb, e.codepoint)
	}
	tb.ui.last_type_time = time.ticks() // TODO perf?
	// Entering text
	if tb.read_only {
		return
	}
	if tb.is_multiline {
		tb.tv.key_down(e)
	} else {
		mut text := *tb.text
		if text.len == 0 {
			tb.cursor_pos = 0
		}
		if int(e.codepoint) !in [0, 13, 27] && e.mods != .super { // skip enter and escape // && e.key !in [.enter, .escape] {
			if tb.max_len > 0 && text.runes().len >= tb.max_len {
				return
			}
			if byte(e.codepoint) in [`\t`, 127] {
				// Do not print the tab character, delete etc
				return
			}
			s := utf32_to_str(e.codepoint)
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
			// println('T "$s " $tb.cursor_pos')
			// tb.text += s
			// tb.cursor_pos ++//= utf8_char_len(s[0])// s.le-112
			return
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
				$if tb_bsp ? {
					println('after bsp $tb.lines ${*tb.text}')
				}
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
				if tb.sel_end > 0 {
					tb.cursor_pos = tb.sel_start + 1
				}
				tb.sel_start = 0
				tb.sel_end = 0
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
				if tb.sel_start > 0 {
					tb.cursor_pos = tb.sel_start - 1
				}
				tb.sel_end = 0
				tb.sel_start = 0
				tb.ui.show_cursor = true
				tb.cursor_pos++
				text_len := text.runes().len
				if tb.cursor_pos > text_len {
					tb.cursor_pos = text_len
				}
				// println("right: $tb.cursor_posj")
			}
			.a {
				if e.mods in [.super, .ctrl] {
					tb.sel_start = 0
					tb.sel_end = text.runes().len - 1
				}
			}
			.v {
				if e.mods in [.super, .ctrl] {
					tb.insert(tb.ui.clipboard.paste())
				}
			}
			.tab {
				tb.ui.show_cursor = true
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
	return point_inside(tb, x, y)
}

fn tb_mouse_move(mut tb TextBox, e &MouseMoveEvent, zzz voidptr) {
	if tb.hidden {
		return
	}
	if !tb.point_inside(e.x, e.y) {
		return
	}
	if tb.dragging {
		x := int(e.x - tb.x - ui.textbox_padding_x)
		if tb.is_multiline {
			y := int(e.y - tb.y - ui.textbox_padding_y)
			tb.tv.end_selection(x, y)
		} else {
			tb.sel_end = text_pos_from_x(tb, *tb.text, x)
		}
	}
}

fn tb_mouse_down(mut tb TextBox, e &MouseEvent, zzz voidptr) {
	// println("mouse first")
	if tb.hidden {
		return
	}
	if !tb.point_inside(e.x, e.y) {
		tb.dragging = false
		tb.unfocus()
		return
	} else {
		tb.focus()
	}
	if !tb.dragging && e.action == .down {
		tb.cancel_selection()
	}
	tb.dragging = e.action == .down
	// Calculate cursor position from x
	x := e.x - tb.x - ui.textbox_padding_x
	if tb.is_multiline {
		y := e.y - tb.y - ui.textbox_padding_y
		tb.tv.start_selection(x, y)
	} else {
		tb.cursor_pos = text_pos_from_x(tb, *tb.text, x)
		if tb.dragging {
			tb.sel_start = tb.cursor_pos
		}
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
	set_focus(tb.ui.window, mut tb)
}

fn (tb &TextBox) is_focused() bool {
	return tb.is_focused
}

fn (mut tb TextBox) unfocus() {
	// println('textbox $t.placeholder unfocus()')
	tb.is_focused = false
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
	if tb.is_multiline {
		tb.tv.insert(s)
	} else {
		mut ustr := tb.text.runes()
		old_len := ustr.len
		// Remove the selection
		if tb.sel_start < tb.sel_end {
			unsafe {
				*tb.text = ustr[..tb.sel_start].string() + s + ustr[tb.sel_end + 1..].string()
			}
		} else {
			$if tb_insert ? {
				println('tb_insert: $tb.id $ustr $tb.cursor_pos')
			}
			// Insert one character
			// tb.text = tb.text[..tb.cursor_pos] + s + tb.text[tb.cursor_pos..]
			unsafe {
				*tb.text = ustr[..tb.cursor_pos].string() + s + ustr[tb.cursor_pos..].string()
			}
			ustr = tb.text.runes()
			// The string is too long
			if tb.max_len > 0 && ustr.len >= tb.max_len {
				// tb.text = tb.text.limit(tb.max_len)
				unsafe {
					*tb.text = ustr[..tb.max_len].string()
				}
				ustr = tb.text.runes()
			}
		}
		// tb.cursor_pos += tb.text.len - old_len
		tb.cursor_pos += ustr.len - old_len
		tb.sel_start = 0
		tb.sel_end = 0
	}
}
