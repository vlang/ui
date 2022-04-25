// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

const (
	menu_height         = 30
	menu_width          = 150
	menu_padding        = 10
	menu_bg_color       = gx.rgb(240, 240, 240)
	menu_bg_color_hover = gx.rgb(220, 220, 220)
	menu_border_color   = gx.rgb(123, 123, 123)
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
	item_width  int
	item_height int
	hovered     int = -1
	selected    int = -1
mut:
	text        string
	parent      Layout = empty_stack
	x           int
	y           int
	dx          int
	dy          int = 1
	z_index     int
	items       []&MenuItem
	parent_menu &Menu       = 0 // for submenu
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
	items  []&MenuItem
	hidden bool
	theme  string = no_style
}

pub fn menu(c MenuParams) &Menu {
	mut m := &Menu{
		id: c.id
		text: c.text
		items: c.items
		width: c.width
		height: c.height
		item_width: c.width
		item_height: c.height
		ui: 0
		z_index: c.z_index
		style_forced: c.MenuStyleParams
		hidden: c.hidden
	}
	m.style_forced.style = c.theme
	// connect parent menu
	for i, mut item in m.items {
		item.menu = m
		item.pos = i
		if item.id == '' {
			item.id = '$i'
		}
	}
	return m
}

pub fn menubar(c MenuParams) &Menu {
	mut m := menu(c)
	m.orientation = .horizontal
	m.dx, m.dy = 1, 0
	return m
}

fn (mut m Menu) init(parent Layout) {
	m.parent = parent
	ui := parent.get_ui()
	m.ui = ui
	m.load_style()
	m.update_size()
	for mut item in m.items {
		item.init()
	}
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, menu_click, m)
	subscriber.subscribe_method(events.on_mouse_move, menu_mouse_move, m)
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
		m.selected = if m.orientation == .vertical {
			int((e.y - m.y - m.offset_y) / m.item_height)
		} else {
			int((e.x - m.x - m.offset_y) / m.item_width)
		}
		mut item := m.items[m.selected]
		if item.submenu != 0 {
			println('toggle submenu $item.id')
			item.submenu.parent_menu = item.menu
			item.toggle_submenu()
		}
		if item.action != voidptr(0) {
			parent := m.parent
			state := parent.get_state()
			item.action(item, state)
		}
	}
}

fn menu_mouse_move(mut m Menu, e &MouseMoveEvent, window &Window) {
	if m.hidden {
		return
	}
	if m.point_inside(e.x, e.y) {
		m.hovered = if m.orientation == .vertical {
			int((e.y - m.y - m.offset_y) / m.item_height)
		} else {
			int((e.x - m.x - m.offset_y) / m.item_width)
		}

		// if item.submenu != 0 {
		// 	println('open submenu $item.id')
		// 	item.open_submenu()
		// }
	} else {
		m.hovered = -1
	}
}

pub fn (mut m Menu) set_pos(x int, y int) {
	println('set_pos $m.id $x, $y')
	m.x = x
	m.y = y
}

fn (mut m Menu) update_size() {
	if m.orientation == .vertical {
		m.height = m.items.len * m.item_height
	} else {
		m.width = m.items.len * m.item_width
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
		// println("item <$m.id> $m.x, $m.y")
		if m.hovered >= 0 && i == m.hovered {
			d.draw_rect_filled(m.x + i * m.dx * m.item_width, m.y + i * m.dy * m.item_height,
				m.item_width, m.item_height, m.style.bg_color_hover)
		}
		dtw.draw_device_text(d, m.x + i * m.dx * m.item_width + ui.menu_padding, m.y +
			i * m.dy * m.item_height + ui.menu_padding, item.text)
	}
	offset_end(mut m)
}

pub fn (mut m Menu) add_item(p MenuItemParams) {
	m.items << menuitem(p)
}

pub fn (mut m Menu) set_visible(state bool) {
	m.hidden = !state
}

pub fn (mut m Menu) set_children_visible(state bool) {
	m.set_visible(state)
	if m.selected >= 0 {
		mut item := m.items[m.selected]
		if item.has_submenu() {
			item.submenu.set_children_visible(state)
		}
	}
}

fn (m &Menu) point_inside(x f64, y f64) bool {
	return point_inside(m, x, y)
}

pub fn (mut m Menu) set_text(s string) {
	m.text = s
}

pub type MenuItemFn = fn (item &MenuItem, state voidptr)

[heap]
pub struct MenuItem {
pub mut:
	id      string
	text    string
	pos     int
	submenu &Menu = 0
	menu    &Menu = 0
mut:
	action MenuItemFn
}

[params]
pub struct MenuItemParams {
	id      string
	text    string
	submenu &Menu      = 0
	action  MenuItemFn = MenuItemFn(0)
}

pub fn menuitem(p MenuItemParams) &MenuItem {
	mi := &MenuItem{
		text: p.text
		id: p.id
		action: p.action
		submenu: p.submenu
	}
	return mi
}

fn (mut mi MenuItem) init() {
	mi.id = mi.menu.id + '/' + mi.id
	if mi.submenu != 0 {
		mi.submenu.id = '$mi.id'
		mi.menu.ui.window.add_top_layer(mi.submenu)
		mi.submenu.set_visible(false)
		println('add_top_layer $mi.submenu.id')
		println('<$mi.submenu.id> $mi.submenu.x, $mi.submenu.y')
		println('${mi.menu.ui.window.top_layer.children.map(it.id)}')
	}
}

pub fn (mi &MenuItem) has_submenu() bool {
	return mi.submenu != 0
}

pub fn (mut mi MenuItem) toggle_submenu() {
	if mi.submenu.hidden {
		mi.set_pos_submenu()
		mi.submenu.set_visible(true)
	} else {
		mi.submenu.set_children_visible(false)
	}
}

pub fn (mut mi MenuItem) set_submenu_visible(state bool) {
	if state {
		mi.set_pos_submenu()
		mi.submenu.set_visible(true)
	} else {
		mi.submenu.set_children_visible(false)
	}
}

pub fn (mut mi MenuItem) set_pos_submenu() {
	if mi.submenu == voidptr(0) {
		return
	}
	if mi.menu.orientation == .horizontal {
		mi.submenu.set_pos(mi.menu.x + mi.pos * mi.menu.item_width, mi.menu.y + mi.menu.item_height)
	} else {
		mi.submenu.set_pos(mi.menu.x + mi.menu.item_width, mi.menu.y + mi.pos * mi.menu.item_height)
	}
}
