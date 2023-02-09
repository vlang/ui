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
	1) (xLeft,yTop) -> (xRight,yBottom) => storage: Box{LeftTopToRightBottom}
	2) (x,y) ++ (w,h) equivalent to (x,y) -> (x+w,y+h) => storage: Box{gg.Rect} (x,y)==(xLeft,yTop) w>0,h>0
	3) (x,y) -- (w,h) equivalent to (x-w,y-h) -> (x,y) => storage: Box{gg.Rect} (x,y)==(xRight,yBottom) w<0,h<0
	4) (x,y) .. (w,h) equivalent to (x-w/2,y-h/2) -> (x+w/2,y+h/2) => storage: Box{gg.Rect} (x,y)==(xRight,yBottom) w<0,h<0
	5) When xLeft,yTop,xRight,yBottom are relative one can fancy to add absolute coordinate left_offset, right_offset, top_offset, bottom_offset
		(xLeft + left_offset, yTop + top_offset) -> (xRight + right_offset,yBottom + bottom_offset) => storage: Box{LeftTopToRightBottom} but with values being float which absolute value is the sum of integer and real between 0 and 1
*/

// IMPORTANT: No margins since users can add relative or absolute ones manually

struct LeftTopToRightBottom {
mut:
	x_left   f32
	y_top    f32
	x_right  f32
	y_bottom f32
}

union Box {
	gg.Rect
	LeftTopToRightBottom
}

enum BoxMode {
	left_top_width_height // width>0, height>0
	right_top_width_height // width<0, height>0
	right_bottom_width_height // width<0, height<0
	left_bottom_width_height // width>0, height<0
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
	mut tmp2 := []string{}
	id, tmp_rect := if tmp.len > 1 {
		tmp[0], tmp[1]
	} else {
		b.id + '_' + key, tmp[0]
	}
	if tmp_rect.contains('++') {
		tmp2 = tmp_rect.split('++').map(it.trim_space())
		mut tmp3 := tmp2[0].find_between('(', ')')
		if !tmp3.is_blank() {
			mut vec4 := tmp3.split(',').map(it.f32())
			tmp3 = tmp2[1].find_between('(', ')')
			vec4 << tmp3.split(',').map(it.f32())
			b.add_rect_child(id, child, vec4)
		}
	} else if tmp_rect.contains('-+') {
		tmp2 = tmp_rect.split('-+').map(it.trim_space())
		mut tmp3 := tmp2[0].find_between('(', ')')
		if !tmp3.is_blank() {
			mut vec4 := tmp3.split(',').map(it.f32())
			tmp3 = tmp2[1].find_between('(', ')')
			vec4 << tmp3.split(',').map(it.f32())
			vec4[2] -= vec4[2]
			b.add_rect_child(id, child, vec4)
		}
	} else if tmp_rect.contains('--') {
		tmp2 = tmp_rect.split('--').map(it.trim_space())
		mut tmp3 := tmp2[0].find_between('(', ')')
		if !tmp3.is_blank() {
			mut vec4 := tmp3.split(',').map(it.f32())
			tmp3 = tmp2[1].find_between('(', ')')
			vec4 << tmp3.split(',').map(it.f32())
			vec4[2] -= vec4[2]
			vec4[3] -= vec4[3]
			b.add_rect_child(id, child, vec4)
		}
	} else if tmp_rect.contains('+-') {
		tmp2 = tmp_rect.split('--').map(it.trim_space())
		mut tmp3 := tmp2[0].find_between('(', ')')
		if !tmp3.is_blank() {
			mut vec4 := tmp3.split(',').map(it.f32())
			tmp3 = tmp2[1].find_between('(', ')')
			vec4 << tmp3.split(',').map(it.f32())
			vec4[3] -= vec4[3]
			b.add_rect_child(id, child, vec4)
		}
	} else if tmp_rect.contains('->') {
		tmp2 = tmp_rect.split('->').map(it.trim_space())
		mut tmp3 := tmp2[0].find_between('(', ')')
		if !tmp3.is_blank() {
			mut vec4 := tmp3.split(',').map(it.f32())
			tmp3 = tmp2[1].find_between('(', ')')
			vec4 << tmp3.split(',').map(it.f32())
			b.add_lt2rb_child(id, child, vec4)
		}
	} else if tmp_rect.contains('x') { // (xLeft,yTop,xRight,yBottom) mode
		tmp2 = tmp_rect.split('x').map(it.trim_space())
		mut vec4 := tmp2[0].split(',').map(it.f32())
		vec4 << tmp2[1].split(',').map(it.f32())
		b.add_lt2rb_child(id, child, vec4)
	} else if tmp_rect.contains(',') { // (x,y,w,h) mode
		vec4 := tmp_rect.split(',').map(it.f32())
		b.add_rect_child(id, child, vec4)
	}
}

