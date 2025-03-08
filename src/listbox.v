module ui

import gx
import gg

type ListBoxFn = fn (&ListBox)

const listbox_item_height = 20
const listbox_bg_color = gx.white
const listbox_color_pressed = gx.light_blue
const listbox_color_disabled = gx.light_gray
const listbox_border_color = gx.gray
const listbox_text_offset_y = 3
const listbox_text_offset_x = 5

@[heap]
pub struct ListBox {
pub mut:
	height        int
	width         int
	x             int
	y             int
	offset_x      int
	offset_y      int
	z_index       int
	parent        Layout      = empty_stack
	ui            &UI         = unsafe { nil }
	items         []&ListItem = []&ListItem{}
	selection     int         = -1
	selectable    bool
	multi         bool
	hovering      int = -1
	draw_count    int
	on_change     ListBoxFn = unsafe { ListBoxFn(0) }
	is_focused    bool
	item_height   int = listbox_item_height
	text_offset_y int = listbox_text_offset_y
	id            string
	// TODO
	draw_lines     bool
	color_disabled gx.Color = listbox_color_disabled
	// Style
	theme_style  string
	style        ListBoxShapeStyle
	style_params ListBoxStyleParams
	// text styles
	text_styles TextStyles
	text_size   f64
	hidden      bool
	clipping    bool
	// files dropped
	files_dropped bool
	// ordered
	ordered      bool
	just_dragged bool
	// drag drop types for compatibility
	drag_type  string   = 'lb'
	drop_types []string = ['lb']
	// guess adjusted width
	adj_width  int
	adj_height int
	// component state for composable widget
	component voidptr
	// scrollview
	has_scrollview   bool
	scrollview       &ScrollView         = unsafe { nil }
	on_scroll_change ScrollViewChangedFn = unsafe { ScrollViewChangedFn(0) }
}

@[params]
pub struct ListBoxParams {
	ListBoxStyleParams
pub mut:
	x             int
	y             int
	width         int
	height        int
	z_index       int
	on_change     ListBoxFn = unsafe { ListBoxFn(0) }
	item_height   int       = listbox_item_height
	text_offset_y int       = listbox_text_offset_y
	id            string // To use one callback for multiple ListBoxes
	// TODO
	draw_lines bool // Draw a rectangle around every item?
	theme      string = no_style
	// related to text drawing
	text_size  f64
	selection  int  = -1
	selectable bool = true
	multi      bool
	scrollview bool = true
	items      map[string]string
	// files droped
	files_dropped bool
	// ordered
	ordered bool
}

// Keys of the items map are IDs of the elements, values are text
pub fn listbox(c ListBoxParams) &ListBox {
	mut list := &ListBox{
		x:          c.x // if c.draw_lines { c.x } else { c.x - 1 }
		y:          c.y // if c.draw_lines { c.y } else { c.y - 1 }
		width:      c.width
		height:     c.height
		z_index:    c.z_index
		selection:  c.selection
		selectable: c.selectable
		multi:      c.multi
		on_change:  c.on_change
		draw_lines: c.draw_lines
		// bg_color: c.bg_color
		// color_pressed: c.color_pressed
		// border_color: c.border_color
		item_height:   c.item_height
		text_offset_y: c.text_offset_y
		text_size:     c.text_size
		style_params:  c.ListBoxStyleParams
		files_dropped: c.files_dropped
		ordered:       c.ordered
		id:            c.id
		ui:            unsafe { nil }
	}
	list.style_params.style = c.theme
	for id, text in c.items {
		// println(" append $id -> $text ")
		list.append_item(id, text, 0)
	}
	if c.scrollview {
		scrollview_add(mut list)
	}
	return list
}

