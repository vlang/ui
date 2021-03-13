module ui

import gx
import eventbus

type SelectionChangedFn = fn (voidptr, voidptr) // The second will be ListBox

const (
	_item_height     = 20
	_col_list_bkgrnd = gx.white
	_col_item_select = gx.light_blue
	_col_border      = gx.gray
	_text_offset_y   = 3
	_text_offset_x   = 5
)

pub struct ListBoxConfig {
mut:
	x             int
	y             int
	width         int
	height        int
	z_index       int
	callback      SelectionChangedFn = SelectionChangedFn(0)
	draw_lines    bool     // Draw a rectangle around every item?
	col_border    gx.Color = ui._col_border // Item and list border color
	col_bkgrnd    gx.Color = ui._col_list_bkgrnd // ListBox background color
	col_selected  gx.Color = ui._col_item_select // Selected item background color
	item_height   int      = ui._item_height
	text_offset_y int      = ui._text_offset_y
	id            string // To use one callback for multiple ListBoxes
}

// Keys of the items map are IDs of the elements, values are text
pub fn listbox(c ListBoxConfig, items map[string]string) &ListBox {
	mut list := &ListBox{
		x: if c.draw_lines { c.x } else { c.x - 1 }
		y: if c.draw_lines { c.y } else { c.y - 1 }
		width: c.width
		height: c.height
		z_index: c.z_index
		selection: -1
		clbk: c.callback
		draw_lines: c.draw_lines
		col_bkgrnd: c.col_bkgrnd
		col_selected: c.col_selected
		col_border: c.col_border
		item_height: c.item_height
		text_offset_y: c.text_offset_y
		id: c.id
		ui: 0
	}
	for id, text in items {
		list.append_item(id, text, 0)
	}
	return list
}

pub fn (mut list ListBox) add_item(id string, text string) {
	list.append_item(id, text, list.get_draw_to(text))
}

pub struct ListBox {
pub mut:
	height        int
	width         int
	x             int
	y             int
	z_index       int
	parent        Layout
	ui            &UI
	items         []ListItem
	selection     int = -1
	draw_count    int
	clbk          SelectionChangedFn = SelectionChangedFn(0)
	focused       bool
	draw_lines    bool
	col_bkgrnd    gx.Color = ui._col_list_bkgrnd
	col_selected  gx.Color = ui._col_item_select
	col_border    gx.Color = ui._col_border
	item_height   int      = ui._item_height
	text_offset_y int      = ui._text_offset_y
	id            string
	hidden        bool
}

struct ListItem {
	x    int
	id   string
	list &ListBox
mut:
	y         int
	text      string
	draw_text string
}

fn (mut lb ListBox) get_draw_to(text string) int {
	width := lb.ui.gg.text_width(text)
	real_w := lb.width - ui._text_offset_x * 2
	mut draw_to := text.len
	if width >= real_w {
		draw_to = int(f32(text.len) * (f32(real_w) / f32(width)))
		for draw_to > 1 && lb.ui.gg.text_width(text[0..draw_to]) > real_w {
			draw_to--
		}
	}
	return draw_to
}

fn (mut lb ListBox) append_item(id string, text string, draw_to int) {
	lb.items << ListItem{
		x: lb.x
		y: lb.y + lb.item_height * lb.items.len
		id: id
		text: text
		list: lb
		draw_text: text[0..draw_to]
	}
}

pub fn (lb &ListBox) is_selected() bool {
	if lb.selection < 0 || lb.selection >= lb.items.len {
		return false
	}
	return true
}

// Returns the ID and the text of the selected item
pub fn (lb &ListBox) selected() ?(string, string) {
	if !lb.is_selected() {
		return error('Nothing is selected')
	}
	return lb.items[lb.selection].id, lb.items[lb.selection].text
}

// Returns the index of the selected item
pub fn (lb &ListBox) selected_inx() ?int {
	if !lb.is_selected() {
		return error('Nothing is selected')
	}
	return lb.selection
}

pub fn (mut lb ListBox) set_text(id string, text string) {
	for i in 0 .. lb.items.len {
		if lb.items[i].id == id {
			lb.items[i].text = text
			lb.items[i].draw_text = text[0..lb.get_draw_to(text)]
			break
		}
	}
}

pub fn (mut lb ListBox) remove_item(id string) {
	for i in 0 .. lb.items.len {
		if lb.items[i].id == id {
			lb.remove_inx(i)
			break
		}
	}
}

pub fn (mut lb ListBox) remove_inx(i int) {
	if i < 0 || i >= lb.items.len {
		return
	}
	for j in (i + 1) .. lb.items.len {
		lb.items[j].y -= lb.item_height
	}
	lb.items.delete(i)
}

