module ui

import gx
import gg

type ListBoxSelectionChangedFn = fn (voidptr, &ListBox) // The second arg is ListBox

const (
	_item_height      = 20
	_col_list_bkgrnd  = gx.white
	_col_item_select  = gx.light_blue
	_col_item_disable = gx.light_gray
	_col_border       = gx.gray
	_text_offset_y    = 3
	_text_offset_x    = 5
)

[heap]
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
	ui            &UI         = 0
	items         []&ListItem = []&ListItem{}
	selection     int = -1
	selectable    bool
	multi         bool
	draw_count    int
	on_change     ListBoxSelectionChangedFn = ListBoxSelectionChangedFn(0)
	is_focused    bool
	draw_lines    bool
	col_bkgrnd    gx.Color = ui._col_list_bkgrnd
	col_selected  gx.Color = ui._col_item_select
	col_disabled  gx.Color = ui._col_item_disable
	col_border    gx.Color = ui._col_border
	item_height   int      = ui._item_height
	text_offset_y int      = ui._text_offset_y
	id            string
	// text styles
	text_styles TextStyles
	text_size   f64
	text_cfg    gx.TextCfg
	hidden      bool
	// files droped
	files_droped bool
	// ordered
	ordered      bool
	dragged_item int = -1
	just_dragged bool
	// drag drop types
	drag_type  string = 'lb'
	drop_types []string
	// guess adjusted width
	adj_width  int
	adj_height int
	// component state for composable widget
	component voidptr
	// scrollview
	has_scrollview   bool
	scrollview       &ScrollView = 0
	on_scroll_change ScrollViewChangedFn = ScrollViewChangedFn(0)
}

[params]
pub struct ListBoxParams {
mut:
	x             int
	y             int
	width         int
	height        int
	z_index       int
	on_change     ListBoxSelectionChangedFn = ListBoxSelectionChangedFn(0)
	draw_lines    bool     // Draw a rectangle around every item?
	col_border    gx.Color = ui._col_border // Item and list border color
	col_bkgrnd    gx.Color = ui._col_list_bkgrnd // ListBox background color
	col_selected  gx.Color = ui._col_item_select // Selected item background color
	item_height   int      = ui._item_height
	text_offset_y int      = ui._text_offset_y
	id            string // To use one callback for multiple ListBoxes
	// related to text drawing
	text_cfg   gx.TextCfg
	text_size  f64
	selection  int  = -1
	selectable bool = true
	multi      bool
	scrollview bool = true
	items      map[string]string
	// files droped
	files_droped bool
	// ordered
	ordered bool
}

// Keys of the items map are IDs of the elements, values are text
pub fn listbox(c ListBoxParams) &ListBox {
	mut list := &ListBox{
		x: c.x // if c.draw_lines { c.x } else { c.x - 1 }
		y: c.y // if c.draw_lines { c.y } else { c.y - 1 }
		width: c.width
		height: c.height
		z_index: c.z_index
		selection: c.selection
		selectable: c.selectable
		multi: c.multi
		on_change: c.on_change
		draw_lines: c.draw_lines
		col_bkgrnd: c.col_bkgrnd
		col_selected: c.col_selected
		col_border: c.col_border
		item_height: c.item_height
		text_offset_y: c.text_offset_y
		text_cfg: c.text_cfg
		text_size: c.text_size
		files_droped: c.files_droped
		ordered: c.ordered
		id: c.id
		ui: 0
	}
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
	ui := parent.get_ui()
	lb.ui = ui
	lb.init_style()
	lb.draw_count = lb.height / lb.item_height
	lb.text_offset_y = (lb.item_height - text_height(lb, 'W')) / 2
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
	// println("lb $lb.files_droped")
	if lb.files_droped {
		subscriber.subscribe_method(events.on_files_droped, on_files_droped, lb)
		// lb.ui.window.evt_mngr.add_receiver(lb, [events.on_files_droped])
	}
}

