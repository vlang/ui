// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	menu_height       = 30
	menu_color        = gx.rgb(240, 240, 240)
	menu_border_color = gx.rgb(223, 223, 223)
)

pub struct Menu {
mut:
	text    string
	parent  Layout
	x       int
	y       int
	z_index int
	ui      &UI
	items   []MenuItem
	hidden  bool
}

pub struct MenuConfig {
	z_index int
	text    string
	items   []MenuItem
}

pub type MenuFn = fn ()

pub struct MenuItem {
	text   string
	action MenuFn
}

fn (mut m Menu) init(parent Layout) {
	ui := parent.get_ui()
	m.ui = ui
}

pub fn menu(c MenuConfig) &Menu {
	return &Menu{
		text: c.text
		items: c.items
		ui: 0
		z_index: c.z_index
	}
}

fn (mut m Menu) set_pos(x int, y int) {
	m.x = x
	m.y = y
}

fn (mut m Menu) size() (int, int) {
	return 0, 0
}

fn (mut m Menu) propose_size(w int, h int) (int, int) {
	// m.width = w
	// m.height = h
	return 0, 0
}

fn (mut m Menu) draw() {
	if m.hidden {
		return
	}
	gg := m.ui.gg
	gg.draw_rect(m.x, m.y, 150, m.items.len * ui.menu_height, ui.menu_color)
	gg.draw_empty_rect(m.x, m.y, 150, m.items.len * ui.menu_height, ui.menu_border_color)
	for i, item in m.items {
		m.ui.gg.draw_text_def(m.x + 10, m.y + i * ui.menu_height + 10, item.text)
	}
}

pub fn (mut m Menu) add_item(text string, action MenuFn) {
	m.items << MenuItem{
		text: text
		action: action
	}
}

fn (mut m Menu) set_visible(state bool) {
	m.hidden = state
}

fn (m &Menu) focus() {
}

fn (m &Menu) is_focused() bool {
	return false
}

fn (m &Menu) unfocus() {
}

fn (m &Menu) point_inside(x f64, y f64) bool {
	return false // x >= m.x && x <= m.x + m.width && y >= m.y && y <= m.y + m.height
}

pub fn (mut m Menu) set_text(s string) {
	m.text = s
}