fn (mut lb ListBox) init(parent Layout) {
	lb.parent = parent
	u := parent.get_ui()
	lb.ui = u
	lb.init_style()
	mut dtw := DrawTextWidget(lb)
	dtw.load_style()
	lb.draw_count = lb.height / lb.item_height
	lb.text_offset_y = (lb.item_height - dtw.text_height('W')) / 2
	if lb.text_offset_y < 0 {
		lb.text_offset_y = 0
	}

	// update lb.width and lb.height to adjusted sizes when initialized to 0
	lb.init_size()

	lb.init_items()

	if has_scrollview(lb) {
		lb.scrollview.init(parent)
		scrollview_update(lb)
	}

	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, on_change, lb)
	subscriber.subscribe_method(events.on_mouse_down, lb_mouse_down, lb)
	subscriber.subscribe_method(events.on_mouse_move, lb_mouse_move, lb)
	subscriber.subscribe_method(events.on_mouse_up, lb_mouse_up, lb)
	subscriber.subscribe_method(events.on_key_up, lb_key_up, lb)
	lb.ui.window.evt_mngr.add_receiver(lb, [events.on_mouse_down, events.on_scroll])
	// println("lb $lb.files_dropped")
	if lb.files_dropped {
		subscriber.subscribe_method(events.on_files_dropped, on_files_dropped, lb)
		// lb.ui.window.evt_mngr.add_receiver(lb, [events.on_files_dropped])
	}
}

@[manualfree]
fn (mut lb ListBox) cleanup() {
	mut subscriber := lb.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, lb)
	subscriber.unsubscribe_method(events.on_mouse_down, lb)
	subscriber.unsubscribe_method(events.on_mouse_move, lb)
	subscriber.unsubscribe_method(events.on_mouse_up, lb)
	subscriber.unsubscribe_method(events.on_key_up, lb)
	lb.ui.window.evt_mngr.rm_receiver(lb, [events.on_mouse_down, events.on_scroll])
	if lb.files_dropped {
		subscriber.unsubscribe_method(events.on_files_dropped, lb)
		// lb.ui.window.evt_mngr.rm_receiver(lb, [events.on_files_dropped])
	}

	unsafe { lb.free() }
}

