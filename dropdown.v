// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	dropdown_height = 25
	dropdown_width = 150
	dropdown_color=gx.rgb(240, 240, 240)
	border_color=gx.rgb(223,223,223)
	drawer_color = gx.rgb(255,255,255)
)

pub type SelectionChangedFn fn(voidptr, voidptr)

pub struct Dropdown {
mut:
	def_text string
	width	int = 150
	parent Layout
	x      int
	y      int

	ui     &UI
	items []DropdownItem
	open bool
	selected_index int
	hover_index    int
	is_focused     bool
	on_selection_changed SelectionChangedFn
}

pub struct DropdownConfig {
	def_text   string
	x      int
	y      int
	width  int
	parent Layout
	items []DropdownItem
	selected_index int = -1
	on_selection_changed SelectionChangedFn
}

pub struct DropdownItem {
pub:
	text string
}

fn (dd mut Dropdown)init(parent Layout) {
	dd.parent = parent
	ui := parent.get_ui()
	dd.ui = ui
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, dd_click, dd)
	subscriber.subscribe_method(events.on_key_down, dd_key_down, dd)
	subscriber.subscribe_method(events.on_mouse_move, dd_mouse_move, dd)
}

pub fn dropdown(c DropdownConfig) &Dropdown {
	mut dd := &Dropdown{
		width: c.width
		items: c.items
		selected_index: c.selected_index
		on_selection_changed: c.on_selection_changed
		def_text: c.def_text
		ui: 0
	}
	return dd
}

fn (dd mut Dropdown) set_pos(x, y int) {
	dd.x = x
	dd.y = y
}

fn (b mut Dropdown) size() (int, int) {
	return b.width, dropdown_height
}

fn (dd mut Dropdown) propose_size(w, h int) (int, int) {
	dd.width = w
	//b.height = h
	return w, dropdown_height
}

fn (dd mut Dropdown) draw() {
	gg := dd.ui.gg
	mut ft := dd.ui.ft

	//draw the main dropdown
	gg.draw_rect(dd.x, dd.y, dd.width, dropdown_height, dropdown_color)
	gg.draw_empty_rect(dd.x, dd.y, dd.width, dropdown_height, border_color)
	if dd.selected_index >= 0 {
		ft.draw_text_def(dd.x + 5, dd.y + 5, dd.items[dd.selected_index].text)
	} else {
		ft.draw_text_def(dd.x + 5, dd.y + 5, dd.def_text)
	}

	//draw the drawer
	if dd.open {
		gg.draw_rect(dd.x, dd.y + dropdown_height, dd.width, dd.items.len * dropdown_height, drawer_color)
		gg.draw_empty_rect(dd.x, dd.y + dropdown_height, dd.width, dd.items.len * dropdown_height, border_color)
		y := dd.y + dropdown_height
		for i, item in dd.items {
			color := if i == dd.hover_index {border_color} else {drawer_color}
			gg.draw_rect(dd.x, y + i * dropdown_height, dd.width, dropdown_height, color)
			gg.draw_empty_rect(dd.x, y + i * dropdown_height, dd.width, dropdown_height, border_color)
			dd.ui.ft.draw_text_def(dd.x + 5, y + i * dropdown_height + 5, item.text)
		}
	}
	//draw the arrow
	gg.draw_image(dd.x + (dd.width - 28), dd.y - 3, 28, 28, dd.ui.down_arrow)
}

pub fn (dd mut Dropdown) add_item(text string) {
	dd.items << DropdownItem{text}
}

fn dd_key_down(dd mut Dropdown, e &KeyEvent, zzz voidptr) {
	if dd.hover_index < 0 {
		dd.hover_index = 0
		return
	}
	match e.key {
		.arrow_down {
			if !dd.open {
				dd.open_drawer()
				return
			}
			if dd.hover_index < dd.items.len - 1{ dd.hover_index++ }
		}
		.escape {
			dd.unfocus()
		}
		.arrow_up {
			if dd.hover_index > 0 {
				dd.hover_index--
			}
		}
		.enter {
			dd.selected_index = dd.hover_index
			dd.unfocus()
		} else {}
	}
}

fn dd_click(dd mut Dropdown, e &MouseEvent, zzz voidptr) {
	if !dd.point_inside(e.x, e.y) || e.action == 1 {return}

	if e.y >= dd.y && e.y <= dd.y + dropdown_height && e.x >= dd.x && e.x <= dd.x + dd.width {
		dd.open_drawer()
	} else if dd.open {
		th := dd.y + (dd.items.len * dropdown_height)
		index := ((e.y * dd.items.len) / th) - 1
		dd.selected_index = index
		if dd.on_selection_changed != 0 {
			parent := dd.parent
			state := parent.get_state()
			dd.on_selection_changed(state, dd)
		}
		dd.unfocus()
	}
}

fn dd_mouse_move(dd mut Dropdown, e &MouseEvent, zzz voidptr) {
	if dd.open {
		th := dd.y + (dd.items.len * dropdown_height)
		index := ((e.y * dd.items.len) / th) - 1
		dd.hover_index = index
	}
}

fn (dd mut Dropdown) focus() {
	dd.is_focused = true
}

fn (dd mut Dropdown) open_drawer() {
	dd.open = !dd.open
	if !dd.open {
		dd.hover_index = dd.selected_index
	}
	dd.focus()
}

fn (dd &Dropdown) is_focused() bool {
	return dd.is_focused
}

fn (dd mut Dropdown) unfocus() {
	dd.open = false
	dd.is_focused = false
}

fn (dd &Dropdown) point_inside(x, y f64) bool {
	return y >= dd.y && y <= dd.y + (dd.items.len * dropdown_height) + dropdown_height && x >= dd.x && x <= dd.x + dd.width
}
