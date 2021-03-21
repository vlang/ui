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
pub mut:
	offset_x int
	offset_y int
mut:
	text      string
	parent    Layout
	x         int
	y         int
	width     int
	height    int
	z_index   int
	ui        &UI
	items     []MenuItem
	text_cfg  gx.TextCfg
	text_size f64
	hidden    bool
}

pub struct MenuConfig {
	width     int = 150
	z_index   int
	text_cfg  gx.TextCfg
	text_size f64
	text      string
	items     []MenuItem
}

pub type MenuItemFn = fn (m &Menu, item &MenuItem, state voidptr)

pub struct MenuItem {
mut:
	action MenuItemFn = MenuItemFn(0)
pub mut:
	text string
}

fn (mut m Menu) init(parent Layout) {
	m.parent = parent
	ui := parent.get_ui()
	m.ui = ui
	init_text_cfg<Menu>(mut m)
	m.update_height()
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, menu_click, m)
}

pub fn menu(c MenuConfig) &Menu {
	return &Menu{
		text: c.text
		items: c.items
		width: c.width
		ui: 0
		z_index: c.z_index
		text_cfg: c.text_cfg
		text_size: c.text_size
	}
}

fn menu_click(mut m Menu, e &MouseEvent, window &Window) {
	if m.point_inside(e.x, e.y) {
		i := int((e.y - m.y - m.offset_y) / menu_height)
		item := m.items[i]
		if item.action != MenuItemFn(0) {
			parent := m.parent
			state := parent.get_state()
			item.action(&m, &item, state)
		}
	}
}

fn (mut m Menu) set_pos(x int, y int) {
	m.x = x
	m.y = y
}

fn (mut m Menu) update_height() {
	m.height = m.items.len * ui.menu_height
}

fn (mut m Menu) size() (int, int) {
	m.update_height()
	return m.width, m.height
}

fn (mut m Menu) propose_size(w int, h int) (int, int) {
	m.width = w
	m.height = h
	return m.width, m.height
}

fn (mut m Menu) draw() {
	offset_start(mut m)
	if m.hidden {
		return
	}
	gg := m.ui.gg
	gg.draw_rect(m.x, m.y, m.width, m.height, ui.menu_color)
	gg.draw_empty_rect(m.x, m.y, m.width, m.height, ui.menu_border_color)
	for i, item in m.items {
		m.ui.gg.draw_text_def(m.x + 10, m.y + i * ui.menu_height + 10, item.text)
	}
	offset_end(mut m)
}

pub fn (mut m Menu) add_item(text string, action MenuItemFn) {
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
	return point_inside<Menu>(m, x, y)
}

pub fn (mut m Menu) set_text(s string) {
	m.text = s
}