@[unsafe]
pub fn (lb &ListBox) free() {
	$if free ? {
		print('listbox ${lb.id}')
	}
	unsafe {
		lb.id.free()
		for item in lb.items {
			item.free()
		}
		lb.items.free()
		free(lb)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (mut lb ListBox) init_style() {
	// $if nodtw ? {
	// 	if is_empty_text_cfg(lb.text_cfg) {
	// 		lb.text_cfg = lb.ui.window.text_cfg
	// 	}
	// 	if lb.text_size > 0 {
	// 		_, win_height := lb.ui.window.size()
	// 		lb.text_cfg = gx.TextCfg{
	// 			...lb.text_cfg
	// 			size: text_size_as_int(lb.text_size, win_height)
	// 		}
	// 	}
	// } $else {
	mut dtw := DrawTextWidget(lb)
	dtw.init_style()
	dtw.update_text_size(lb.text_size)
	// }
}

fn (mut lb ListBox) init_items() {
	for i, mut item in lb.items {
		// println("$i $item.text get ot draw-> ${lb.get_draw_to(item.text)}")
		item.draw_to = lb.get_draw_to(item.text)
		item.x = 0
		item.y = lb.item_height * i
		// println("item init $i, $item.text, $item.x $item.y")
	}
}

pub fn (mut lb ListBox) reset() {
	lb.items.clear()
}

pub fn (mut lb ListBox) update_items(items []string) {
	// unsafe { lb.items.free() }
	lb.items.clear()
	for item in items {
		lb.add_item(item, item)
	}
}

pub fn (mut lb ListBox) add_item(id string, text string) {
	lb.append_item(id, text, lb.get_draw_to(text))
	lb.update_adj_size()
}

pub fn (mut lb ListBox) append_item(id string, text string, draw_to int) {
	lb.items << listitem(
		x:       0
		y:       lb.item_height * lb.items.len
		id:      id
		text:    text
		list:    lb
		draw_to: draw_to
	)
}

pub fn (mut lb ListBox) delete_item(id string) {
	for i in 0 .. lb.items.len {
		if lb.items[i].id == id {
			lb.delete_at(i)
			lb.update_adj_size()
			break
		}
	}
}

pub fn (mut lb ListBox) delete_at(i int) {
	if i < 0 || i >= lb.items.len {
		return
	}
	for j in (i + 1) .. lb.items.len {
		lb.items[j].y -= lb.item_height
	}
	lb.items.delete(i)
}

pub fn (mut lb ListBox) insert_at(i int, item &ListItem) {
	if i < 0 || i > lb.items.len {
		return
	}
	// println('item $item.id inserted at $i in $lb.id')
	lb.items.insert(i, item)
	lb.update_adj_size()
	lb.init_items()
	// println("${lb.items.map(it.id)} ${lb.items.map(it.y)}")
}

pub fn (mut lb ListBox) move_by(i int, delta int) {
	if i < 0 || i >= lb.items.len || delta == 0 || i + delta < 0 || i + delta >= lb.items.len {
		return
	}
	mut cur := -1
	if delta < 0 {
		if delta == -1 {
			cur = i - 1
		} else {
			for d in 0 .. (-delta) {
				lb.move_by(i - d, -1)
			}
		}
	} else {
		if delta == 1 {
			cur = i
		} else {
			for d in 0 .. delta {
				lb.move_by(i + d, 1)
			}
		}
	}
	if cur >= 0 {
		if !lb.multi {
			if lb.selection == i {
				lb.selection = i + delta
			} else if lb.selection == i + delta {
				lb.selection = i
			}
		}
		lb.items[cur], lb.items[cur + 1] = lb.items[cur + 1], lb.items[cur]
		lb.items[i].y += lb.item_height * (-delta)
	}
}

pub fn (lb &ListBox) is_selected() bool {
	if lb.selection < 0 || lb.selection >= lb.items.len {
		return false
	}
	return true
}

pub fn (lb &ListBox) is_item_selected_at(inx int) bool {
	return lb.selectable && if lb.multi {
		lb.items[inx].selected && !lb.items[inx].disabled
	} else {
		inx == lb.selection
	}
}

pub fn (lb &ListBox) is_item_selected(li &ListItem) bool {
	return lb.selectable && if lb.multi {
		li.selected && !li.disabled
	} else {
		if lb.selection < 0 || lb.selection >= lb.items.len {
			false
		} else {
			li == lb.items[lb.selection]
		}
	}
}

pub fn (mut lb ListBox) set_item_selected(inx int, enable_mode bool) bool {
	if lb.multi {
		if enable_mode {
			lb.items[inx].disabled = !lb.items[inx].disabled
			return true
		} else {
			if !lb.items[inx].disabled {
				lb.items[inx].selected = !lb.items[inx].selected
				return true
			}
			return false
		}
	} else {
		if inx != lb.selection {
			lb.selection = inx
			return true
		} else {
			return false
		}
	}
}

pub fn (lb &ListBox) is_item_enabled_at(inx int) bool {
	return lb.items[inx].is_enabled()
}

pub fn (lb &ListBox) ids() []string {
	mut res := []string{}
	for _, item in lb.items {
		res << item.id
	}
	return res
}

pub fn (lb &ListBox) values() []string {
	mut res := []string{}
	for _, item in lb.items {
		res << item.text
	}
	return res
}

pub fn (lb &ListBox) indices() []int {
	mut res := []int{}
	for inx, _ in lb.items {
		res << inx
	}
	return res
}

// Returns the id and the text of the selected item
pub fn (lb &ListBox) selected() !(string, string) {
	if !lb.is_selected() {
		return error('Nothing is selected')
	}
	return lb.items[lb.selection].id, lb.items[lb.selection].text
}

// Returns id and text of the selected item. Empty id means that there is no selection.
pub fn (lb &ListBox) selected_item() (string, string) {
	if lb.is_selected() {
		return lb.items[lb.selection].id, lb.items[lb.selection].text
	} else {
		return '', ''
	}
}

pub fn (lb &ListBox) items() []&ListItem {
	if lb.multi {
		return lb.items
	} else {
		return if lb.is_selected() { [lb.items[lb.selection]] } else { []&ListItem{} }
	}
}

// Returns the index of the selected item
pub fn (lb &ListBox) selected_at() !int {
	if !lb.is_selected() {
		return error('Nothing is selected')
	}
	return lb.selection
}

// Returns the index of the selected item and -1 if no selection.
pub fn (lb &ListBox) selected_item_at() int {
	if lb.is_selected() {
		return lb.selection
	} else {
		return -1
	}
}

pub fn (mut lb ListBox) set_text(id string, text string) {
	for i in 0 .. lb.items.len {
		if lb.items[i].id == id {
			lb.items[i].text = text
			lb.items[i].draw_to = lb.get_draw_to(text)
			break
		}
	}
}

@[manualfree]
pub fn (mut lb ListBox) clear() {
	for item in lb.items {
		unsafe { item.free() }
	}
	lb.items.clear()
	lb.selection = -1
}

fn (lb &ListBox) get_selected_item(y int) int {
	inx := lb.current_pos(y)
	return if inx < 0 || inx >= lb.items.len { -1 } else { inx }
}

fn (lb &ListBox) current_pos(y int) int {
	$if lb_selitem ? {
		println('lb sel item ${(y - lb.y) / lb.item_height} := (${y} - ${lb.y}) / ${lb.item_height}')
	}
	return (y - lb.y) / lb.item_height
}

fn (lb &ListBox) visible_items() (int, int) {
	mut j1, mut j2 := 0, 0
	if lb.has_scrollview {
		j1 = lb.scrollview.offset_y / lb.item_height
		if j1 < 0 {
			j1 = 0
		}
	}

	if lb.has_scrollview {
		j2 = (lb.scrollview.offset_y + lb.height) / lb.item_height
	} else {
		j2 = lb.height / lb.item_height
	}
	jmax := lb.items.len - 1
	if j2 > jmax {
		j2 = jmax
	}
	return j1, j2
}

fn (mut lb ListBox) draw() {
	lb.draw_device(mut lb.ui.dd)
}

fn (mut lb ListBox) draw_device(mut d DrawDevice) {
	offset_start(mut lb)
	defer {
		offset_end(mut lb)
	}
	$if layout ? {
		if lb.ui.layout_print {
			println('ListBox(${lb.id}): (${lb.x}, ${lb.y}, ${lb.width}, ${lb.height})')
		}
	}
	scrollview_draw_begin(mut lb, d)
	defer {
		scrollview_draw_end(lb, d)
	}
	cstate := clipping_start(lb, mut d) or { return }
	defer {
		clipping_end(lb, mut d, cstate)
	}

	mut dtw := DrawTextWidget(lb)
	dtw.draw_device_load_style(d)
	height := if lb.has_scrollview && lb.adj_height > lb.height {
		lb.adj_height + lb.text_offset_y
	} else {
		lb.height
	}
	$if lb_draw ? {
		println('draw ${lb.id} scrollview=${lb.has_scrollview} ${lb.x}, ${lb.y}, ${lb.width} ${lb.height} ${height}')
	}
	d.draw_rect_filled(lb.x, lb.y, lb.width, height, lb.style.bg_color)
	// println("draw rect")
	from, to := lb.visible_items()
	if lb.items.len == 0 {
		dtw = DrawTextWidget(lb)
		dtw.draw_device_styled_text(d, lb.x + listbox_text_offset_x, lb.y + lb.text_offset_y,
			if lb.files_dropped {
			'Empty listbox. Drop files here ...'
		} else {
			''
		}, color: gx.gray)
	} else {
		for inx, item in lb.items {
			// println("$inx >= $lb.draw_count")
			if inx >= lb.draw_count && !has_scrollview(lb) {
				break
			}
			if !has_scrollview(lb) || (inx >= from && inx <= to) {
				if !lb.has_dragger_active_at(inx) {
					item.draw_device(d)
				}
			}
		}
	}
	if !lb.draw_lines {
		d.draw_rect_empty(lb.x - 1, lb.y - 1, lb.width + 2, height + 2, lb.style.border_color)
	}
}

fn (mut lb ListBox) get_draw_to(text string) int {
	if lb.has_scrollview {
		return 0
	}
	mut dtw := DrawTextWidget(lb)
	dtw.load_style()
	width := dtw.text_width(text)
	real_w := lb.width + listbox_text_offset_x * 2
	mut draw_to := text.len
	if width >= real_w {
		draw_to = int(f32(text.len) * (f32(real_w) / f32(width)))
		for draw_to > 1 && dtw.text_width(text[0..draw_to]) > real_w {
			draw_to--
		}
	}
	// println('width $width >= real_w $real_w draw_to: $draw_to, $text, ${text[0..draw_to]}')
	return draw_to
}

fn (lb &ListBox) point_inside(x f64, y f64) bool {
	// println("inside lb $x $y (${lb.x + lb.offset_x}, ${lb.y + lb.offset_y}, $lb.width, $lb.height)")
	if lb.has_scrollview {
		return lb.scrollview.point_inside(x, y, .view)
	} else {
		return point_inside(lb, x, y)
	}
}

fn on_change(mut lb ListBox, e &MouseEvent, window &Window) {
	// println("onclick $e.action ${int(e.action)}")
	if lb.hidden {
		return
	}
	if !lb.ui.window.is_top_widget(lb, events.on_mouse_down) {
		return
	}
	if e.action != .up {
		return
	}
	// unclickable if dragged
	if lb.just_dragged {
		lb.just_dragged = false
		return
	}
	if !lb.point_inside(e.x, e.y) {
		lb.unfocus()
		return
	}
	lb.focus()
	$if dd_change_old ? {
		for inx, item in lb.items {
			if !lb.has_scrollview && inx >= lb.draw_count {
				break
			}
			// println(' $item.id -> ($e.x,$e.y)')
			if item.point_inside(e.x, e.y) {
				if lb.set_item_selected(inx, ctrl_key(lb.ui.keymods)) {
					lb.call_on_change()
				}
				break
			}
		}
	} $else {
		inx := lb.get_selected_item(e.y)
		if inx >= 0 && lb.set_item_selected(inx, ctrl_key(lb.ui.keymods)) {
			lb.call_on_change()
		}
	}
}

pub fn (lb &ListBox) call_on_change() {
	if lb.on_change != unsafe { ListBoxFn(0) } {
		lb.on_change(lb)
	}
}

fn lb_mouse_down(mut lb ListBox, e &MouseEvent, window &Window) {
	$if lb_md ? {
		println('lb_mouse_down ${lb.id} top_widget ${lb.ui.window.is_top_widget(lb, events.on_mouse_down)}')
	}
	if lb.hidden {
		return
	}
	if !lb.ui.window.is_top_widget(lb, events.on_mouse_down) {
		return
	}
	if lb.point_inside(e.x, e.y) {
		lb.focus() // IMPORTANT to not propagate event at the same position of removed widget
		if lb.ordered {
			dragged_item := lb.get_selected_item(e.y)
			if dragged_item >= 0 {
				mut di := lb.items[dragged_item]
				lb.just_dragged = drag_register(di, e)
				if lb.just_dragged {
					lb.ui.window.dragger.extra_int = dragged_item
				}
			}
		}
		// lb.state = .pressed
	}
}

fn lb_mouse_up(mut lb ListBox, e &MouseEvent, window &Window) {
	// println('lb_mu')
	if lb.hidden {
		return
	}
	if lb.has_dragger_active() {
		dragged_item := lb.ui.window.dragger.extra_int
		$if lb_up ? {
			println('lb ${lb.id} mouse up ${dragged_item} (${lb.items.len})')
		}
		lb.items[dragged_item].x, lb.items[dragged_item].y = 0, dragged_item * lb.item_height
		lb.items[dragged_item].offset_x, lb.items[dragged_item].offset_y = 0, 0
		lb.call_on_change()
	}
	// b.state = .normal
}

fn lb_mouse_move(mut lb ListBox, e &MouseMoveEvent, window &Window) {
	// println('lb move $lb.id')
	if lb.hidden {
		return
	}
	if lb.point_inside(e.x, e.y) {
		if dragger_intersect_dropzone(mut lb) {
			// $if lb_move ? {
			// 	println("lb mouse move OUTSIDE $lb.id")
			// }
			mut dragger := lb.ui.window.dragger
			mut dragged := dragger.widget
			if mut dragged is ListItem {
				if dragged.list.id != lb.id {
					$if lb_move ? {
						println('lb mouse move reparent ${lb.id} from ${dragged.list.id}')
					}
					// remove previous lb N.B.: dragged.remove()
					dragged.list.delete_at(lb.ui.window.dragger.extra_int)
					// reparent dragged item
					j := lb.current_pos(int(e.y))
					dragged.update_parent(mut lb, j)
					// change origin for dragger
					lb.ui.window.dragger.start_x = int(e.x) - dragged.offset_x
					lb.ui.window.dragger.start_y = int(e.y) - dragged.offset_y
				} else {
					// $if lb_move ? {
					// 	println("lb mouse move swap inside $lb.id")
					// }
					j := lb.get_selected_item(int(e.y))
					dragged_item := lb.ui.window.dragger.extra_int
					if j >= 0 && (j == dragged_item - 1 || j == dragged_item + 1) {
						lb.move_by(dragged_item, j - dragged_item)
						lb.ui.window.dragger.extra_int = j
					}
				}
			}
		} else {
			lb.hovering = lb.get_selected_item(int(e.y))
		}
	} else {
		lb.hovering = -1
	}
}

fn on_files_dropped(mut lb ListBox, e &MouseEvent, window &Window) {
	// println("on_files_dropped")
	if lb.hidden {
		return
	}
	// println("on files: inside ${lb.point_inside(e.x, e.y)}")
	if !lb.point_inside(e.x, e.y) {
		return
	}
	// println("${lb.ui.window.point_inside_receivers(events.on_files_dropped)}")
	// if !lb.ui.window.is_top_widget(lb, events.on_files_dropped) {
	// 	return
	// }
	num_dropped := get_num_dropped_files()
	for i in 0 .. num_dropped {
		path := get_dropped_file_path(i)
		lb.add_item(path, path.clone())
	}
	lb.ui.window.update_layout()
}

// Up and Down keys work on the list when it's is_focused
fn lb_key_up(mut lb ListBox, e &KeyEvent, window &Window) {
	if lb.hidden {
		return
	}
	if !lb.is_focused {
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
	if lb.on_change != unsafe { ListBoxFn(0) } {
		lb.on_change(lb)
	}
}

pub fn (mut lb ListBox) set_pos(x int, y int) {
	if lb.x != x || lb.y != y {
		// println("set pos lb: $x, $y")
		scrollview_widget_save_offset(lb)
		lb.x = x
		lb.y = y
		scrollview_widget_restore_offset(lb, true)
	}
}

fn (mut lb ListBox) set_visible(state bool) {
	lb.hidden = !state
}

fn (mut lb ListBox) focus() {
	mut f := Focusable(lb)
	f.set_focus()
}

fn (mut lb ListBox) unfocus() {
	lb.is_focused = false
}

// Needed for ScrollableWidget
fn (mut lb ListBox) adj_size() (int, int) {
	if lb.adj_width == 0 {
		mut width := 0
		mut dtw := DrawTextWidget(lb)
		dtw.load_style()
		for item in lb.items {
			width = dtw.text_width(item.text) + listbox_text_offset_x * 2
			// println('$item.text -> $width')
			if width > lb.adj_width {
				lb.adj_width = width
			}
		}
		// println("adj_width: $lb.adj_width")
	}
	if lb.adj_height == 0 {
		lb.adj_height = lb.items.len * lb.item_height + 2 * lb.text_offset_y
	}
	// println("lb adj: ($lb.adj_width, $lb.adj_height) size: ($lb.width, $lb.height)")
	return lb.adj_width, lb.adj_height
}

fn (mut lb ListBox) update_adj_size() {
	mut width := 0
	mut dtw := DrawTextWidget(lb)
	dtw.load_style()
	for item in lb.items {
		width = dtw.text_width(item.text) + listbox_text_offset_x * 2
		// println('$item.text -> $width')
		if width > lb.adj_width {
			lb.adj_width = width
		}
	}
	lb.adj_height = lb.items.len * lb.item_height
	scrollview_update(lb)
}

fn (mut lb ListBox) init_size() {
	if lb.width == 0 {
		lb.width, _ = lb.adj_size()
	}
	if lb.height == 0 {
		_, lb.height = lb.adj_size()
	}
}

pub fn (lb &ListBox) size() (int, int) {
	// println("lb size: $lb.width, $lb.height")
	return lb.width, lb.height
}

pub fn (mut lb ListBox) propose_size(w int, h int) (int, int) {
	// println("lb propose: ($w, $h)")
	lb.resize(w, h)
	scrollview_update(lb)
	return lb.width, lb.height
}

fn (mut lb ListBox) resize(width int, height int) {
	if width != lb.width {
		lb.init_items()
	}
	lb.width = width
	lb.height = height
	lb.draw_count = lb.height / lb.item_height
}

// Normally useless but required for scrollview_draw_begin()
fn (lb &ListBox) set_children_pos() {}

fn (lb &ListBox) has_dragger_active_at(inx int) bool {
	return lb.has_dragger_active() && lb.ui.window.dragger.extra_int == inx
}

fn (lb &ListBox) has_dragger_active() bool {
	dragged := lb.ui.window.dragger.widget
	if dragged is ListItem {
		return lb.ui.window.dragger.activated && lb.id == dragged.list.id
	}
	return false
}

fn (lb &ListBox) fit_at(at int) int {
	mut inx := at
	if inx >= lb.items.len {
		inx = lb.items.len - 1
	}
	if inx < 0 {
		inx = 0
	}
	return inx
}

@[heap]
struct ListItem {
mut:
	id       string
	list     &ListBox = unsafe { nil }
	x        int
	y        int
	offset_x int
	offset_y int
	z_index  int
	draw_to  int
pub mut:
	text     string
	disabled bool
	selected bool
}

@[params]
struct ListItemParams {
pub:
	id       string
	list     &ListBox = unsafe { nil }
	x        int
	y        int
	offset_x int
	offset_y int
	z_index  int
	text     string
	disabled bool
	selected bool
	draw_to  int
}

pub fn listitem(p ListItemParams) &ListItem {
	return &ListItem{
		x:        p.x
		y:        p.y
		id:       p.id
		text:     p.text
		list:     unsafe { p.list }
		draw_to:  p.draw_to // p.text[0..p.draw_to]
		offset_x: p.offset_x
		offset_y: p.offset_y
		z_index:  p.z_index
		disabled: p.disabled
		selected: p.selected
	}
}

@[unsafe]
fn (item &ListItem) free() {
	$if free ? {
		print('\tlistbox item ${item.id}')
	}
	unsafe {
		// Failing: item.id.free()
		item.text.free()
		// Failing: free(item)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (li &ListItem) text() string {
	return li.text[0..li.draw_to]
}

fn (li &ListItem) point_inside(x f64, y f64) bool {
	lix, liy := li.x + li.offset_x + li.list.x + li.list.offset_x, li.y + li.offset_y + li.list.y +
		li.list.offset_y
	return x >= lix && x <= lix + li.list.width && y >= liy && y <= liy + li.list.item_height
}

pub fn (li &ListItem) size() (int, int) {
	// println("lb size: $lb.width, $lb.height")
	return li.list.width, li.list.item_height
}

// method implemented in Draggable
fn (li &ListItem) get_window() &Window {
	return li.list.ui.window
}

fn (li &ListItem) drag_type() string {
	return li.list.drag_type
}

fn (li &ListItem) drag_bounds() gg.Rect {
	w, h := li.size()
	return gg.Rect{li.x + li.offset_x + li.list.x + li.list.offset_x, li.y + li.offset_y +
		li.list.y + li.list.offset_y, w, h}
}

pub fn (li &ListItem) is_selected() bool {
	return li.list.is_item_selected(li)
}

pub fn (li &ListItem) is_enabled() bool {
	return !li.disabled
}

pub fn (li &ListItem) delete() {
	mut lb := li.list
	lb.delete_item(li.id)
}

pub fn (mut li ListItem) update(id string, text string) {
	li.id = id
	li.text = text
	li.draw_to = li.list.get_draw_to(li.text)
}

pub fn (mut li ListItem) update_parent(mut lb ListBox, at int) {
	li_x := li.x + li.offset_x + li.list.x
	li_y := li.y + li.offset_y + li.list.y
	li.list = lb
	// insert
	j := lb.fit_at(at)
	$if li_upar ? {
		println('update parent ${li.id} in ${lb.id} insert_at ${j}')
	}
	lb.insert_at(j, li)
	// recompute offset
	li.offset_x = li_x - (li.x + li.list.x)
	li.offset_y = li_y - (li.y + li.list.y)
	lb.ui.window.dragger.extra_int = j
}

fn (li &ListItem) draw() {
	li.draw_device(li.list.ui.dd)
}

fn (li &ListItem) draw_device(d DrawDevice) {
	lb := li.list
	col := if li.is_selected() {
		lb.style.bg_color_pressed
	} else if lb.hovering >= 0 && li == lb.items[lb.hovering] {
		lb.style.bg_color_hover
	} else {
		lb.style.bg_color
	}
	width := if lb.has_scrollview && lb.adj_width > lb.width { lb.adj_width } else { lb.width }
	$if li_draw ? {
		println('draw item  ${lb.id} ${li.id} ${li.text()} ${li.x} + ${lb.x} + ${li.offset_x} + ${listbox_text_offset_x}, ${li.y} + ${li.offset_y} + ${lb.y} + ${lb.text_offset_y}, ${lb.width}, ${lb.item_height}')
	}
	d.draw_rect_filled(li.x + li.offset_x + lb.x + listbox_text_offset_x, li.y + li.offset_y +
		lb.y + lb.text_offset_y, width - 2 * listbox_text_offset_x, lb.item_height, col)

	mut dtw := DrawTextWidget(lb)
	dtw.draw_device_styled_text(d, li.x + li.offset_x + lb.x + listbox_text_offset_x,
		li.y + li.offset_y + lb.y + lb.text_offset_y, if lb.has_scrollview {
		li.text
	} else {
		li.text()
	},
		color: if li.is_enabled() { lb.text_styles.current.color } else { lb.color_disabled }
	)
	if lb.draw_lines {
		// println("line item $li.x + $lb.x, $li.y + $lb.x, $lb.width, $lb.item_height")
		d.draw_rect_empty(li.x + li.offset_x + lb.x + listbox_text_offset_x, li.y + li.offset_y +
			lb.y + lb.text_offset_y, width - 2 * listbox_text_offset_x, lb.item_height,
			lb.style.border_color)
	}
}
