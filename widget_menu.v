// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	menu_height       = 30
	menu_width        = 150
	menu_padding      = 10
	menu_bg_color     = gx.rgb(240, 240, 240)
	menu_border_color = gx.rgb(223, 223, 223)
)

[heap]
pub struct Menu {
pub mut:
	id       string
	offset_x int
	offset_y int
	hidden   bool
	ui       &UI
	// Style
	theme_style  string
	style        MenuShapeStyle
	style_forced MenuStyleParams
	// text styles
	text_styles TextStyles
	component   voidptr
	width       int
	height      int
mut:
	text        string
	parent      Layout = empty_stack
	x           int
	y           int
	dx          int
	dy          int = 1
	z_index     int
	items       []MenuItem
	orientation Orientation = Orientation.vertical
}

[params]
pub struct MenuParams {
	MenuStyleParams
	id      string
	width   int = ui.menu_width
	height  int = ui.menu_height
	z_index int
	// text_size f64
	text   string
	items  []MenuItem
	hidden bool
	theme  string = no_style
}

pub type MenuItemFn = fn (item &MenuItem, state voidptr)

[params]
pub struct MenuItem {
pub mut:
	text    string
	submenu &Menu = 0
	menu    &Menu = 0
mut:
	action MenuItemFn = MenuItemFn(0)
}

pub fn menu(c MenuParams) &Menu {
	mut m := &Menu{
		id: c.id
		text: c.text
		items: c.items
		width: c.width
		height: c.height
		ui: 0
		z_index: c.z_index
		style_forced: c.MenuStyleParams
		hidden: c.hidden
	}
	m.style_forced.style = c.theme
	// connect parent menu
	for mut item in m.items {
		item.menu = m
	}
	return m
}

pub fn menu_main(c MenuParams) &Menu {
	mut m := menu(c)
	m.orientation = .horizontal
	m.dx, m.dy = 1, 0
	return m
}

pub fn menuitem(p MenuItem) MenuItem {
	return p
}

fn (mut m Menu) init(parent Layout) {
	m.parent = parent
	ui := parent.get_ui()
	m.ui = ui
	m.load_style()
	m.update_size()
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, menu_click, m)
}

// fn (mut m Menu) init_style() {
// 	mut dtw := DrawTextWidget(m)
// 	dtw.init_style()
// 	dtw.update_text_size(m.text_size)
// }

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
		i := if m.orientation == .vertical {
			int((e.y - m.y - m.offset_y) / ui.menu_height)
		} else {
			int((e.x - m.x - m.offset_y) / ui.menu_width)
		}
		item := m.items[i]
		if item.submenu != 0 {
			// item.open()
		}
		if item.action != voidptr(0) {
			parent := m.parent
			state := parent.get_state()
			item.action(&item, state)
		}
	}
}

pub fn (mut m Menu) set_pos(x int, y int) {
	m.x = x
	m.y = y
}

fn (mut m Menu) update_size() {
	if m.orientation == .vertical {
		m.height = m.items.len * ui.menu_height
	} else {
		m.width = m.items.len * ui.menu_width
	}
}

pub fn (mut m Menu) size() (int, int) {
	m.update_size()
	return m.width, m.height
}

pub fn (mut m Menu) propose_size(w int, h int) (int, int) {
	m.width = w
	m.height = h
	return m.width, m.height
}

fn (mut m Menu) draw() {
	m.draw_device(m.ui.gg)
}

fn (mut m Menu) draw_device(d DrawDevice) {
	offset_start(mut m)
	if m.hidden {
		return
	}
	dtw := DrawTextWidget(m)
	dtw.draw_device_load_style(d)

	d.draw_rect_filled(m.x, m.y, m.width, m.height, m.style.bg_color)
	d.draw_rect_empty(m.x, m.y, m.width, m.height, m.style.border_color)

	for i, item in m.items {
		dtw.draw_device_text(d, m.x + i * m.dx * ui.menu_width + ui.menu_padding, m.y +
			i * m.dy * ui.menu_height + ui.menu_padding, item.text)
	}
	offset_end(mut m)
}

pub fn (mut m Menu) add_item(text string, action MenuItemFn) {
	m.items << MenuItem{
		text: text
		action: action
	}
}

pub fn (mut m Menu) set_visible(state bool) {
	m.hidden = !state
}

fn (m &Menu) point_inside(x f64, y f64) bool {
	return point_inside(m, x, y)
}

pub fn (mut m Menu) set_text(s string) {
	m.text = s
}
