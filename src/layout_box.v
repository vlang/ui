module ui

// import gx
import gg
import eventbus

/*
Goal:
1) Children are located relatively to the size of the parent box_layout
2) Two options:
	a) size of box_layout is fixed (=> use of srollview if parent does not allocate enough space)
	b) size of box_layout is not fixed and then only deduced from the parent.

NEW:
a) sizes:
	1) float between 0.0 to 100.0 expresses relative size in percentage of the full size (stored in f32 between 0.0 and 1.0)
	2) integer expresses absolute size (stored between 1.0001 and ....)
	3) <id>.w and <id>.h where <id> is an already defined box_layout child
	4) TODO: math expression: min(w1,w2), <id>.w+dw, <id>.w-dw, <id>.w * cw, <id>.w/cw
a) coordinates:
	1) float between 0.0 to 100.0 expresses expresses relative coordinate in percentage of the full size
	2) integer expresses absolute coordinate
	3) x or y absolute coordinates from top-left corner
	4) -x or -y absolute coordinates from bottom-right corner
b) widget position and size:
	1) (xLeft,yTop) -> (xRight,yBottom) or (xRight,yBottom) <- (xLeft,yTop) => storage: Bounding{LeftTopToRightBottom}
	2) (x,y) ++ (w,h) equivalent to (x,y) -> (x+w,y+h) => storage: Bounding{gg.Rect} (x,y)==(xLeft,yTop) w>0,h>0
	3) (x,y) -- (w,h) equivalent to (x-w,y-h) -> (x,y) => storage: Bounding{gg.Rect} (x,y)==(xRight,yBottom) w<0,h<0
*/

// IMPORTANT: No margins since users can add relative or absolute ones manually

struct LeftTopToRightBottom {
mut:
	x_left   f32
	x_right  f32
	y_top    f32
	y_bottom f32
}

union Box {
	gg.Rect
	LeftTopToRightBottom
}

enum BoxMode {
	left_top_width_height
	left_top_right_bottom
}

// TODO: add bg_color
[heap]
pub struct BoxLayout {
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
	child_box        []Box
	child_id         []string
	child_mode       []BoxMode
	children         []Widget
	drawing_children []Widget
	hidden           bool
	is_root_layout   bool = true
	// component state for composable widget
	component voidptr
	// debug stuff to be removed
	debug_ids []string
}

[params]
pub struct BoxLayoutParams {
pub mut:
	id       string
	x        int
	y        int
	width    int
	height   int
	children map[string]Widget
}

pub fn box_layout(c BoxLayoutParams) &BoxLayout {
	mut b := &BoxLayout{
		id: c.id
		x: c.x
		y: c.y
		width: c.width
		height: c.height
		ui: 0
	}
	for key, child in c.children {
		b.parse_child(key, child)
	}
	return b
}

fn (mut b BoxLayout) parse_child(key string, child Widget) {
	tmp := key.split_any('@:')
	id, tmp_rect := if tmp.len > 1 {
		tmp[0], tmp[1]
	} else {
		b.id + '_' + key, tmp[0]
	}
	if tmp_rect.contains_any_substr(['++', '--', '->', '<-']) {
		// TODO
		// lt2rb := LeftTopToRightBottom{0.0,0.0,0.0,0.0}
		// a := Bounding{LeftTopToRightBottom: lt2rb}
		// unsafe{println(a.x_left)}
	} else if tmp_rect.contains('x') { // (x,y,w,h) mode
		vec4 := tmp_rect.split('x').map(it.f32())
		rect := if vec4.len == 4 {
			gg.Rect{vec4[0], vec4[1], vec4[2], vec4[3]}
		} else {
			gg.Rect{0.0, 0.0, 0.0, 0.0}
		}
		b.child_id << id
		b.child_box << Box{
			Rect: rect
		}
		b.child_mode << BoxMode.left_top_width_height
		b.children << child
	} else if tmp_rect.contains(',') { // (xLeft,yTop,xRight,yBottom) mode
		vec4 := tmp_rect.split(',').map(it.f32())
		lt2rb := if vec4.len == 4 {
			LeftTopToRightBottom{vec4[0], vec4[1], vec4[2], vec4[3]}
		} else {
			LeftTopToRightBottom{0.0, 0.0, 0.0, 0.0}
		}
		b.child_id << id
		b.child_box << Box{
			LeftTopToRightBottom: lt2rb
		}
		b.child_mode << BoxMode.left_top_right_bottom
		b.children << child
	}
}