pub fn (mut lb ListBox) clear() {
	lb.items.clear()
	lb.selection = -1
}

fn (mut lb ListBox) draw_item(li ListItem, selected bool) {
	col := if selected { lb.col_selected } else { lb.col_bkgrnd }
	lb.ui.gg.draw_rect(li.x, li.y, lb.width, lb.item_height, col)
	lb.ui.gg.draw_text_def(li.x + ui._text_offset_x, li.y + lb.text_offset_y, li.draw_text)
	if lb.draw_lines {
		lb.ui.gg.draw_empty_rect(li.x, li.y, lb.width, lb.item_height, lb.col_border)
	}
}

fn (mut lb ListBox) init(parent Layout) {
	lb.parent = parent
	lb.ui = parent.get_ui()
	lb.draw_count = lb.height / lb.item_height
	lb.text_offset_y = (lb.item_height - lb.ui.gg.text_height('W')) / 2
	if lb.text_offset_y < 0 {
		lb.text_offset_y = 0
	}
	for i, item in lb.items {
		lb.items[i].draw_text = item.text[0..lb.get_draw_to(item.text)]
	}
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, on_click, lb)
	subscriber.subscribe_method(events.on_key_up, on_key_up, lb)
}

fn (mut lb ListBox) draw() {
	lb.ui.gg.draw_rect(lb.x, lb.y, lb.width, lb.height, lb.col_bkgrnd)
	if !lb.draw_lines {
		lb.ui.gg.draw_empty_rect(lb.x, lb.y, lb.width + 1, lb.height + 1, lb.col_border)
	}
	for inx, item in lb.items {
		if inx >= lb.draw_count {
			break
		}
		lb.draw_item(item, inx == lb.selection)
	}
}

fn (lb &ListBox) point_inside(x f64, y f64) bool {
	return x >= lb.x && x <= lb.x + lb.width && y >= lb.y && y <= lb.y + lb.height
}

fn (li &ListItem) point_inside(x f64, y f64) bool {
	return x >= li.x && x <= li.x + li.list.width && y >= li.y && y <= li.y + li.list.item_height
}

fn on_click(mut lb ListBox, e &MouseEvent, window &Window) {
	if int(e.action) != 1 {
		return
	}
	if !lb.point_inside(e.x, e.y) {
		lb.unfocus()
		return
	}
	lb.focus()
	for inx, item in lb.items {
		if inx >= lb.draw_count {
			break
		}
		if item.point_inside(e.x, e.y) {
			if lb.selection != inx {
				lb.selection = inx
				if lb.clbk != voidptr(0) {
					lb.clbk(window.state, lb)
				}
			}
			break
		}
	}
}

// Up and Down keys work on the list when it's focused
fn on_key_up(mut lb ListBox, e &KeyEvent, window &Window) {
	if !lb.focused {
		return
	}
	match e.key {
		.down {
			if lb.selection >= lb.draw_count - 1 {
				return
			}
			if lb.selection >= lb.items.len - 1 {
				return
			}
			lb.selection++
		}
		.up {
			if lb.selection <= 0 {
				return
			}
			lb.selection--
		}
		else {
			return
		}
	}
	if lb.clbk != voidptr(0) {
		lb.clbk(window.state, lb)
	}
}

fn (mut lb ListBox) set_pos(x int, y int) {
	lb.x = x
	lb.y = y
}

fn (mut lb ListBox) set_visible(state bool) {
	lb.hidden = state
}

fn (mut lb ListBox) focus() {
	lb.focused = true
}

fn (mut lb ListBox) unfocus() {
	lb.focused = false
}

fn (lb &ListBox) is_focused() bool {
	return lb.focused
}

fn (lb &ListBox) get_ui() &UI {
	return lb.ui
}

fn (mut lb ListBox) unfocus_all() {
	lb.focused = false
}

fn (mut lb ListBox) resize(width int, height int) {
	lb.width = width
	lb.height = height
	lb.draw_count = lb.height / lb.item_height
}

fn (lb &ListBox) get_state() voidptr {
	parent := lb.parent
	return parent.get_state()
}

fn (lb &ListBox) get_subscriber() &eventbus.Subscriber {
	parent := lb.parent
	return parent.get_subscriber()
}

fn (lb &ListBox) size() (int, int) {
	return lb.width, lb.height
}

fn (mut lb ListBox) propose_size(w int, h int) (int, int) {
	lb.resize(w, h)
	return lb.width, lb.height
}
