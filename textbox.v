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
	textbox_padding               = 5
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
	height     int
	width      int
	x          int
	y          int
	z_index    int
	parent     Layout
	is_focused bool
	// gg &gg.GG
	ui &UI
	// text               string
	text             &string = voidptr(0)
	max_len          int
	is_multi         bool
	placeholder      string
	placeholder_bind &string = voidptr(0)
	cursor_pos       int
	is_numeric       bool
	is_password      bool
	sel_start        int
	sel_end          int
	last_x           int
	read_only        bool
	borderless       bool
	on_key_down      KeyDownFn = KeyDownFn(0)
	on_char          CharFn    = CharFn(0)
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
	width            int
	height           int = 22
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
	is_multi         bool
	text             &string = voidptr(0)
	is_error         &bool   = voidptr(0)
	is_focused       bool
	// is_error bool
	borderless  bool
	on_key_down KeyDownFn
	on_char     CharFn
	// on_key_up          KeyUpFn
	on_change          voidptr
	on_enter           voidptr
	border_accentuated bool
	text_cfg           gx.TextCfg
	text_size          f64
}

fn (mut tb TextBox) init(parent Layout) {
	tb.parent = parent
	ui := parent.get_ui()
	tb.ui = ui
	if is_empty_text_cfg(tb.text_cfg) {
		tb.text_cfg = tb.ui.window.text_cfg
	}
	if tb.text_size > 0 {
		_, win_height := tb.ui.window.size()
		tb.text_cfg = gx.TextCfg{
			...tb.text_cfg
			size: text_size_as_int(tb.text_size, win_height)
		}
	}
	// return widget
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, tb_click, tb)
	subscriber.subscribe_method(events.on_key_down, tb_key_down, tb)
	subscriber.subscribe_method(events.on_char, tb_char, tb)
	// subscriber.subscribe_method(events.on_key_up, tb_key_up, tb)
	subscriber.subscribe_method(events.on_mouse_move, tb_mouse_move, tb)
}