fn (mut b BoxLayout) init(parent Layout) {
	b.parent = parent
	mut ui := parent.get_ui()
	b.ui = ui
	for mut child in b.children {
		// println('gl init child ${child.id} ')
		child.init(b)
	}
	b.decode_size()
	b.set_children_pos_and_size()
	b.set_root_layout()
}

// Determine wheither BoxLayout b is a root layout
fn (mut b BoxLayout) set_root_layout() {
	if mut b.parent is Window {
		// TODO: before removing line below test if this is necessary
		// b.ui.window = unsafe { b.parent }
		mut window := unsafe { b.parent }
		if b.is_root_layout {
			window.root_layout = b
			// window.update_layout()
		} else {
			b.update_layout()
		}
	} else {
		b.is_root_layout = false
	}
}

[manualfree]
pub fn (mut b BoxLayout) cleanup() {
	for mut child in b.children {
		child.cleanup()
	}
	unsafe {
		b.free()
	}
}

[unsafe]
pub fn (b &BoxLayout) free() {
	$if free ? {
		print('group ${b.id}')
	}
	unsafe {
		b.id.free()
		b.child_id.free()
		b.child_box.free()
		b.children.free()
		free(b)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (mut b BoxLayout) decode_size() {
	parent_width, parent_height := b.parent.size()
	if b.is_root_layout {
		// full size from window
		b.width, b.height = -100, -100
	}
	// Relative sizes
	b.width = relative_size_from_parent(b.width, parent_width)
	b.height = relative_size_from_parent(b.height, parent_height)
	// }
	// println('b size: ($b.width, $b.height) ($parent_width, $parent_height) ')
	// debug_show_size(s, "decode after -> ")
}

fn (mut b BoxLayout) set_pos(x int, y int) {
	b.x = x
	b.y = y
	b.set_children_pos_and_size()
}

pub fn (mut b BoxLayout) set_children_pos() {
	// mut widgets := b.children.clone()
	mut start_x := f32(b.x)
	mut start_y := f32(b.y)
	w := f32(b.width) / 100.0
	h := f32(b.height) / 100.0
	// println('size: $b.width, $b.height $w, $h $b.child_box')
	for i, mut child in b.children {
		// println('widget.set_pos($i) $widget.id ${int(start_x + w * b.child_box[i].x)}, ${int(
		// start_y + h * b.child_box[i].y)})')
		// println("size(${int(w * b.child_box[i].width)}, ${int(h * b.child_box[i].height)})")
		unsafe {
			child.set_pos(int(start_x + w * b.child_box[i].x), int(start_y + h * b.child_box[i].y))
		}
		if mut child is Stack {
			child.update_layout()
		}
	}
}

fn (mut b BoxLayout) set_children_pos_and_size() {
	$if bl_scps ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('gridlayout scps ${b.id} size: (${b.width}, ${b.height})')
		}
	}
	// mut widgets := b.children.clone()
	mut start_x := f32(b.x)
	mut start_y := f32(b.y)
	w := f32(b.width) / 100.0
	h := f32(b.height) / 100.0
	// println('size: $b.width, $b.height $w, $h $b.child_box')
	for i, mut widget in b.children {
		// if b.child_rect_bounding
		// println('widget.set_pos($i) $widget.id ${int(start_x + w * b.child_box[i].x)}, ${int(
		// start_y + h * b.child_box[i].y)})')
		// println("size(${int(w * b.child_box[i].width)}, ${int(h * b.child_box[i].height)})")
		unsafe {
			widget.set_pos(int(start_x + w * b.child_box[i].x), int(start_y + h * b.child_box[i].y))
			widget.propose_size(int(w * b.child_box[i].width), int(h * b.child_box[i].height))
		}
	}
	$if bl_scps ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('gridlayout scps ${b.id} size: (${b.width}, ${b.height})')
		}
	}
}

