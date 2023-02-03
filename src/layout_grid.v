module ui

// import gx
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
	child_rects    []gg.Rect
	child_ids      []string
	children       []Widget
	margin_left    int = 5
	margin_top     int = 5
	margin_right   int = 5
	margin_bottom  int = 5
	adj_height     int
	adj_width      int
	hidden         bool
	is_root_layout bool = true
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
	id, tmp_sizes := if tmp.len > 1 {
		tmp[0], tmp[1]
	} else {
		g.id + '_' + key, tmp[0]
	}
	sizes := tmp_sizes.split('x').map(it.f32())
	rect := if sizes.len == 4 {
		gg.Rect{sizes[0], sizes[1], sizes[2], sizes[3]}
	} else {
		gg.Rect{0.0, 0.0, 0.0, 0.0}
	}
	g.child_ids << id
	g.child_rects << rect
	g.children << child
}

fn (mut g GridLayout) init(parent Layout) {
	g.parent = parent
	mut ui := parent.get_ui()
	g.ui = ui
	if parent is Window {
		ui.window = unsafe { parent }
		mut window := unsafe { parent }
		if g.is_root_layout {
			window.root_layout = g
			window.update_layout() // i.e s.update_all_children_recursively(parent)
		} else {
			g.update_layout()
		}
	} else {
		g.is_root_layout = false
	}

	for mut child in g.children {
		child.init(g)
	}
	g.decode_size()
	g.calculate_children()
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
		print('group ${g.id}')
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
	if g.is_root_layout {
		g.width, g.height = -100, -100
	}
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
	g.calculate_children()
}

fn (mut g GridLayout) calculate_children() {
	$if glccp ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('gridlayout ccp ${g.id} size: (${g.width}, ${g.height})')
		}
	}
	// mut widgets := g.children.clone()
	mut start_x := f32(g.x + g.margin_left)
	mut start_y := f32(g.y + g.margin_top)
	w := f32(g.width - g.margin_right - g.margin_left) / 100.0
	h := f32(g.height - g.margin_top - g.margin_bottom) / 100.0
	// println('size: $g.width, $g.height $w, $h $g.child_rects')
	for i, mut widget in g.children {
		// println('widget.set_pos($i) $widget.id ${int(start_x + w * g.child_rects[i].x)}, ${int(
		// start_y + h * g.child_rects[i].y)})')
		widget.set_pos(int(start_x + w * g.child_rects[i].x), int(start_y + h * g.child_rects[i].y))
		widget.propose_size(int(w * g.child_rects[i].width), int(h * g.child_rects[i].height))
	}
	$if glccp ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('gridlayout ccp2 ${g.id} size: (${g.width}, ${g.height})')
		}
	}
}

fn (mut g GridLayout) draw() {
	g.draw_device(mut g.ui.dd)
}

fn (mut g GridLayout) draw_device(mut d DrawDevice) {
	offset_start(mut g)
	// Border
	$if gldraw ? {
		if g.debug_ids.len == 0 || g.id in g.debug_ids {
			println('grid_layout ${g.id} size: (${g.width}, ${g.height})')
		}
	}
	for mut child in g.children {
		// println("${child.id} drawn at ${child.x}, ${child.y} ${child.size()}")
		child.draw_device(mut d)
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

fn (mut g GridLayout) resize(width int, height int) {
	// println("resize ${width}, ${height}")
	g.propose_size(width, height)
}

fn (g &GridLayout) get_subscriber() &eventbus.Subscriber {
	parent := g.parent
	return parent.get_subscriber()
}

fn (mut g GridLayout) set_adjusted_size(i int, ui &UI) {
	g.adj_width = g.width
	g.adj_height = g.height
	// $if adj_size_group ? {
	// 	println('group $g.id adj size: ($g.adj_width, $g.adj_height)')
	// }
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
			println('grid_layout ${g.id} propose size: (${g.width}, ${g.height})')
		}
	}
	g.calculate_children()
	return g.width, g.height
}

fn (g &GridLayout) size() (int, int) {
	return g.width, g.height
}

fn (g &GridLayout) get_children() []Widget {
	return g.children
}

fn (mut g GridLayout) update_layout() {
	if g.is_root_layout {
		window := g.ui.window
		mut to_resize := window.mode in [.fullscreen, .max_size, .resizable]
		$if android {
			to_resize = true
		}
		if to_resize {
			g.resize(window.width, window.height)
		}
	}
	g.calculate_children()
}
