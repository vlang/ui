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
	parent &ui.Window
	x      int
	y      int
	idx    int
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
	parent &ui.Window
	items []DropdownItem
	selected_index int = -1
	on_selection_changed SelectionChangedFn
}

pub struct DropdownItem {
	text string
}

pub fn new_dropdown(c DropdownConfig) &Dropdown {
	mut l := &Dropdown{
		width: c.width
		x: c.x
		y: c.y
		parent: c.parent
		ui: c.parent.ui
		items: c.items
		selected_index: c.selected_index
		idx: c.parent.children.len
		on_selection_changed: c.on_selection_changed
		def_text: c.def_text
	}
	l.parent.children << l
	return l
}

fn (m mut Dropdown) draw() {
	gg := m.ui.gg
	mut ft := m.ui.ft

	//draw the main dropdown
	gg.draw_rect(m.x, m.y, m.width, dropdown_height, dropdown_color)
	gg.draw_empty_rect(m.x, m.y, m.width, dropdown_height, border_color)
	if m.selected_index >= 0 {
		ft.draw_text_def(m.x + 5, m.y + 5, m.items[m.selected_index].text)
	} else {
		ft.draw_text_def(m.x + 5, m.y + 5, m.def_text)
	}

	//draw the drawer
	if m.open {
		gg.draw_rect(m.x, m.y + dropdown_height, m.width, m.items.len * dropdown_height, drawer_color)
		gg.draw_empty_rect(m.x, m.y + dropdown_height, m.width, m.items.len * dropdown_height, border_color)
		y := m.y + dropdown_height
		for i, item in m.items {
			color := if i == m.hover_index {border_color} else {drawer_color}
			gg.draw_rect(m.x, y + i * dropdown_height, m.width, dropdown_height, color)
			gg.draw_empty_rect(m.x, y + i * dropdown_height, m.width, dropdown_height, border_color)
			m.ui.ft.draw_text_def(m.x + 5, y + i * dropdown_height + 5, item.text)
		}
	}
	//draw the arrow
	gg.draw_image(m.x + (m.width - 28), m.y - 3, 28, 28, m.ui.down_arrow)
}

pub fn (m mut Dropdown) add_item(text string) {
	m.items << DropdownItem{text}
}

fn (t mut Dropdown) key_down(e KeyEvent) {
	if t.hover_index < 0 {
		t.hover_index = 0
		return
	}
	match e.key {
		.arrow_down {
			if !t.open {
				t.open_drawer()
				return
			}
			if t.hover_index < t.items.len - 1{ t.hover_index++ }
		}
		.escape {
			t.unfocus()
		}
		.arrow_up {
			if t.hover_index > 0 {
				t.hover_index--
			}
		}
		.enter {
			t.selected_index = t.hover_index
			t.unfocus()
		} else {}
	}
}

fn (t mut Dropdown) click(e MouseEvent) {
	if e.action == 1 {return}
	if e.y >= t.y && e.y <= t.y + dropdown_height && e.x >= t.x && e.x <= t.x + t.width {
		t.open_drawer()
	} else if t.open {
		th := t.y + (t.items.len * dropdown_height)
		index := ((e.y * t.items.len) / th) - 1
		t.selected_index = index
		if t.on_selection_changed != 0 {
			t.on_selection_changed(t.parent.user_ptr, t)
		}
		t.unfocus()
	}
}

fn (t mut Dropdown) mouse_move(e MouseEvent) {
	if t.open {
		th := t.y + (t.items.len * dropdown_height)
		index := ((e.y * t.items.len) / th) - 1
		t.hover_index = index
	}
}

fn (t mut Dropdown) focus() {
	t.is_focused = true
}

fn (t mut Dropdown) open_drawer() {
	t.open = !t.open
	if !t.open {
		t.hover_index = t.selected_index
	}
	t.focus()
}

fn (t &Dropdown) idx() int {
	return t.idx
}

fn (t &Dropdown) typ() WidgetType {
	return .dropdown
}

fn (t &Dropdown) is_focused() bool {
	return t.is_focused
}

fn (t mut Dropdown) unfocus() {
	t.open = false
	t.is_focused = false
}

fn (t &Dropdown) point_inside(x, y f64) bool {
	return y >= t.y && y <= t.y + (t.items.len * dropdown_height) + dropdown_height && x >= t.x && x <= t.x + t.width
}
