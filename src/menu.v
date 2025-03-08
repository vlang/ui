// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import gx

const menu_height = 30
const menu_width = 150
const menu_padding = 10
const menu_bar_color = gx.rgb(230, 230, 230)
const menu_bg_color = gx.rgb(240, 240, 240)
const menu_bg_color_hover = gx.rgb(220, 220, 220)
const menu_border_color = gx.rgb(123, 123, 123)

@[heap]
pub struct Menu {
pub mut:
	id       string
	offset_x int
	offset_y int
	hidden   bool
	ui       &UI = unsafe { nil }
	// Style
	theme_style  string
	style        MenuShapeStyle
	style_params MenuStyleParams
	// text styles
	text_styles TextStyles
	component   voidptr
	width       int
	height      int
	item_width  int
	item_height int
	real_width  int // expanded_width
	fixed_width bool
	hovered     int = -1
	selected    int = -1
mut:
	text      string
	parent    Layout = empty_stack
	x         int
	y         int
	dx        int
	dy        int = 1
	z_index   int
	items     []&MenuItem
	root_menu &Menu = unsafe { nil }
	// for submenu
	parent_item &MenuItem   = unsafe { nil }
	orientation Orientation = Orientation.vertical
}

@[params]
pub struct MenuParams {
	MenuStyleParams
pub:
	id          string
	width       int = menu_width
	height      int = menu_height
	fixed_width bool
	z_index     int = 1000
	// text_size f64
	text   string
	items  []&MenuItem
	hidden bool
	theme  string = no_style
}

pub fn menu(c MenuParams) &Menu {
	mut m := &Menu{
		id:           c.id
		text:         c.text
		items:        c.items
		width:        c.width
		height:       c.height
		item_width:   c.width
		item_height:  c.height
		fixed_width:  c.fixed_width
		ui:           unsafe { nil }
		z_index:      c.z_index
		style_params: c.MenuStyleParams
		hidden:       c.hidden
	}
	m.root_menu = m
	m.style_params.style = c.theme

	// connect parent menu
	for i, mut item in m.items {
		item.pos = i
		if item.id == '' {
			item.id = '${i}'
		}
	}
	return m
}

// main
pub fn menubar(c MenuParams) &Menu {
	mut m := menu(c)
	m.orientation = .horizontal
	m.dx, m.dy = 1, 0
	return m
}

// often activated by right click
pub fn menucontext(c MenuParams) &Menu {
	mut m := menu(c)
	return m
}

fn (mut m Menu) build(mut win Window) {
	// println("menu $m.id build")
	for mut item in m.items {
		item.menu = m
		item.build(mut win)
	}
}

fn (mut m Menu) init(parent Layout) {
	m.parent = parent
	u := parent.get_ui()
	m.ui = u
	m.update_size()
	if m.is_root_menu() {
		m.propagate_connection()
	}
	m.load_style()
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, menu_click, m)
	subscriber.subscribe_method(events.on_mouse_move, menu_mouse_move, m)
	m.ui.window.evt_mngr.add_receiver(m, [events.on_mouse_down])
}

@[manualfree]
pub fn (mut m Menu) cleanup() {
	mut subscriber := m.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, m)
	m.ui.window.evt_mngr.rm_receiver(m, [events.on_mouse_down])
	unsafe { m.free() }
}

