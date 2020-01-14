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
	parent &ui.Window
	x      int
	y      int
	idx    int
	ctx    &UI
	items []MenuItem
	visible bool
}

pub struct MenuConfig {
	x      int
	y      int
	parent &ui.Window
	text   string
	items []MenuItem
}

pub type MenuFn fn()

pub struct MenuItem {
	text string
	action MenuFn
}

pub fn new_menu(c MenuConfig) &Menu {
	mut l := &Menu{
		text: c.text
		x: c.x
		y: c.y
		parent: c.parent
		ctx: c.parent.ctx
		items: c.items
	}
	l.parent.children << l
	return l
}

fn (m mut Menu) draw() {
	if !m.visible {
		return
	}
	gg := m.ctx.gg
	gg.draw_rect(m.x, m.y, 150, m.items.len * menu_height, menu_color)
	gg.draw_empty_rect(m.x, m.y, 150, m.items.len * menu_height, menu_border_color)
	for i, item in m.items {
		m.ctx.ft.draw_text_def(m.x + 10, m.y + i * menu_height  +10, item.text)
	}
}

fn (t &Menu) key_down(e KeyEvent) {}

fn (t &Menu) click(e MouseEvent) {
}

fn (t &Menu) focus() {}

fn (t &Menu) idx() int {
	return t.idx
}

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