pub fn textbox(c TextBoxConfig) &TextBox {
	tb := &TextBox{
		height: c.height
		width: if c.width < 30 { 30 } else { c.width }
		z_index: c.z_index
		// sel_start: 0
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
	}
	if c.text == 0 {
		panic('textbox.text binding is not set')
	}
	return tb
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

fn (mut t TextBox) set_pos(x int, y int) {
	// xx := t.placeholder
	// println('text box $xx set pos $x, $y')
	t.x = x
	t.y = y
}

fn (mut tb TextBox) size() (int, int) {
	return tb.width, tb.height
}

fn (mut tb TextBox) propose_size(w int, h int) (int, int) {
	tb.width, tb.height = w, h
	return tb.width, tb.height
}

fn (mut tb TextBox) draw() {
	text := *(tb.text)
	mut placeholder := tb.placeholder
	if tb.placeholder_bind != 0 {
		placeholder = *(tb.placeholder_bind)
	}
	tb.ui.gg.draw_rect(tb.x, tb.y, tb.width, tb.height, gx.white)
	if !tb.borderless {
		draw_inner_border(tb.border_accentuated, tb.ui.gg, tb.x, tb.y, tb.width, tb.height,
			tb.is_error != 0 && *tb.is_error)
	}
	width := if text.len == 0 { 0 } else { text_width<TextBox>(tb, text) }
	text_y := tb.y + 2 // TODO off by 1px
	mut skip_idx := 0
	// Placeholder
	if text == '' && placeholder != '' {
		// tb.ui.gg.draw_text(tb.x + ui.textbox_padding, text_y, placeholder, tb.placeholder_cfg)
		// tb.draw_text(tb.x + ui.textbox_padding, text_y, placeholder)
		draw_text<TextBox>(tb, tb.x + ui.textbox_padding, text_y, placeholder)
	}
	// Text
	else {
		// Selection box
		// if tb.sel_start != 0 {
		ustr := text.ustring()
		if tb.sel_start < tb.sel_end && tb.sel_start < ustr.len {
			left := ustr.left(tb.sel_start)
			right := ustr.right(tb.sel_end)
			tb.ui.gg.set_cfg(tb.text_cfg)
			sel_width := width - tb.ui.gg.text_width(right) - tb.ui.gg.text_width(left)
			x := tb.ui.gg.text_width(left) + tb.x + ui.textbox_padding
			tb.ui.gg.draw_rect(x, tb.y + 3, sel_width, tb.height - 6, ui.selection_color) // sel_width := tb.ui.gg.text_width(right) + 1
		}
		// The text doesn'tb fit, find the largest substring we can draw
		if width > tb.width {
			tb.ui.gg.set_cfg(tb.text_cfg)
			for i := text.len - 1; i >= 0; i-- {
				if i >= text.len {
					continue
				}
				if tb.ui.gg.text_width(text[i..]) > tb.width {
					skip_idx = i + 3
					break
				}
			}
			// tb.ui.gg.draw_text(tb.x + ui.textbox_padding, text_y, text[skip_idx..], tb.placeholder_cfg)
			// tb.draw_text(tb.x + ui.textbox_padding, text_y, text[skip_idx..])
			draw_text<TextBox>(tb, tb.x + ui.textbox_padding, text_y, text[skip_idx..])
		} else {
			if tb.is_password {
				/*
				for i in 0..tb.text.len {
					// TODO drawing multiple circles is broken
					//tb.ui.gg.draw_image(tb.x + 5 + i * 12, tb.y + 5, 8, 8, tb.ui.circle_image)
				}
				*/
				// tb.ui.gg.draw_text(tb.x + ui.textbox_padding, text_y, strings.repeat(`*`,
				// 	text.len), tb.placeholder_cfg)
				// tb.draw_text(tb.x + ui.textbox_padding, text_y, strings.repeat(`*`, text.len))
				draw_text<TextBox>(tb, tb.x + ui.textbox_padding, text_y, strings.repeat(`*`,
					text.len))
			} else {
				// tb.ui.gg.draw_text(tb.x + ui.textbox_padding, text_y, text, tb.placeholder_cfg)
				// tb.draw_text(tb.x + ui.textbox_padding, text_y, text)
				draw_text<TextBox>(tb, tb.x + ui.textbox_padding, text_y, text)
			}
		}
	}
	// Draw the cursor
	if tb.is_focused && !tb.read_only && tb.ui.show_cursor && tb.sel_start == 0 && tb.sel_end == 0 {
		// no cursor in sel mode
		mut cursor_x := tb.x + ui.textbox_padding
		if tb.is_password {
			cursor_x += text_width<TextBox>(tb, strings.repeat(`*`, tb.cursor_pos))
		} else if skip_idx > 0 {
			cursor_x += text_width<TextBox>(tb, text[skip_idx..])
		} else if text.len > 0 {
			// left := tb.text[..tb.cursor_pos]
			left := text.ustring().left(tb.cursor_pos)
			cursor_x += text_width<TextBox>(tb, left)
		}
		if text.len == 0 {
			cursor_x = tb.x + ui.textbox_padding
		}
		// tb.ui.gg.draw_line(cursor_x, tb.y+2, cursor_x, tb.y-2+tb.height-1)//, gx.Black)
		tb.ui.gg.draw_rect(cursor_x, tb.y + 3, 1, tb.height - 6, gx.black) // , gx.Black)
	}
	$if bb ? {
		draw_bb(tb, tb.ui)
	}
}

// fn tb_key_up(mut tb TextBox, e &KeyEvent, window &Window) {
// 	println("hvhvh")
// 	if !tb.is_focused {
// 		return
// 	}
// 	if tb.on_key_up != voidptr(0) {
// 		tb.on_key_up(window.state, tb, e.codepoint)
// 	}
// }

fn tb_char(mut tb TextBox, e &KeyEvent, window &Window) {
	//  println("tb_char")
	if !tb.is_focused {
		return
	}
	if tb.on_char != voidptr(0) {
		tb.on_char(window.state, tb, e.codepoint)
	}
}

fn tb_key_down(mut tb TextBox, e &KeyEvent, window &Window) {
	// println('key down $e')
	text := *tb.text
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
	if int(e.codepoint) !in [0, 13, 27] && e.mods != .super { // skip enter and escape // && e.key !in [.enter, .escape] {
		if tb.read_only {
			return
		}
		if tb.max_len > 0 && text.len >= tb.max_len {
			return
		}
		if byte(e.codepoint) in [`\t`, 127] {
			// Do not print the tab character, delete etc
			return
		}
		s := utf32_to_str(e.codepoint)
		// if (tb.is_numeric && (s.len > 1 || !s[0].is_digit()  ) {
		if tb.is_numeric && (s.len > 1 || (!s[0].is_digit() && ((s[0] != `-`)
			|| ((text.len > 0) && (tb.cursor_pos > 0))))) {
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
	match e.key {
		.enter {
			if tb.on_enter != TextBoxEnterFn(0) {
				tb.on_enter(*tb.text, window.state)
			}
		}
		.backspace {
			tb.ui.show_cursor = true
			if text != '' {
				if tb.cursor_pos == 0 {
					return
				}
				u := text.ustring()
				// Delete the entire selection
				if tb.sel_start < tb.sel_end {
					unsafe {
						*tb.text = u.left(tb.sel_start) + u.right(tb.sel_end)
					}
					tb.cursor_pos = tb.sel_start
					tb.sel_start = 0
					tb.sel_end = 0
				} else if e.mods in [.super, .ctrl] {
					// Delete until previous whitespace
					mut i := tb.cursor_pos
					for {
						if i > 0 {
							i--
						}
						if text[i].is_space() || i == 0 {
							// unsafe { *tb.text = u.left(i) + u.right(tb.cursor_pos)}
							break
						}
					}
					tb.cursor_pos = i
				} else {
					// Delete just one character
					unsafe {
						*tb.text = u.left(tb.cursor_pos - 1) + u.right(tb.cursor_pos)
					}
					tb.cursor_pos--
				}
				// u.free() // TODO remove
				// tb.text = tb.text[..tb.cursor_pos - 1] + tb.text[tb.cursor_pos..]
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
			u := text.ustring()
			unsafe {
				*tb.text = u.left(tb.cursor_pos) + u.right(tb.cursor_pos + 1)
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
			if tb.sel_end > 0 {
				tb.cursor_pos = tb.sel_start + 1
			}
			tb.sel_start = 0
			tb.sel_end = 0
			tb.ui.show_cursor = true // always show cursor when moving it (left, right, backspace etc)
			tb.cursor_pos--
			if tb.cursor_pos <= 0 {
				tb.cursor_pos = 0
			}
		}
		.right {
			if tb.sel(e.mods, e.key) {
				return
			}
			if tb.sel_start > 0 {
				tb.cursor_pos = tb.sel_end - 1
			}
			tb.sel_end = 0
			tb.sel_start = 0
			tb.ui.show_cursor = true
			tb.cursor_pos++
			if tb.cursor_pos > text.len {
				tb.cursor_pos = text.len
			}
		}
		.a {
			if e.mods in [.super, .ctrl] {
				tb.sel_start = 0
				tb.sel_end = text.ustring().len - 1
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

fn (mut tb TextBox) set_sel(sel_start int, sel_end int, key Key) {
	if tb.sel_direction == .right_to_left {
		tb.sel_start = sel_start
		tb.sel_end = sel_end
	} else {
		tb.sel_start = sel_end
		tb.sel_end = sel_start
	}
}

fn (mut tb TextBox) sel(mods KeyMod, key Key) bool {
	mut sel_start := if tb.sel_direction == .right_to_left { tb.sel_start } else { tb.sel_end }
	mut sel_end := if tb.sel_direction == .right_to_left { tb.sel_end } else { tb.sel_start }
	text := *tb.text
	if int(mods) == int(KeyMod.shift) + int(KeyMod.ctrl) {
		mut i := tb.cursor_pos
		if sel_start > 0 {
			i = if key == .left { sel_start - 1 } else { sel_start + 1 }
		} else if sel_start == 0 && sel_end > 0 {
			i = 0
		} else {
			tb.sel_direction = if key == .left {
				SelectionDirection.right_to_left
			} else {
				SelectionDirection.left_to_right
			}
		}
		sel_end = tb.cursor_pos
		for {
			if key == .left && i > 0 {
				i--
			} else if key == .right && i < tb.text.len {
				i++
			}
			if i == 0 {
				sel_start = 0
				break
			} else if i == text.len {
				sel_start = tb.text.len
				break
			} else if text[i].is_space() {
				sel_start = if tb.sel_direction == .right_to_left { i + 1 } else { i }
				break
			}
		}
		tb.set_sel(sel_start, sel_end, key)
		return true
	}
	if mods == .shift {
		if (tb.sel_direction == .right_to_left && sel_start == 0 && sel_end > 0)
			|| (tb.sel_direction == .left_to_right && sel_end == tb.text.len) {
			return true
		}
		if sel_start <= 0 {
			sel_end = tb.cursor_pos
			sel_start = if key == .left { tb.cursor_pos - 1 } else { tb.cursor_pos + 1 }
			tb.sel_direction = if key == .left {
				SelectionDirection.right_to_left
			} else {
				SelectionDirection.left_to_right
			}
		} else {
			sel_start = if key == .left { sel_start - 1 } else { sel_start + 1 }
		}
		tb.set_sel(sel_start, sel_end, key)
		return true
	}
	return false
}

fn (tb &TextBox) point_inside(x f64, y f64) bool {
	return x >= tb.x && x <= tb.x + tb.width && y >= tb.y && y <= tb.y + tb.height
}

fn tb_mouse_move(mut tb TextBox, e &MouseEvent, zzz voidptr) {
	if !tb.point_inside(e.x, e.y) {
		return
	}
	if tb.dragging {
		x := e.x - tb.x - ui.textbox_padding
		reverse := x - tb.last_x < 0
		if tb.sel_start <= 0 {
			tb.sel_start = tb.cursor_pos
		}
		tb.last_x = x
		mut prev_width := 0
		ustr := tb.text.ustring()
		for i in 1 .. ustr.len {
			width := text_width<TextBox>(tb, ustr.left(i))
			if prev_width <= x && x <= width {
				if i < tb.sel_start && tb.sel_end < tb.sel_start {
					tb.sel_end = tb.sel_start
					tb.sel_start = i
					return
				}
				if reverse {
					tb.sel_start = i
				} else {
					tb.sel_end = i
				}
				return
			}
			prev_width = width
		}
		if reverse {
			tb.sel_start = 0
		} else {
			tb.sel_end = tb.text.len
		}
	}
}

fn tb_click(mut tb TextBox, e &MouseEvent, zzz voidptr) {
	if !tb.point_inside(e.x, e.y) {
		tb.dragging = false
		return
	}
	if !tb.dragging && e.action == MouseAction(1) {
		tb.sel_start = 0
		tb.sel_end = 0
	}
	tb.dragging = int(e.action) == 1
	tb.ui.show_cursor = true
	tb.focus()
	if *tb.text == '' {
		return
	}
	// Calculate cursor position from x
	x := e.x - tb.x - ui.textbox_padding
	if x <= 0 {
		tb.cursor_pos = 0
		return
	}
	mut prev_width := 0
	ustr := tb.text.ustring()
	for i in 1 .. ustr.len {
		// width := tb.ui.gg.text_width(tb.text[..i])
		width := text_width<TextBox>(tb, ustr.left(i))
		if prev_width <= x && x <= width {
			tb.cursor_pos = i
			return
		}
		prev_width = width
	}
	tb.cursor_pos = tb.text.len
}

fn (mut tb TextBox) set_visible(state bool) {
	tb.hidden = state
}

pub fn (mut tb TextBox) focus() {
	if tb.is_focused {
		return
	}
	parent := tb.parent
	parent.unfocus_all()
	mut wnd := parent.get_ui().window
	wnd.unfocus_all()
	tb.is_focused = true
}

fn (tb &TextBox) is_focused() bool {
	return tb.is_focused
}

fn (mut t TextBox) unfocus() {
	// println('textbox $t.placeholder unfocus()')
	t.is_focused = false
	t.sel_start = 0
	t.sel_end = 0
}

fn (mut tb TextBox) update() {
	tb.cursor_pos = tb.text.ustring().len
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
	mut ustr := tb.text.ustring()
	old_len := ustr.len
	// Remove the selection
	if tb.sel_start < tb.sel_end {
		unsafe {
			*tb.text = ustr.left(tb.sel_start) + s + ustr.right(tb.sel_end + 1)
		}
	} else {
		// Insert one character
		// tb.text = tb.text[..tb.cursor_pos] + s + tb.text[tb.cursor_pos..]
		unsafe {
			*tb.text = ustr.left(tb.cursor_pos) + s + ustr.right(tb.cursor_pos)
		}
		ustr = tb.text.ustring()
		// The string is too long
		if tb.max_len > 0 && ustr.len >= tb.max_len {
			// tb.text = tb.text.limit(tb.max_len)
			unsafe {
				*tb.text = ustr.left(tb.max_len)
			}
			ustr = tb.text.ustring()
		}
	}
	// tb.cursor_pos += tb.text.len - old_len
	tb.cursor_pos += ustr.len - old_len
	tb.sel_start = 0
	tb.sel_end = 0
}
