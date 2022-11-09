module ui

import gx
import gg
import eventbus

/*
Goal:
1) Children are located relatively to the size of the parent grid_layout
2) Two options:
	a) size of grid_layout is fixed (=> use of srollview if parent does not allocate enough space)
	b) size of grid_layout is not fixed and then only deduced from the parent.
*/

[heap]
pub struct GridLayout {
pub mut:
	id         string
	height     int
	width      int
	x          int
	y          int
	offset_x   int
	offset_y   int
	z_index    int
	is_focused bool
	parent     Layout = empty_stack
	ui         &UI    = unsafe { nil }
	// children
	child_rects   []gg.Rect
	child_ids     []string
	children      []Widget
	margin_left   int = 5
	margin_top    int = 5
	margin_right  int = 5
	margin_bottom int = 5
	adj_height    int
	adj_width     int
	hidden        bool
	// component state for composable widget
	component voidptr
	// debug stuff to be removed
	debug_ids []string
}

[params]
pub struct GridLayoutParams {
pub mut:
	id       string
	x        int
	y        int
	width    int
	height   int
	children map[string]Widget
}

pub fn grid_layout(c GridLayoutParams) &GridLayout {
	mut g := &GridLayout{
		id: c.id
		x: c.x
		y: c.y
		width: c.width
		height: c.height
		ui: 0
	}
	for key, child in c.children {
		g.parse_child(key, child)
	}
	return g
}

fn (mut g GridLayout) parse_child(key string, child Widget) {
	tmp := key.split('@')
	sizes := tmp[1].split('x').map(it.f32())
	rect := gg.Rect{sizes[0], sizes[1], sizes[2], sizes[3]}
	g.child_ids << tmp[0]
	g.child_rects << rect
	g.children << child
}

fn (mut g GridLayout) init(parent Layout) {
	g.parent = parent
	ui := parent.get_ui()
	g.ui = ui
	g.decode_size()
	for mut child in g.children {
		child.init(g)
	}
	g.calculate_child_positions()
}

[manualfree]
pub fn (mut g GridLayout) cleanup() {
	for mut child in g.children {
		child.cleanup()
	}
	unsafe {
		g.free()
	}
}

[unsafe]
pub fn (g &GridLayout) free() {
	$if free ? {
		print('group $g.id')
	}
	unsafe {
		g.id.free()
		g.child_ids.free()
		g.child_rects.free()
		g.children.free()
		free(g)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (mut g GridLayout) decode_size() {
	parent_width, parent_height := g.parent.size()
	// Relative sizes
	g.width = relative_size_from_parent(g.width, parent_width)
	g.height = relative_size_from_parent(g.height, parent_height)
	// }
	// println('g size: ($g.width, $g.height) ($parent_width, $parent_height) ')
	// debug_show_size(s, "decode after -> ")
}

fn (mut g GridLayout) set_pos(x int, y int) {
	g.x = x
	g.y = y
	g.calculate_child_positions()
}

fn (mut g GridLayout) calculate_child_positions() {
	$if glccp ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('gridlayout ccp $g.id size: ($g.width, $g.height)')
		}
	}
	mut widgets := g.children.clone()
	mut start_x := g.x + g.margin_left
	mut start_y := g.y + g.margin_top
	w := g.width - g.margin_right - g.margin_left
	h := g.height - g.margin_top - g.margin_bottom
	for i, mut widget in widgets {
		widget.set_pos(int(start_x + w * g.child_rects[i].x), int(start_y + h * g.child_rects[i].y))
		widget.propose_size(int(w * g.child_rects[i].width), int(h * g.child_rects[i].height))
	}
	$if glccp ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('gridlayout ccp2 $g.id size: ($g.width, $g.height)')
		}
	}
}

fn (mut g GridLayout) draw() {
	g.draw_device(g.ui.gg)
}

fn (mut g GridLayout) draw_device(d DrawDevice) {
	offset_start(mut g)
	// Border
	$if gdraw ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('group $g.id size: ($g.width, $g.height)')
		}
	}
	d.draw_rect_empty(g.x, g.y, g.width, g.height, gx.gray)
	for mut child in g.children {
		child.draw_device(d)
	}
	offset_end(mut g)
}

fn (g &GridLayout) point_inside(x f64, y f64) bool {
	return point_inside(g, x, y)
}

fn (mut g GridLayout) set_visible(state bool) {
	g.hidden = !state
}

fn (g &GridLayout) get_ui() &UI {
	return g.ui
}

fn (g &GridLayout) resize(width int, height int) {
}

fn (g &GridLayout) get_subscriber() &eventbus.Subscriber {
	parent := g.parent
	return parent.get_subscriber()
}

fn (mut g GridLayout) set_adjusted_size(i int, ui &UI) {
	mut h, mut w := 0, 0
	for mut child in g.children {
		mut child_width, mut child_height := child.size()

		$if ui_group ? {
			println('$i $child.type_name() => child_width, child_height: $child_width, $child_height')
		}

		h += child_height // height of vertical stack means adding children's height
		if child_width > w { // width of vertical stack means greatest children's width
			w = child_width
		}
	}
	g.adj_width = w
	g.adj_height = h
	$if adj_size_group ? {
		println('group $g.id adj size: ($g.adj_width, $g.adj_height)')
	}
}

fn (g &GridLayout) adj_size() (int, int) {
	return g.adj_width, g.adj_height
}

fn (mut g GridLayout) propose_size(w int, h int) (int, int) {
	g.width = w
	g.height = h
	// println('g prop size: ($w, $h)')
	$if gps ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('group $g.id propose size: ($g.width, $g.height)')
		}
	}
	return g.width, g.height
}

fn (g &GridLayout) size() (int, int) {
	return g.width, g.height
}

fn (g &GridLayout) get_children() []Widget {
	return g.children
}

fn (g &GridLayout) update_layout() {}
