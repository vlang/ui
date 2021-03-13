// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	dropdown_height = 25
	dropdown_width  = 150
	dropdown_color  = gx.rgb(240, 240, 240)
	border_color    = gx.rgb(223, 223, 223)
	drawer_color    = gx.rgb(255, 255, 255)
)

pub type SelectionChangedFn = fn (arg_1 voidptr, arg_2 voidptr)

pub struct Dropdown {
mut:
	def_text             string
	width                int = 150
	parent               Layout
	x                    int
	y                    int
	z_index              int
	ui                   &UI
	items                []DropdownItem
	open                 bool
	selected_index       int
	hover_index          int
	is_focused           bool
	on_selection_changed SelectionChangedFn
	hidden               bool
}

pub struct DropdownConfig {
	def_text             string
	x                    int
	y                    int
	width                int
	z_index              int = 10
	parent               Layout
	selected_index       int = -1
	on_selection_changed SelectionChangedFn
}

pub struct DropdownItem {
pub:
	text string
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

pub fn dropdown(c DropdownConfig, items []DropdownItem) &Dropdown {
	mut dd := &Dropdown{
		width: c.width
		z_index: c.z_index
		items: items
		selected_index: c.selected_index
		on_selection_changed: c.on_selection_changed
		def_text: c.def_text
		ui: 0
	}
	return dd
}

fn (mut dd Dropdown) set_pos(x int, y int) {
	dd.x = x
	dd.y = y
}

fn (mut dd Dropdown) size() (int, int) {
	return dd.width, ui.dropdown_height
}

fn (mut dd Dropdown) propose_size(w int, h int) (int, int) {
	dd.width = w
	// dd.height = h
	return w, ui.dropdown_height
}

fn (dd &Dropdown) draw() {
	gg := dd.ui.gg
	// draw the main dropdown
	gg.draw_rect(dd.x, dd.y, dd.width, ui.dropdown_height, ui.dropdown_color)
	gg.draw_empty_rect(dd.x, dd.y, dd.width, ui.dropdown_height, ui.border_color)
	if dd.selected_index >= 0 {
		gg.draw_text_def(dd.x + 5, dd.y + 5, dd.items[dd.selected_index].text)
	} else {
		gg.draw_text_def(dd.x + 5, dd.y + 5, dd.def_text)
	}
	dd.draw_open()
	// draw the arrow
	gg.draw_image(dd.x + (dd.width - 28), dd.y - 3, 28, 28, dd.ui.down_arrow)
}

fn (dd &Dropdown) draw_open() {
	// draw the drawer
	if dd.open {
		gg := dd.ui.gg
		gg.draw_rect(dd.x, dd.y + ui.dropdown_height, dd.width, dd.items.len * ui.dropdown_height,
			ui.drawer_color)
		gg.draw_empty_rect(dd.x, dd.y + ui.dropdown_height, dd.width, dd.items.len * ui.dropdown_height,
			ui.border_color)
		y := dd.y + ui.dropdown_height
		for i, item in dd.items {
			color := if i == dd.hover_index { ui.border_color } else { ui.drawer_color }
			gg.draw_rect(dd.x, y + i * ui.dropdown_height, dd.width, ui.dropdown_height,
				color)
			gg.draw_empty_rect(dd.x, y + i * ui.dropdown_height, dd.width, ui.dropdown_height,
				ui.border_color)
			gg.draw_text_def(dd.x + 5, y + i * ui.dropdown_height + 5, item.text)
		}
	}
}

pub fn (mut dd Dropdown) add_item(text string) {
	dd.items << DropdownItem{text}
}

fn dd_key_down(mut dd Dropdown, e &KeyEvent, zzz voidptr) {
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
	if !dd.point_inside(e.x, e.y) || e.action == .down {
		return
	}
	if e.y >= dd.y && e.y <= dd.y + ui.dropdown_height && e.x >= dd.x && e.x <= dd.x + dd.width {
		dd.open_drawer()
	} else if dd.open {
		th := dd.y + (dd.items.len * ui.dropdown_height)
		index := ((e.y * dd.items.len) / th) - 1
		dd.selected_index = index
		if dd.on_selection_changed != voidptr(0) {
			parent := dd.parent
			state := parent.get_state()
			dd.on_selection_changed(state, dd)
		}
		dd.unfocus()
	}
}

fn dd_mouse_move(mut dd Dropdown, e &MouseEvent, zzz voidptr) {
	if dd.open {
		th := dd.y + (dd.items.len * ui.dropdown_height)
		index := ((e.y * dd.items.len) / th) - 1
		dd.hover_index = index
	}
}

fn (mut dd Dropdown) set_visible(state bool) {
	dd.hidden = state
}

fn (mut dd Dropdown) focus() {
	dd.is_focused = true
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
	return y >= dd.y && y <= dd.y + (dd.items.len * ui.dropdown_height) + ui.dropdown_height
		&& x >= dd.x && x <= dd.x + dd.width
}

// Returns the currently selected DropdownItem
pub fn (dd &Dropdown) selected() DropdownItem {
	return dd.items[dd.selected_index]
}
