// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	dropdown_color = gx.rgb(240, 240, 240)
	border_color   = gx.rgb(223, 223, 223)
	drawer_color   = gx.rgb(255, 255, 255)
)

pub type SelectionChangedFn = fn (arg_1 voidptr, arg_2 voidptr)

[heap]
pub struct Dropdown {
pub mut:
	id                   string
	def_text             string
	width                int = 150
	dropdown_height      int
	parent               Layout = empty_stack
	x                    int
	y                    int
	offset_x             int
	offset_y             int
	z_index              int
	ui                   &UI
	items                []DropdownItem
	open                 bool
	selected_index       int
	hover_index          int
	is_focused           bool
	on_selection_changed SelectionChangedFn
	hidden               bool
	// component state for composable widget
	component voidptr
}

pub struct DropdownConfig {
	id       string
	def_text string
	x        int
	y        int
	width    int = 150
	height   int = 25
	z_index  int = 10
	selected_index       int = -1
	on_selection_changed SelectionChangedFn
	items                []DropdownItem
}

pub struct DropdownItem {
pub:
	text string
}

pub fn dropdown(c DropdownConfig) &Dropdown {
	mut dd := &Dropdown{
		id: c.id
		width: c.width
		dropdown_height: c.height
		z_index: c.z_index
		items: c.items
		selected_index: c.selected_index
		on_selection_changed: c.on_selection_changed
		def_text: c.def_text
		ui: 0
	}
	return dd
}

fn (mut dd Dropdown) init(parent Layout) {
	dd.parent = parent
	ui := parent.get_ui()
	dd.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, dd_click, dd)
	subscriber.subscribe_method(events.on_key_down, dd_key_down, dd)
	subscriber.subscribe_method(events.on_mouse_move, dd_mouse_move, dd)
}

[manualfree]
fn (mut dd Dropdown) cleanup() {
	mut subscriber := dd.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, dd)
	subscriber.unsubscribe_method(events.on_key_down, dd)
	subscriber.unsubscribe_method(events.on_mouse_move, dd)
	unsafe { dd.free() }
}

[unsafe]
pub fn (dd &Dropdown) free() {
	$if free ? {
		print('dropdown $dd.id')
	}
	unsafe {
		dd.id.free()
		dd.def_text.free()
		for item in dd.items {
			item.text.free()
		}
		dd.items.free()
		free(dd)
	}
	$if free ? {
		println(' -> freed')
	}
}

pub fn (mut dd Dropdown) set_pos(x int, y int) {
	dd.x = x
	dd.y = y
}

pub fn (mut dd Dropdown) size() (int, int) {
	return dd.width, dd.dropdown_height
}

pub fn (mut dd Dropdown) propose_size(w int, h int) (int, int) {
	dd.width = w
	// dd.height = h
	return w, dd.dropdown_height
}

fn (mut dd Dropdown) draw() {
	offset_start(mut dd)
	gg := dd.ui.gg
	// draw the main dropdown
	gg.draw_rect(dd.x, dd.y, dd.width, dd.dropdown_height, ui.dropdown_color)
	gg.draw_empty_rect(dd.x, dd.y, dd.width, dd.dropdown_height, ui.border_color)
	if dd.selected_index >= 0 {
		gg.draw_text_def(dd.x + 5, dd.y + 5, dd.items[dd.selected_index].text)
	} else {
		gg.draw_text_def(dd.x + 5, dd.y + 5, dd.def_text)
	}
	dd.draw_open()
	// draw the arrow
	gg.draw_image(dd.x + (dd.width - 28), dd.y - 3, 28, 28, dd.ui.down_arrow)
	offset_end(mut dd)
}