[manualfree]
fn (mut lb ListBox) cleanup() {
	mut subscriber := lb.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, lb)
	subscriber.unsubscribe_method(events.on_mouse_down, lb)
	subscriber.unsubscribe_method(events.on_mouse_move, lb)
	subscriber.unsubscribe_method(events.on_mouse_up, lb)
	subscriber.unsubscribe_method(events.on_key_up, lb)
	lb.ui.window.evt_mngr.rm_receiver(lb, [events.on_mouse_down, events.on_scroll])
	if lb.files_droped {
		subscriber.unsubscribe_method(events.on_files_droped, lb)
		// lb.ui.window.evt_mngr.rm_receiver(lb, [events.on_files_droped])
	}

	unsafe { lb.free() }
}

[unsafe]
pub fn (lb &ListBox) free() {
	$if free ? {
		print('listbox $lb.id')
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
	$if nodtw ? {
		if is_empty_text_cfg(lb.text_cfg) {
			lb.text_cfg = lb.ui.window.text_cfg
		}
		if lb.text_size > 0 {
			_, win_height := lb.ui.window.size()
			lb.text_cfg = gx.TextCfg{
				...lb.text_cfg
				size: text_size_as_int(lb.text_size, win_height)
			}
		}
	} $else {
		mut dtw := DrawTextWidget(lb)
		dtw.init_style()
		dtw.update_text_size(lb.text_size)
	}
}

fn (mut lb ListBox) init_items() {
	for i, mut item in lb.items {
		// println("$i $item.text get ot draw-> ${lb.get_draw_to(item.text)}")
		item.draw_text = item.text[0..lb.get_draw_to(item.text)]
		item.x = 0
		item.y = lb.item_height * i
		// println("item init $i, $item.text, $item.x $item.y")
	}
}

pub fn (mut lb ListBox) add_item(id string, text string) {
	lb.append_item(id, text, lb.get_draw_to(text))
	lb.update_adj_size()
}

pub fn (mut lb ListBox) append_item(id string, text string, draw_to int) {
	lb.items << &ListItem{
		x: 0
		y: lb.item_height * lb.items.len
		id: id
		text: text
		list: unsafe { lb }
		draw_text: text[0..draw_to]
	}
}

pub fn (mut lb ListBox) remove_item(id string) {
	for i in 0 .. lb.items.len {
		if lb.items[i].id == id {
			lb.remove_inx(i)
			lb.update_adj_size()
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

pub fn (mut lb ListBox) move_inx_by(i int, delta int) {
	if i < 0 || i >= lb.items.len || delta == 0 || i + delta < 0 || i + delta >= lb.items.len {
		return
	}
	mut cur := -1
	if delta < 0 {
		if delta == -1 {
			cur = i - 1
		} else {
			for d in 0 .. (-delta) {
				lb.move_inx_by(i - d, -1)
			}
		}
	} else {
		if delta == 1 {
			cur = i
		} else {
			for d in 0 .. delta {
				lb.move_inx_by(i + d, 1)
			}
		}
	}
	if cur >= 0 {
		if lb.selection == i {
			lb.selection = i + delta
		} else if lb.selection == i + delta {
			lb.selection = i
		}
		// swap items cur and cur + 1
		if cur == lb.selection {
			lb.selection
		}
		lb.items[cur], lb.items[cur + 1] = lb.items[cur + 1], lb.items[cur]
		if cur == lb.dragged_item {
			lb.items[cur].y -= lb.item_height
		}
		if cur + 1 == lb.dragged_item {
			lb.items[cur + 1].y += lb.item_height
		}
	}
}

pub fn (lb &ListBox) is_selected() bool {
	if lb.selection < 0 || lb.selection >= lb.items.len {
		return false
	}
	return true
}

pub fn (lb &ListBox) is_item_selected(inx int) bool {
	return lb.selectable && if lb.multi {
		lb.items[inx].selected && !lb.items[inx].disabled
	} else {
		inx == lb.selection
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

pub fn (lb &ListBox) is_enabled_item(inx int) bool {
	return !lb.items[inx].disabled
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

[manualfree]
pub fn (mut lb ListBox) clear() {
	for item in lb.items {
		unsafe { item.free() }
	}
	lb.items.clear()
	lb.selection = -1
}

fn (lb &ListBox) selected_item(y int) int {
	inx := (y - lb.y) / lb.item_height
	return if inx < 0 || inx >= lb.items.len { -1 } else { inx }
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
	offset_start(mut lb)
	DrawTextWidget(lb).load_style()
	// scrollview_clip(mut lb)
	scrollview_draw_begin(mut lb)
	height := if lb.has_scrollview && lb.adj_height > lb.height {
		lb.adj_height + lb.text_offset_y
	} else {
		lb.height
	}
	$if lb_draw ? {
		println('draw $lb.id scrollview=$lb.has_scrollview $lb.x, $lb.y, $lb.width $lb.height $height')
	}
	lb.ui.gg.draw_rect_filled(lb.x, lb.y, lb.width, height, lb.col_bkgrnd)
	// println("draw rect")
	from, to := lb.visible_items()
	if lb.items.len == 0 {
		$if nodtw ? {
			draw_text_with_color(lb, lb.x + ui._text_offset_x, lb.y + lb.text_offset_y,
				if lb.files_droped { 'Empty listbox. Drop files here ...' } else { '' },
				gx.gray)
		} $else {
			DrawTextWidget(lb).draw_styled_text(lb.x + ui._text_offset_x, lb.y + lb.text_offset_y,
				if lb.files_droped { 'Empty listbox. Drop files here ...' } else { '' },
				color: gx.gray)
		}
	} else {
		for inx, item in lb.items {
			// println("$inx >= $lb.draw_count")
			if inx >= lb.draw_count && !has_scrollview(lb) {
				break
			}
			if !has_scrollview(lb) || (inx >= from && inx <= to) {
				if lb.dragged_item != inx {
					lb.draw_item(item, inx)
				}
			}
		}
		if lb.dragged_item >= 0 && lb.dragged_item < lb.items.len {
			lb.draw_item(lb.items[lb.dragged_item], lb.dragged_item)
		}
	}
	if !lb.draw_lines {
		lb.ui.gg.draw_rect_empty(lb.x - 1, lb.y - 1, lb.width + 2, height + 2, lb.col_border)
	}

	// scrollview_draw(lb)
	scrollview_draw_end(lb)
	offset_end(mut lb)
}

fn (mut lb ListBox) draw_item(li ListItem, inx int) {
	col := if lb.is_item_selected(inx) { lb.col_selected } else { lb.col_bkgrnd }
	width := if lb.has_scrollview && lb.adj_width > lb.width { lb.adj_width } else { lb.width }
	$if lb_draw_item ? {
		println('draw item  $li.draw_text $li.x + $lb.x + $ui._text_offset_x, $li.y + $lb.y + $lb.text_offset_y, $lb.width, $lb.item_height')
	}
	lb.ui.gg.draw_rect_filled(li.x + li.offset_x + lb.x + ui._text_offset_x, li.y + li.offset_y +
		lb.y + lb.text_offset_y, width - 2 * ui._text_offset_x, lb.item_height, col)
	$if nodtw ? {
		lb.ui.gg.draw_text_def(li.x + li.offset_x + lb.x + ui._text_offset_x, li.y + li.offset_y +
			lb.y + lb.text_offset_y, if lb.has_scrollview { li.text } else { li.draw_text })
	} $else {
		DrawTextWidget(lb).draw_styled_text(li.x + li.offset_x + lb.x + ui._text_offset_x,
			li.y + li.offset_y + lb.y + lb.text_offset_y, if lb.has_scrollview {
			li.text
		} else {
			li.draw_text
		},
			color: if lb.is_enabled_item(inx) { gx.black } else { lb.col_disabled }
		)
	}
	if lb.draw_lines {
		// println("line item $li.x + $lb.x, $li.y + $lb.x, $lb.width, $lb.item_height")
		lb.ui.gg.draw_rect_empty(li.x + li.offset_x + lb.x + ui._text_offset_x, li.y + li.offset_y +
			lb.y + lb.text_offset_y, width - 2 * ui._text_offset_x, lb.item_height, lb.col_border)
	}
}

fn (mut lb ListBox) get_draw_to(text string) int {
	if lb.has_scrollview {
		return 0
	}
	width := text_width(lb, text)
	real_w := lb.width + ui._text_offset_x * 2
	mut draw_to := text.len
	if width >= real_w {
		draw_to = int(f32(text.len) * (f32(real_w) / f32(width)))
		for draw_to > 1 && text_width(lb, text[0..draw_to]) > real_w {
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
				if lb.set_item_selected(inx, ctl_key(lb.ui.keymods)) {
					lb.call_on_change()
				}
				break
			}
		}
	} $else {
		inx := lb.selected_item(e.y)
		if inx >= 0 && lb.set_item_selected(inx, ctl_key(lb.ui.keymods)) {
			lb.call_on_change()
		}
	}
}

pub fn (lb &ListBox) call_on_change() {
	if lb.on_change != ListBoxSelectionChangedFn(0) {
		lb.on_change(lb.ui.window.state, lb)
	}
}

fn lb_mouse_down(mut lb ListBox, e &MouseEvent, window &Window) {
	$if lb_md ? {
		println('lb_mouse_down $lb.id top_widget ${lb.ui.window.is_top_widget(lb, events.on_mouse_down)}')
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
			dragged_item := lb.selected_item(e.y)
			if dragged_item >= 0 {
				di := lb.items[dragged_item]
				lb.just_dragged = drag_register(di, e)
				if lb.just_dragged {
					lb.dragged_item = dragged_item
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
	if lb.dragged_item >= 0 {
		// reinit dragged item
		lb.items[lb.dragged_item].x, lb.items[lb.dragged_item].y = 0, lb.dragged_item * lb.item_height
		lb.items[lb.dragged_item].offset_x, lb.items[lb.dragged_item].offset_y = 0, 0
		lb.dragged_item = -1
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
		// println("$lb.id $lb.dragged_item ${dragger_inside_dropzone(mut lb)}")
		if lb.dragged_item >= 0 {
			// println("hereee $lb.dragged_item")
			j := lb.selected_item(int(e.y))
			if j >= 0 && (j == lb.dragged_item - 1 || j == lb.dragged_item + 1) {
				// println('herrrreee $lb.dragged_item $j')
				lb.move_inx_by(lb.dragged_item, j - lb.dragged_item)
				lb.dragged_item = j
			}
		} else if dragger_intersect_dropzone(mut lb) {
			println('couocu $lb.id <$lb.ui.window.dragger.widget.id>')
		}
	}

	// 		if b.hoverable && !b.to_hover {
	// 			b.to_hover = true
	// 		}
	// 	} else {
	// 		if b.hoverable && b.to_hover {
	// 			b.to_hover = false
	// 		}
	// 		b.state = .normal
	// 	}
	// }
}

fn on_files_droped(mut lb ListBox, e &MouseEvent, window &Window) {
	// println("on_files_droped")
	if lb.hidden {
		return
	}
	// println("on files: inside ${lb.point_inside(e.x, e.y)}")
	if !lb.point_inside(e.x, e.y) {
		return
	}
	// println("${lb.ui.window.point_inside_receivers(events.on_files_droped)}")
	// if !lb.ui.window.is_top_widget(lb, events.on_files_droped) {
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
	if lb.on_change != ListBoxSelectionChangedFn(0) {
		lb.on_change(window.state, lb)
	}
}

pub fn (mut lb ListBox) set_pos(x int, y int) {
	if lb.x != x || lb.y != y {
		// println("set pos lb: $x, $y")
		lb.x = x
		lb.y = y
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
		for item in lb.items {
			width = text_width(lb, item.text) + ui._text_offset_x * 2
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
	for item in lb.items {
		width = text_width(lb, item.text) + ui._text_offset_x * 2
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

[heap]
struct ListItem {
	id   string
	list &ListBox
mut:
	x         int
	y         int
	offset_x  int
	offset_y  int
	z_index   int
	draw_text string
pub mut:
	text     string
	disabled bool
	selected bool
}

[unsafe]
fn (item &ListItem) free() {
	$if free ? {
		print('\tlistbox item $item.id')
	}
	unsafe {
		item.id.free()
		item.text.free()
		item.draw_text.free()
		// Failing: free(item)
	}
	$if free ? {
		println(' -> freed')
	}
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
