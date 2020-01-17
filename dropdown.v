// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	dropdown_height = 30
	dropdown_color=gx.rgb(240, 240, 240)
	dropdown_border_color=gx.rgb(223,223,223)
)

pub struct Dropdown {
mut:
	text   string
	parent &ui.Window
	x      int
	y      int
	idx    int
	ui     &UI
	items []DropdownItem
	visible bool
	selected_index int
}

pub struct DropdownConfig {
	x      int
	y      int
	parent &ui.Window
	text   string
	items []DropdownItem
	selected_index int = 0
}

pub type DropdownFn fn()

pub struct DropdownItem {
	text string
	action DropdownFn
}

pub fn new_dropdown(c DropdownConfig) &Dropdown {
	mut l := &Dropdown{
		text: c.text
		x: c.x
		y: c.y
		parent: c.parent
		ui: c.parent.ui
		items: c.items
		selected_index: c.selected_index
	}
	l.parent.children << l
	return l
}

fn (m mut Dropdown) draw() {
	gg := m.ui.gg
	ft := m.ui.ft

	gg.draw_rect(m.x, m.y, 150, dropdown_height, dropdown_color)
	gg.draw_empty_rect(m.x, m.y, 150, dropdown_height, dropdown_border_color)
	ft.draw_text_def(m.x + 5, m.y + 5, m.items[m.selected_index].text)
	/* if !m.visible {
		return
	}
	
	gg.draw_rect(m.x, m.y, 150, m.items.len * dropdown_height, dropdown_color)
	gg.draw_empty_rect(m.x, m.y, 150, m.items.len * dropdown_height, dropdown_border_color)
	for i, item in m.items {
		m.ui.ft.draw_text_def(m.x + 10, m.y + i * dropdown_height  +10, item.text)
	} */
}

pub type DropdownClickFn fn()

pub fn (m mut Dropdown) add_item(text string, action DropdownFn) {
	m.items << DropdownItem{text:text, action: action}

}

fn (t &Dropdown) key_down(e KeyEvent) {}

fn (t &Dropdown) click(e MouseEvent) {
}

fn (t &Dropdown) mouse_move(e MouseEvent) {
}

fn (t &Dropdown) focus() {}

fn (t &Dropdown) idx() int {
	return t.idx
}

fn (t &Dropdown) typ() WidgetType {
	return .Dropdown
}

fn (t &Dropdown) is_focused() bool {
	return false
}

fn (t &Dropdown) unfocus() {}

fn (t &Dropdown) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

pub fn (l mut Dropdown) set_text(s string) {
	l.text = s
}
