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

[heap]
pub struct Menu {
pub mut:
	id        string
	offset_x  int
	offset_y  int
	hidden    bool
	ui        &UI
	text_cfg  gx.TextCfg
	text_size f64
	component voidptr
	width     int
	height    int
mut:
	text    string
	parent  Layout = empty_stack
	x       int
	y       int
	z_index int
	items   []MenuItem
}

pub type MenuItemFn = fn (m &Menu, item &MenuItem, state voidptr)

pub struct MenuItem {
mut:
	action MenuItemFn
pub mut:
	text string
}

[params]
pub struct MenuParams {
	id        string
	width     int = 150
	z_index   int
	text_cfg  gx.TextCfg
	text_size f64
	text      string
	items     []MenuItem
}

pub fn menu(c MenuParams) &Menu {
	return &Menu{
		id: c.id
		text: c.text
		items: c.items
		width: c.width
		ui: 0
		z_index: c.z_index
		text_cfg: c.text_cfg
		text_size: c.text_size
	}
}

fn (mut m Menu) init(parent Layout) {
	m.parent = parent
	ui := parent.get_ui()
	m.ui = ui
	init_text_cfg(mut m)
	m.update_height()
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, menu_click, m)
}

[manualfree]
pub fn (mut m Menu) cleanup() {
	mut subscriber := m.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, m)
	unsafe { m.free() }
}

[unsafe]
pub fn (m &Menu) free() {
	$if free ? {
		print('menu $m.id')
	}
	unsafe {
		m.id.free()
		m.text.free()
		for item in m.items {
			item.text.free()
		}
		m.items.free()
		free(m)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn menu_click(mut m Menu, e &MouseEvent, window &Window) {
	if m.hidden {
		return
	}
	if m.point_inside(e.x, e.y) {
		i := int((e.y - m.y - m.offset_y) / ui.menu_height)
		item := m.items[i]
		if item.action != voidptr(0) {
			parent := m.parent
			state := parent.get_state()
			item.action(&m, &item, state)
		}
	}
}

pub fn (mut m Menu) set_pos(x int, y int) {
	m.x = x
	m.y = y
}

fn (mut m Menu) update_height() {
	m.height = m.items.len * ui.menu_height
}

pub fn (mut m Menu) size() (int, int) {
	m.update_height()
	return m.width, m.height
}

pub fn (mut m Menu) propose_size(w int, h int) (int, int) {
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
	gg.draw_rect_filled(m.x, m.y, m.width, m.height, ui.menu_color)
	gg.draw_rect_empty(m.x, m.y, m.width, m.height, ui.menu_border_color)
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
	m.hidden = !state
}

fn (m &Menu) point_inside(x f64, y f64) bool {
	return point_inside(m, x, y)
}

pub fn (mut m Menu) set_text(s string) {
	m.text = s
}