fn (mut b BoxLayout) add_lt2rb_child(id string, child Widget, vec4 []f32) {
	lt2rb := if vec4.len == 4 {
		LeftTopToRightBottom{vec4[0], vec4[1], vec4[2], vec4[3]}
	} else {
		LeftTopToRightBottom{0.0, 0.0, 0.0, 0.0}
	}
	// println(lt2rb)
	b.child_id << id
	b.child_box << Box{
		LeftTopToRightBottom: lt2rb
	}
	b.child_mode << BoxMode.left_top_right_bottom
	b.children << child
}

fn (mut b BoxLayout) add_rect_child(id string, child Widget, vec4 []f32) {
	rect := if vec4.len == 4 {
		gg.Rect{vec4[0], vec4[1], vec4[2], vec4[3]}
	} else {
		gg.Rect{0.0, 0.0, 0.0, 0.0}
	}
	b.child_id << id
	b.child_box << Box{
		Rect: rect
	}
	b.child_mode << box_direction(rect) // BoxMode.left_top_width_height
	b.children << child
}

fn (mut b BoxLayout) init(parent Layout) {
	b.parent = parent
	mut ui := parent.get_ui()
	b.ui = ui
	for i, mut child in b.children {
		child.id = b.child_id[i]
		// println('$i) gl init child ${child.id} ')
		child.init(b)
		// unsafe{println('$i) end init ${b.child_box[i]}')}
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

pub fn (b &BoxLayout) set_child_pos(i int, mut child Widget) {
	mut x, mut y := 0, 0
	unsafe {
		match b.child_mode[i] {
			.left_top_width_height {
				x = b.x + absolute_or_relative_pos(b.child_box[i].x, b.width)
				y = b.y + absolute_or_relative_pos(b.child_box[i].y, b.height)
			}
			.right_top_width_height {
				x = b.x + absolute_or_relative_pos(b.child_box[i].x, b.width) +
					absolute_or_relative_size(b.child_box[i].width, b.width)
				y = b.y + absolute_or_relative_pos(b.child_box[i].y, b.height)
			}
			.right_bottom_width_height {
				x = b.x + absolute_or_relative_pos(b.child_box[i].x, b.width) +
					absolute_or_relative_size(b.child_box[i].width, b.width)
				y = b.y + absolute_or_relative_pos(b.child_box[i].y, b.height) +
					absolute_or_relative_size(b.child_box[i].height, b.height)
			}
			.left_bottom_width_height {
				x = b.x + absolute_or_relative_pos(b.child_box[i].x, b.width)
				y = b.y + absolute_or_relative_pos(b.child_box[i].y, b.height) +
					absolute_or_relative_size(b.child_box[i].height, b.height)
			}
			.left_top_right_bottom {
				x = b.x + absolute_or_relative_pos(b.child_box[i].x_left, b.width)
				y = b.y + absolute_or_relative_pos(b.child_box[i].y_top, b.height)
			}
		}
	}
	// println("$child.id: x,y =($x, $y)")
	child.set_pos(x, y)
}

pub fn (b &BoxLayout) set_child_size(i int, mut child Widget) {
	mut w, mut h := 0, 0
	unsafe {
		match b.child_mode[i] {
			.left_top_width_height {
				w = absolute_or_relative_size(b.child_box[i].width, b.width)
				h = absolute_or_relative_size(b.child_box[i].height, b.height)
			}
			.right_top_width_height {
				w = -absolute_or_relative_size(b.child_box[i].width, b.width)
				h = absolute_or_relative_size(b.child_box[i].height, b.height)
			}
			.right_bottom_width_height {
				w = -absolute_or_relative_size(b.child_box[i].width, b.width)
				h = -absolute_or_relative_size(b.child_box[i].height, b.height)
			}
			.left_bottom_width_height {
				w = absolute_or_relative_size(b.child_box[i].width, b.width)
				h = -absolute_or_relative_size(b.child_box[i].height, b.height)
			}
			.left_top_right_bottom {
				w = absolute_or_relative_pos(b.child_box[i].x_right, b.width) - absolute_or_relative_size(b.child_box[i].x_left,
					b.width)
				h = absolute_or_relative_pos(b.child_box[i].y_bottom, b.height) - absolute_or_relative_size(b.child_box[i].y_top,
					b.height)
			}
		}
	}
	// println('${child.id}: w,h=(${w}, ${h})')
	child.propose_size(w, h)
}

pub fn (mut b BoxLayout) set_children_pos() {
	// println('size: $b.width, $b.height $w, $h $b.child_box')
	for i, mut child in b.children {
		// println('widget.set_pos($i) $widget.id ${int(start_x + w * b.child_box[i].x)}, ${int(
		// start_y + h * b.child_box[i].y)})')
		// println("size(${int(w * b.child_box[i].width)}, ${int(h * b.child_box[i].height)})")
		b.set_child_pos(i, mut child)
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
	for i, mut child in b.children {
		b.set_child_pos(i, mut child)
		b.set_child_size(i, mut child)
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
	for mut child in b.drawing_children {
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
	scrollview_widget_set_orig_xy(b)
	b.propose_size(width, height)
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
	scrollview_widget_set_orig_xy(b)
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
fn absolute_or_relative_pos(size f32, parent_size int) int {
	return if size < -1.0 && int(size) == size { // negative integer => absolute coordinate from the end
		parent_size + int(size)
	} else if (size > 1.0 && int(size) == size) || size == 0 { // positive integer => absolute coordinate from the start
		int(size) // absolute size
	} else if size >= -1 && size <= 1 { // size inside [-1.0,1.0]\{0}
		new_size := size * parent_size
		if size < 0 { // ]-1.0, 0[ => relative coordinate from the end
			parent_size - int(new_size)
		} else {
			// println('relative size: ${size} ${new_size} -> ${percent} * ${parent_size}) ')
			int(new_size)
		}
	} else if size < -1.0 && int(size) != size {
		int((int(size) - size) * parent_size) + int(size)
	} else { // if size > 1.0 && int(size) != size {
		int((size - int(size)) * parent_size) + int(size)
	}
}

// absolute or relative size with respect to parent size
fn absolute_or_relative_size(size f32, parent_size int) int {
	return if (size < -1.0 || size > 1.0) && int(size) == size { // size outside [-1.0, 1.0]
		int(size) // absolute size
	} else if size >= -1 && size <= 1 { // size inside ]-1.0,1.0[
		new_size := size * parent_size
		// println('relative size: ${size} ${new_size} -> ${percent} * ${parent_size}) ')
		int(new_size)
	} else if size < 0 { // non integer < -1
		int((int(size) - size) * parent_size) // Here relative part always > 0
	} else { // non integer > 1
		int((size - int(size)) * parent_size) // Here relative part always > 0
	}
}

fn box_direction(rect &gg.Rect) BoxMode {
	return if rect.width >= 0 && rect.height >= 0 {
		.left_top_width_height
	} else if rect.width <= 0 && rect.height >= 0 {
		.right_top_width_height
	} else if rect.width <= 0 && rect.height <= 0 {
		.right_bottom_width_height
	} else {
		.left_bottom_width_height
	}
}
