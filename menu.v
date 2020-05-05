// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	menu_height = 30
	menu_color=gx.rgb(240, 240, 240)
	menu_border_color=gx.rgb(223,223,223)
)

pub struct Menu {
mut:
	text   string
	parent Layout
	x      int
	y      int
	ui     &UI
	items []MenuItem
	visible bool
}

pub struct MenuConfig {
	text   string
	items []MenuItem
}

pub type MenuFn fn()

pub struct MenuItem {
	text string
	action MenuFn
}

fn (m mut Menu)init(parent Layout) {
	ui := parent.get_ui()
	m.ui = ui
}

pub fn menu(c MenuConfig) &Menu {
	return &Menu {
		text: c.text
		items: c.items
		ui: 0
	}
}

fn (b mut Menu) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut Menu) size() (int, int) {
	return 0, 0
}

fn (b mut Menu) propose_size(w, h int) (int, int) {
	//b.width = w
	//b.height = h
	return 0,0
}

fn (m mut Menu) draw() {
	if !m.visible {
		return
	}
	gg := m.ui.gg
	gg.draw_rect(m.x, m.y, 150, m.items.len * menu_height, menu_color)
	gg.draw_empty_rect(m.x, m.y, 150, m.items.len * menu_height, menu_border_color)
	for i, item in m.items {
		m.ui.ft.draw_text_def(m.x + 10, m.y + i * menu_height  +10, item.text)
	}
}

pub fn (m mut Menu) add_item(text string, action MenuFn) {
	m.items << MenuItem{text:text, action: action}

}

fn (t &Menu) focus() {}

fn (t &Menu) is_focused() bool {
	return false
}

fn (t &Menu) unfocus() {}

fn (t &Menu) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

pub fn (l mut Menu) set_text(s string) {
	l.text = s
}