fn (mut b BoxLayout) draw() {
	b.draw_device(mut b.ui.dd)
}

fn (mut b BoxLayout) draw_device(mut d DrawDevice) {
	offset_start(mut b)
	// Border
	$if bldraw ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('box_layout ${b.id} size: (${b.width}, ${b.height})')
		}
	}
	for mut child in b.children {
		// println("$b.id -> ${child.id} drawn at ${child.x}, ${child.y} ${child.size()}")
		child.draw_device(mut d)
	}
	offset_end(mut b)
}

fn (b &BoxLayout) point_inside(x f64, y f64) bool {
	return point_inside(b, x, y)
}

fn (mut b BoxLayout) set_visible(state bool) {
	b.hidden = !state
}

fn (b &BoxLayout) get_ui() &UI {
	return b.ui
}

fn (mut b BoxLayout) resize(width int, height int) {
	// println("resize ${width}, ${height}")
	b.propose_size(width, height)
	b.set_children_pos()
}

fn (b &BoxLayout) get_subscriber() &eventbus.Subscriber {
	parent := b.parent
	return parent.get_subscriber()
}

fn (mut b BoxLayout) propose_size(w int, h int) (int, int) {
	b.width = w
	b.height = h
	// println('b prop size: ($w, $h)')
	$if bps ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('box_layout ${b.id} propose size: (${b.width}, ${b.height})')
		}
	}
	b.set_children_pos_and_size()
	return b.width, b.height
}

fn (b &BoxLayout) size() (int, int) {
	return b.width, b.height
}

fn (b &BoxLayout) get_children() []Widget {
	return b.children
}

fn (mut b BoxLayout) update_layout() {
	if b.is_root_layout {
		window := b.ui.window
		mut to_resize := window.mode in [.fullscreen, .max_size, .resizable]
		$if android {
			to_resize = true
		}
		if to_resize {
			b.resize(window.width, window.height)
		}
	}
	b.set_children_pos_and_size()
	for mut child in b.children {
		if mut child is Stack {
			child.update_layout()
		}
	}
	b.set_drawing_children()
}

fn (mut b BoxLayout) set_drawing_children() {
	for mut child in b.children {
		if mut child is Stack {
			child.set_drawing_children()
		} else if mut child is CanvasLayout {
			child.set_drawing_children()
		} else if mut child is BoxLayout {
			child.set_drawing_children()
		}
		// println("z_index: ${child.type_name()} $child.z_index")
		if child.z_index > b.z_index {
			$if cl_z_index_update ? {
				println('${b.id} changed z_index from ${child.id} ${child.z_index}')
			}
			b.z_index = child.z_index - 1
		}
	}
	b.drawing_children = b.children.filter(!it.hidden)
	b.sorted_drawing_children()
}

// absolute or relative size with respect to parent size
pub fn absolute_or_relative_size(size f32, parent_size int) f32 {
	return if size < -1.0 || size > 1.0 { // size outside [-1.0, 1.0]
		size // absolute size
	} else if size < 0 { // size inside ]-1.0,0.0[
		percent := f32(-size) / 100
		new_size := percent * parent_size
		// println('relative size: ${size} ${new_size} -> ${percent} * ${parent_size}) ')
		new_size
	} else { // size inside ]0.0,1.0[
		percent := f32(size) / 100
		new_size := percent * parent_size
		// println('relative size: ${size} ${new_size} -> ${percent} * ${parent_size}) ')
		new_size
	}
}