fn (dd &Dropdown) draw_open() {
	// draw the drawer
	if dd.open {
		gg := dd.ui.gg
		gg.draw_rect(dd.x, dd.y + dd.dropdown_height, dd.width, dd.items.len * dd.dropdown_height,
			ui.drawer_color)
		gg.draw_empty_rect(dd.x, dd.y + dd.dropdown_height, dd.width, dd.items.len * dd.dropdown_height,
			ui.border_color)
		y := dd.y + dd.dropdown_height
		for i, item in dd.items {
			color := if i == dd.hover_index { ui.border_color } else { ui.drawer_color }
			gg.draw_rect(dd.x, y + i * dd.dropdown_height, dd.width, dd.dropdown_height,
				color)
			gg.draw_empty_rect(dd.x, y + i * dd.dropdown_height, dd.width, dd.dropdown_height,
				ui.border_color)
			gg.draw_text_def(dd.x + 5, y + i * dd.dropdown_height + 5, item.text)
		}
	}
}

pub fn (mut dd Dropdown) add_item(text string) {
	dd.items << DropdownItem{text}
}

fn dd_key_down(mut dd Dropdown, e &KeyEvent, zzz voidptr) {
	if dd.hidden || !dd.is_focused {
		return
	}
	if dd.hover_index < 0 {
		dd.hover_index = 0
		return
	}
	match e.key {
		.down {
			if !dd.open {
				dd.open_drawer()
				return
			}
			if dd.hover_index < dd.items.len - 1 {
				dd.hover_index++
			}
		}
		.escape {
			dd.unfocus()
		}
		.up {
			if dd.hover_index > 0 {
				dd.hover_index--
			}
		}
		.enter {
			dd.selected_index = dd.hover_index
			if dd.on_selection_changed != voidptr(0) {
				parent := dd.parent
				state := parent.get_state()
				dd.on_selection_changed(state, dd)
			}
			dd.unfocus()
		}
		else {}
	}
}

fn dd_click(mut dd Dropdown, e &MouseEvent, zzz voidptr) {
	if dd.hidden {
		return
	}
	if !dd.point_inside(e.x, e.y) || e.action == .down {
		dd.unfocus()
		return
	}
	offset_start(mut dd)
	if e.y >= dd.y && e.y <= dd.y + dd.dropdown_height && e.x >= dd.x && e.x <= dd.x + dd.width {
		dd.open_drawer()
	} else if dd.open {
		th := dd.y + (dd.items.len * dd.dropdown_height)
		index := ((e.y * dd.items.len) / th) - 1
		dd.selected_index = index
		if dd.on_selection_changed != voidptr(0) {
			parent := dd.parent
			state := parent.get_state()
			dd.on_selection_changed(state, dd)
		}
		dd.unfocus()
	}
	offset_end(mut dd)
}

fn dd_mouse_move(mut dd Dropdown, e &MouseEvent, zzz voidptr) {
	if dd.hidden {
		return
	}
	if dd.open {
		th := dd.y + (dd.items.len * dd.dropdown_height)
		index := ((e.y * dd.items.len) / th) - 1
		dd.hover_index = index
	}
}

fn (mut dd Dropdown) set_visible(state bool) {
	dd.hidden = !state
}

fn (mut dd Dropdown) focus() {
	// dd.is_focused = true
	set_focus(dd.ui.window, mut dd)
}

fn (mut dd Dropdown) open_drawer() {
	dd.open = !dd.open
	if !dd.open {
		dd.hover_index = dd.selected_index
	}
	dd.focus()
}

fn (dd &Dropdown) is_focused() bool {
	return dd.is_focused
}

fn (mut dd Dropdown) unfocus() {
	dd.open = false
	dd.is_focused = false
}

fn (dd &Dropdown) point_inside(x f64, y f64) bool {
	ddx, ddy := dd.x + dd.offset_x, dd.y + dd.offset_y
	return y >= ddy && y <= ddy + (dd.items.len * dd.dropdown_height) + dd.dropdown_height
		&& x >= ddx && x <= ddx + dd.width
}

// Returns the currently selected DropdownItem
pub fn (dd &Dropdown) selected() DropdownItem {
	return dd.items[dd.selected_index]
}