@[unsafe]
pub fn (m &Menu) free() {
	$if free ? {
		print('menu ${m.id}')
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

pub fn (m &Menu) is_root_menu() bool {
	return unsafe { m.root_menu != 0 } && m.id == m.root_menu.id
}

pub fn (m &Menu) is_top_layer_menu() bool {
	return m.parent.id == m.ui.window.top_layer.id
}

fn (mut m Menu) propagate_connection() {
	for mut item in m.items {
		// set root_menu for submenu
		item.set_menu_root_menu()
		if item.has_menu() {
			// submenu parent item
			item.submenu.parent_item = item
			item.submenu.propagate_connection()
		}
	}
}

fn menu_click(mut m Menu, e &MouseEvent, window &Window) {
	if m.hidden {
		return
	}
	if m.point_inside(e.x, e.y) {
		selected := m.selected
		m.selected = if m.orientation == .vertical {
			int((e.y - m.y - m.offset_y) / m.item_height)
		} else {
			if m.root_menu.fixed_width {
				int((e.x - m.x - m.offset_y) / m.item_width)
			} else {
				id_hovered(e.x, e.y, mut m)
			}
		}
		mut item := m.items[m.selected]
		mut submenu_to_open := false
		if item.has_menu() {
			submenu_to_open = item.submenu.hidden
		}
		if selected >= 0 && selected != m.selected {
			m.close()
		}
		if item.action != unsafe { MenuItemFn(0) } {
			item.action(item)
		}
		if item.has_menu() {
			// println('toggle menu $item.id')
			// item.toggle_menu()
			item.set_menu(submenu_to_open)
		} else {
			item.menu.root_menu.close()
			m.selected = -1
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
			if m.root_menu.fixed_width {
				int((e.x - m.x - m.offset_x) / m.item_width)
			} else {
				id_hovered(e.x, e.y, mut m)
			}
		}
		if m.hovered < 0 || m.hovered >= m.items.len {
			return
		}
		mut item := m.items[m.hovered]
		if item.has_menu() {
			// println('open submenu $item.id')
			item.submenu.set_all_children_visible(false)
			item.set_menu_visible(true)
		}
		if unsafe { item.menu != 0 } {
			// println('hover close $item.menu.id ${item.menu.items.map(it.id)}')
			for mut mi in item.menu.items {
				if mi.id != item.id && mi.has_menu() {
					mi.submenu.set_all_children_visible(false)
				}
			}
		}
	} else {
		m.hovered = -1
	}
}

pub fn id_hovered(x f64, y f64, mut m Menu) int {
	mut w := m.x
	for i, item in m.items {
		if x > w && x < (w + item.width) {
			return i
		}
		w = w + item.width
	}
	return -1
}

pub fn (mut m Menu) set_pos(x int, y int) {
	// println('set_pos $m.id $x, $y')
	m.x = x
	m.y = y
}

fn (mut m Menu) update_size() {
	if m.orientation == .vertical {
		m.height = m.items.len * m.item_height
		if !m.root_menu.fixed_width {
			mut mw := 0
			mut dtw := DrawTextWidget(m)
			dtw.load_style()
			for mut item in m.items {
				item.width = dtw.text_width(item.text) + menu_padding * 2
				if item.width > mw {
					mw = item.width
				}

				// println("$item.width $item.text")
			}
			for mut item in m.items {
				item.width = mw
			}
		}
	} else {
		if m.root_menu.fixed_width {
			m.width = m.items.len * m.item_width
		} else {
			mut w := 0
			mut dtw := DrawTextWidget(m)
			dtw.load_style()
			for mut item in m.items {
				item.width = dtw.text_width(item.text) + menu_padding * 2
				w = w + item.width
			}
			m.width = w
		}
	}
}

pub fn (mut m Menu) size() (int, int) {
	m.update_size()
	return m.width, m.height
}

pub fn (mut m Menu) propose_size(w int, h int) (int, int) {
	m.width = w
	m.real_width = w
	m.height = h
	// println("w=$m.width h=$m.height")
	m.update_size()
	return m.width, m.height
}

fn (mut m Menu) draw() {
	m.draw_device(mut m.ui.dd)
}

fn (mut m Menu) draw_device(mut d DrawDevice) {
	offset_start(mut m)
	if m.hidden {
		return
	}
	$if layout ? {
		if m.ui.layout_print {
			println('Menu(${m.id}): (${m.x}, ${m.y}, ${m.width}, ${m.height})')
		}
	}
	mut dtw := DrawTextWidget(m.root_menu)
	dtw.draw_device_load_style(d)

	if m.dx == 1 && m.dy == 0 {
		d.draw_rect_filled(m.x, m.y, m.real_width, m.height, m.root_menu.style.bar_color)
		d.draw_rect_empty(m.x, m.y, m.real_width, m.height, m.root_menu.style.border_color)
	}
	if m.root_menu.fixed_width {
		d.draw_rect_filled(m.x, m.y, m.width + m.items.len * m.dx, m.height, m.root_menu.style.bg_color)
		d.draw_rect_empty(m.x, m.y, m.width + m.items.len * m.dx, m.height, m.root_menu.style.border_color)

		for i, item in m.items {
			//	println("item $i <$m.id> $m.x, $m.y, $w, $item.width, $m.dx")
			if m.hovered >= 0 && i == m.hovered {
				d.draw_rect_filled(m.x + i * m.dx * m.item_width + 1, m.y +
					i * m.dy * m.item_height + 1, m.item_width - 1, m.item_height - 2,
					m.root_menu.style.bg_color_hover)
			}

			dtw.draw_device_text(d, m.x + i * m.dx * m.item_width + menu_padding, m.y +
				i * m.dy * m.item_height + menu_padding, item.text)
		}
	} else { // compact menu
		if m.orientation == .vertical {
			mut mw := 0 // find submenu max width
			for item in m.items {
				if item.width > mw {
					mw = item.width
				}
			}

			d.draw_rect_filled(m.x, m.y, mw + m.items.len * m.dx, m.height, m.root_menu.style.bg_color)
			d.draw_rect_empty(m.x, m.y, mw + m.items.len * m.dx, m.height, m.root_menu.style.border_color)

			for i, item in m.items {
				//	println("item $i <$m.id> $m.x, $m.y, $item.width, $m.dx")
				if m.hovered >= 0 && i == m.hovered {
					d.draw_rect_filled(m.x + 1, m.y + i * m.dy * m.item_height + 1, mw - 2,
						m.item_height - 2, m.root_menu.style.bg_color_hover)

					// println("item $i <$m.id> $m.x, $m.y, $item.width, $m.dx")
				}

				dtw.draw_device_text(d, m.x + menu_padding, m.y + i * m.dy * m.item_height +
					menu_padding, item.text)
			}
		} else { // horizontal
			mut mw := 0 // find submenu max width
			if m.orientation == .vertical {
				for item in m.items {
					if item.width > mw {
						mw = item.width
					}
				}
			} else {
				mw = m.width
			}

			d.draw_rect_filled(m.x, m.y, mw + m.items.len * m.dx, m.height, m.root_menu.style.bg_color)
			d.draw_rect_empty(m.x, m.y, mw + m.items.len * m.dx, m.height, m.root_menu.style.border_color)

			mut w := 0
			for i, item in m.items {
				//	println("item $i <$m.id> $m.x, $m.y, $w, $item.width, $m.dx")
				if m.hovered >= 0 && i == m.hovered {
					d.draw_rect_filled(m.x + i * m.dx + w + 1, m.y + i * m.dy * m.item_height,
						item.width, m.item_height - 1, m.root_menu.style.bg_color_hover)

					// println("item $i <$m.id> $m.x, $m.y, $w, $item.width, $m.dx")
				}

				dtw.draw_device_text(d, m.x + i * m.dx + w + menu_padding, m.y +
					i * m.dy * m.item_height + menu_padding, item.text)

				w = w + item.width
			}
		}
	}

	offset_end(mut m)
}

pub fn (mut m Menu) add_item(p MenuItemParams) {
	m.items << menuitem(p)
	m.update_size()
}

pub fn (mut m Menu) get_items_count() int {
	return m.items.len
}

pub fn (mut m Menu) set_visible(state bool) {
	m.hidden = !state
}

pub fn (mut m Menu) set_children_visible(state bool) {
	m.set_visible(state)
	if m.selected >= 0 {
		mut item := m.items[m.selected]
		if item.has_menu() {
			item.submenu.set_children_visible(state)
		}
	}
}

pub fn (mut m Menu) set_all_children_visible(state bool) {
	for mut item in m.items {
		m.set_visible(state)
		if item.has_menu() {
			item.submenu.set_all_children_visible(state)
		}
	}
}

pub fn (mut m Menu) close() {
	// if m.parent_menu != 0 && m.id != m.parent_menu.id {
	// 	m.set_visible(false)
	// }
	if m.is_top_layer_menu() {
		m.set_visible(false)
	}
	for mut item in m.items {
		if item.has_menu() {
			item.submenu.close()
		}
	}
}

fn (m &Menu) point_inside(x f64, y f64) bool {
	return point_inside(m, x, y)
}

pub fn (mut m Menu) set_text(s string) {
	m.text = s
}

pub fn (m &Menu) show_all_states() {
	println('Show states: ${m.id}')
	for i, item in m.items {
		print('${i}) ${item.id} ${item.text}')
		if item.has_menu() {
			println(' with submenu ${item.submenu.id} hidden ${item.submenu.hidden}')
			item.submenu.show_all_states()
		} else {
			println('')
		}
	}
	println('')
}

pub type MenuItemFn = fn (item &MenuItem)

@[heap]
pub struct MenuItem {
pub mut:
	id          string
	text        string
	pos         int
	submenu     &Menu     = unsafe { nil }
	menu        &Menu     = unsafe { nil }
	parent_item &MenuItem = unsafe { nil }
	width       int
mut:
	action MenuItemFn = unsafe { nil }
}

@[params]
pub struct MenuItemParams {
pub:
	id      string
	text    string
	submenu &Menu      = unsafe { nil }
	action  MenuItemFn = unsafe { MenuItemFn(0) }
}

pub fn menuitem(p MenuItemParams) &MenuItem {
	mi := &MenuItem{
		text:    p.text
		id:      p.id
		action:  p.action
		submenu: p.submenu
		width:   0
	}
	return mi
}

fn (mut mi MenuItem) build(mut win Window) {
	mi.id = mi.menu.id + '/' + mi.id
	if unsafe { mi.submenu != 0 } {
		mi.submenu.id = '${mi.id}'
		mi.submenu.build(mut win)
		win.add_top_layer(mi.submenu)
		mi.submenu.set_visible(false)

		// println("$mi.submenu.id $mi.submenu.parent_menu.id")
		// println('add_top_layer $mi.submenu.id')
		// println('<$mi.submenu.id> $mi.submenu.x, $mi.submenu.y')
		// println('${mi.menu.ui.window.top_layer.children.map(it.id)}')
	}
}

fn (mut mi MenuItem) set_menu_root_menu() {
	if mi.has_menu() {
		$if mi_smpm ? {
			if mi.menu.root_menu == 0 {
				println("item ${mi.id} submenu can't inherit root menu")
			} else {
				println('item ${mi.id} submenu inherit root menu from parent ${mi.menu.parent_menu.id}')
			}
		}
		mi.submenu.root_menu = mi.menu.root_menu
	}
}

pub fn (mi &MenuItem) has_menu() bool {
	return unsafe { mi.submenu != 0 }
}

pub fn (mut mi MenuItem) set_menu(state bool) {
	if state {
		mi.set_menu_pos()
		mi.submenu.set_visible(true)
	} else {
		mi.submenu.set_all_children_visible(false)
	}
}

pub fn (mut mi MenuItem) set_menu_visible(state bool) {
	if state {
		mi.set_menu_pos()
		mi.submenu.set_visible(true)
	} else {
		mi.submenu.set_children_visible(false)
	}
}

pub fn (mut mi MenuItem) set_menu_pos() {
	if mi.submenu == unsafe { nil } {
		return
	}
	if mi.menu.root_menu.fixed_width {
		if mi.menu.orientation == .horizontal {
			mi.submenu.set_pos(mi.menu.x + mi.pos * mi.menu.item_width, mi.menu.y +
				mi.menu.item_height)
		} else {
			mi.submenu.set_pos(mi.menu.x + mi.menu.item_width, mi.menu.y +
				mi.pos * mi.menu.item_height)
		}
	} else {
		if mi.menu.orientation == .horizontal {
			mut dx := 0
			for i, item in mi.menu.items {
				if i < mi.pos {
					dx = dx + item.width
				}
			}
			mi.submenu.set_pos(mi.menu.x + dx + mi.pos * mi.menu.dx, mi.menu.y + mi.menu.item_height)
		} else {
			mut dx := 0
			for item in mi.menu.items {
				if item.width > dx {
					dx = item.width
				}
			}
			mi.submenu.set_pos(mi.menu.x + dx, mi.menu.y + mi.pos * mi.menu.item_height)
		}
	}
}
