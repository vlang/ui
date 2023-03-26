module ui

// import gx
import gg
import eventbus
import regex

const (
	null_rect = gg.Rect{0.0, 0.0, 0.0, 0.0}
)

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

// IMPORTANT: 1) No margins since users can add relative or absolute ones manually
// 2) The box_layout <id> is RELATIVE to its own box_layout so this id is independent of the id of the widget

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
	id          string
	height      int
	width       int
	adj_height  int
	adj_width   int
	x           int
	y           int
	offset_x    int
	offset_y    int
	z_index     int
	deactivated bool
	is_focused  bool
	parent      Layout = empty_stack
	ui          &UI    = unsafe { nil }
	// children
	child_box        []Box
	child_box_expr   map[string]string // for box_expression mode, i.e. specifically when some @id are used inside bounding expression
	child_id         []string // relative id
	cid              []string // real child id defined inside its own constructor
	child_mode       []BoxMode
	children         []Widget
	drawing_children []Widget
	hidden           bool
	clipping         bool
	is_root_layout   bool = true
	// scrollview
	has_scrollview   bool
	scrollview       &ScrollView = unsafe { nil }
	on_scroll_change ScrollViewChangedFn = ScrollViewChangedFn(0)
	// component state for composable widget
	component voidptr
	// debug stuff to be removed
	debug_ids []string
}

[params]
pub struct BoxLayoutParams {
pub mut:
	id         string
	x          int
	y          int
	width      int
	height     int
	clipping   bool = true
	scrollview bool
	children   map[string]Widget
}

// TODO: documentation
pub fn box_layout(c BoxLayoutParams) &BoxLayout {
	mut b := &BoxLayout{
		id: c.id
		x: c.x
		y: c.y
		width: c.width
		height: c.height
		clipping: c.clipping
		ui: 0
	}
	for key, child in c.children {
		mut child_mut := child
		b.set_child_bounding(key, mut child_mut)
	}
	if c.scrollview {
		scrollview_add(mut b)
	}
	return b
}

// TODO: documentation
pub fn (mut b BoxLayout) init(parent Layout) {
	b.parent = parent
	mut ui := parent.get_ui()
	b.ui = ui
	for _, mut child in b.children {
		// DON'T DO THAT: child.id = b.child_id[i]
		// println('$i) gl init child ${child.id} ')
		child.init(b)
		// unsafe{println('$i) end init ${b.child_box[i]}')}
	}
	b.decode_size()
	b.set_children_pos_and_size()
	b.set_adjusted_size(b.ui)
	b.set_root_layout()
	if has_scrollview(b) {
		b.scrollview.init(parent)
		b.ui.window.evt_mngr.add_receiver(b, [events.on_scroll])
	} else {
		scrollview_delegate_parent_scrollview(mut b)
	}
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

// TODO: documentation
[manualfree]
pub fn (mut b BoxLayout) cleanup() {
	for mut child in b.children {
		child.cleanup()
	}
	unsafe {
		b.free()
	}
}

// TODO: documentation
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

pub fn (mut b BoxLayout) set_child_bounding(key string, mut child Widget) {
	id, mut bounding := parse_boxlayout_child_key(key, b.id)
	// Non-sense here no underscore when setting a child bounding box
	// bounding = b.update_child_current_box_expression(id, bounding)
	mode, bounding_vec, has_z_index, z_index, box_expr := parse_boxlayout_child_bounding(bounding)
	match mode {
		'rect' { b.add_child_rect(id, child, bounding_vec) }
		'lt2rb' { b.add_child_lt2rb(id, child, bounding_vec) }
		'box_expr' { b.add_child_box_expr(id, child, box_expr) }
		else {}
	}
	if has_z_index {
		child.set_depth(z_index)
	}
	b.update_visible_children()
}

fn (mut b BoxLayout) add_child_lt2rb(id string, child Widget, vec4 []f32) {
	lt2rb := if vec4.len == 4 {
		LeftTopToRightBottom{vec4[0], vec4[1], vec4[2], vec4[3]}
	} else {
		LeftTopToRightBottom{0.0, 0.0, 0.0, 0.0}
	}
	// println(lt2rb)
	b.child_id << id
	b.cid << child.id
	b.child_box << Box{
		LeftTopToRightBottom: lt2rb
	}
	b.child_mode << BoxMode.left_top_right_bottom
	b.children << child
}

fn (mut b BoxLayout) add_child_rect(id string, child Widget, vec4 []f32) {
	rect := if vec4.len == 4 {
		gg.Rect{vec4[0], vec4[1], vec4[2], vec4[3]}
	} else {
		gg.Rect{0.0, 0.0, 0.0, 0.0}
	}
	b.child_id << id
	b.cid << child.id
	b.child_box << Box{
		Rect: rect
	}
	b.child_mode << box_direction(rect) // BoxMode.left_top_width_height
	b.children << child
}

fn (mut b BoxLayout) add_child_box_expr(id string, child Widget, box_expr string) {
	b.child_id << id
	b.cid << child.id
	b.child_box_expr[id] = box_expr
	b.child_mode << if box_expr.contains('++') {
		.left_top_width_height
	} else {
		.left_top_right_bottom
	}
	b.child_box << Box{
		Rect: gg.Rect{0.001, 0.0, 0.0, 0.0}
	}
	// println("add_child_box_expr: $id ${b.child_box_expr[id]} ${(b.child_mode)[b.child_mode.len-1]}")
	b.children << child
}

pub fn (mut b BoxLayout) update_child_bounding(key string) {
	id, mut bounding := parse_boxlayout_child_key(key, b.id)
	bounding = b.update_child_current_box_expression(id, bounding)
	mode, bounding_vec, has_z_index, z_index, box_expr := parse_boxlayout_child_bounding(bounding)
	match mode {
		'rect' { b.update_child_rect(id, bounding_vec) }
		'lt2rb' { b.update_child_lt2rb(id, bounding_vec) }
		'box_expr' { b.update_child_box_expr(id, box_expr) }
		else {}
	}
	if has_z_index {
		b.update_child_depth(id, z_index)
	}
}

// TODO: documentation
pub fn (mut b BoxLayout) update_boundings(keys ...string) {
	for key in keys {
		b.update_child_bounding(key)
	}
	b.update_visible_children()
	b.update_layout()
}

// TODO: IMPORTANT check if it was before a box_expression to remove inside b.child_box_expr
fn (mut b BoxLayout) update_child_lt2rb(id string, vec4 []f32) {
	lt2rb := if vec4.len == 4 {
		LeftTopToRightBottom{vec4[0], vec4[1], vec4[2], vec4[3]}
	} else {
		LeftTopToRightBottom{0.0, 0.0, 0.0, 0.0}
	}
	ind := b.child_id.index(id)
	if ind < 0 {
		return
	}
	b.child_box[ind] = Box{
		LeftTopToRightBottom: lt2rb
	}
	b.child_mode[ind] = BoxMode.left_top_right_bottom
}

// TODO: IMPORTANT check if it was before a box_expression to remove inside b.child_box_expr
fn (mut b BoxLayout) update_child_rect(id string, vec4 []f32) {
	rect := if vec4.len == 4 {
		gg.Rect{vec4[0], vec4[1], vec4[2], vec4[3]}
	} else {
		gg.Rect{0.0, 0.0, 0.0, 0.0}
	}
	ind := b.child_id.index(id)
	if ind < 0 {
		return
	}
	b.child_box[ind] = Box{
		Rect: rect
	}
	b.child_mode[ind] = box_direction(rect)
}

fn (mut b BoxLayout) update_child_box_expr(id string, box_expr string) {
	ind := b.child_id.index(id)
	if ind < 0 {
		return
	}
	b.child_box_expr[id] = box_expr
}

fn (mut b BoxLayout) update_child_depth(id string, z_index int) {
	ind := b.child_id.index(id)
	if ind < 0 {
		return
	}
	b.children[ind].set_depth(z_index)
}

// TODO: documentation
pub fn (mut b BoxLayout) update_child(id string, mut child Widget) {
	ind := b.child_id.index(id)
	if ind < 0 {
		return
	}
	child_id := b.children[ind].id
	b.children[ind].cleanup()
	b.children[ind] = child
	child.init(b)
	b.register_child(child)
	child.id = child_id
	b.update_layout()
}

pub fn (mut b BoxLayout) update_visible_children() {
	for i, mut child in b.children {
		child.hidden = b.child_box[i].is_null()
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

// TODO: documentation
pub fn (b &BoxLayout) set_child_pos(i int, mut child Widget) {
	mut x, mut y := 0, 0
	unsafe {
		// println("bl.set_child_pos $i ${b.child_mode[i]} ${b.child_box}")
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
	// println('${child.id}: x,y =(${x}, ${y})')
	if mut child is AdjustableWidget {
		mut w := child as AdjustableWidget
		// println('$child.id: $x + $offset_x, $y + $offset_y')
		w.set_adjusted_pos(x, y)
	} else {
		child.set_pos(x, y)
	}
}

// TODO: documentation
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
	// println('${child.id}: w,h=(${w}, ${h}) (${b.width}, ${b.height})')
	child.propose_size(w, h)
}

fn (b BoxLayout) ids_repl(re regex.RE, in_txt string, start int, end int) string {
	id := re.get_group_by_id(in_txt, 0)
	field := re.get_group_by_id(in_txt, 1)
	ind := b.child_id.index(id)
	if ind >= 0 {
		box := b.child_box[ind]
		val := unsafe {
			match field {
				'xl' { box.x_left }
				'xr' { box.x_right }
				'yt' { box.y_top }
				'yb' { box.y_bottom }
				'x' { box.x }
				'y' { box.y }
				'w' { box.width }
				'h' { box.height }
				'xw' { box.x + box.width }
				'yh' { box.y + box.height }
				else { 0.0 }
			}
		}
		return val.str()
	}
	return in_txt
}

fn (mut b BoxLayout) preprocess_child_box_expression(i int, id string) {
	// TODO: extract first the @id, replace by unsafe value in the expression
	// the new bounding string is then evaluated to generate b.child_box[i]
	// temporary modify b.child_mode[i] to the evaluated mode
	// call again set_child_pos with the
	// restore b.child_mode[i] to .box_expression
	// and return

	if id in b.child_box_expr {
		mut bounding := b.child_box_expr[id]
		// extract @id
		query := r'@(\w+)\.(\w+)'

		mut re := regex.regex_opt(query) or { panic(err) }
		// println("before: $bounding")
		bounding = re.replace_by_fn(bounding, b.ids_repl)
		// precompute formulae
		bounding = b.precompute_box_expression(bounding)
		// println("precompute:  $bounding")
		// set the child_box[i] and child_mode[i] (already done normally)
		mode, bounding_vec, _, _, _ := parse_boxlayout_child_bounding(bounding)
		// println("preprocess $id $bounding_vec")
		match mode {
			'rect' { b.update_child_rect(id, bounding_vec) }
			'lt2rb' { b.update_child_lt2rb(id, bounding_vec) }
			else {}
		}
	}
}

fn (b &BoxLayout) precompute_box_expression(bounding string) string {
	mut res, mut bbs := bounding.trim_space(), []string{}
	mut op := ''
	if res.contains('++') {
		op = '++'
	} else {
		op = '->'
	}
	mut tmp := res.split(op).map(it.trim_space()#[1..-1])
	for i in 0 .. 2 {
		if tmp[i].contains_any('+-*/()') {
			bbs = tmp[i].split(',').map(it.trim_space())
			tmp[i] = '${b.calculate(bbs[i * 2])}, ${b.calculate(bbs[i * 2 + 1])}'
		}
	}
	return '(${tmp[0]}) ${op} (${tmp[1]})'
}

fn (b &BoxLayout) calculate(formula string) f32 {
	return b.ui.window.calculate(formula)
}

// TODO: documentation
pub fn (mut b BoxLayout) set_children_pos() {
	// println('size: $b.width, $b.height $w, $h $b.child_box')
	for i, mut child in b.children {
		// println('widget.set_pos($i) $widget.id ${int(start_x + w * b.child_box[i].x)}, ${int(
		// start_y + h * b.child_box[i].y)})')
		// println("size(${int(w * b.child_box[i].width)}, ${int(h * b.child_box[i].height)})")
		b.preprocess_child_box_expression(i, b.child_id[i])
		b.set_child_pos(i, mut child)
		if mut child is Stack {
			child.update_layout()
		} else if mut child is SubWindow {
			child.update_layout()
		}
	}
}

fn (mut b BoxLayout) set_children_pos_and_size() {
	$if bl_scps ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('boxlayout scps ${b.id} size: (${b.width}, ${b.height})')
		}
	}
	for i, mut child in b.children {
		b.preprocess_child_box_expression(i, b.child_id[i])
		b.set_child_pos(i, mut child)
		b.set_child_size(i, mut child)
	}
	$if bl_scps ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('boxlayout scps ${b.id} size: (${b.width}, ${b.height})')
		}
	}
}

fn (mut b BoxLayout) draw() {
	b.draw_device(mut b.ui.dd)
}

fn (mut b BoxLayout) draw_device(mut d DrawDevice) {
	offset_start(mut b)
	defer {
		offset_end(mut b)
	}
	cstate := clipping_start(b, mut d) or { return }
	defer {
		clipping_end(b, mut d, cstate)
	}
	scrollview_draw_begin(mut b, d)
	defer {
		scrollview_draw_end(b, d)
	}
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
	// scrollview_set_children_orig_xy(b, false)
	b.propose_size(width, height)
	scrollview_set_children_orig_xy(b, false)
	for mut child in b.children {
		if mut child is Layout {
			child.update_layout()
		} else if mut child is SubWindow {
			child.update_layout()
		}
	}
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
	scrollview_update(b)
	return b.width, b.height
}

fn (b &BoxLayout) size() (int, int) {
	return b.width, b.height
}

// TODO: documentation
pub fn (mut b BoxLayout) set_adjusted_size(gui &UI) {
	$if b_adj_size ? {
		b.debug_ids = env('UI_IDS').split(',').clone()
		b.debug_children_ids = []
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('bl set_adj ${b.id}')
		}
	}
	mut w, mut h := 0, 0
	$if b_adj_size ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('bll ${b.id} children: ${b.children.map(it.id)}')
		}
	}
	for mut child in b.children {
		$if b_adj_size ? {
			if b.debug_ids.len == 0 || b.id in b.debug_ids {
				println('bl child ${child.id} ${child.z_index} > ${z_index_hidden}')
			}
		}
		if child.z_index > z_index_hidden { // taking into account only visible widgets
			child_width, child_height := child.size()

			if child.x + child_width > w {
				w = child.x + child_width
			}
			if child.y + child_height > h {
				h = child.y + child_height
			}
			$if b_adj_size ? {
				if b.debug_ids.len == 0 || b.id in b.debug_ids {
					println('bl size child ${child.id} ${child.type_name()} -> (${child.x} + ${child_width}, ${child.y} + ${child_height}) -> (${w}, ${h})')
				}
			}
		}
	}
	$if b_adj_size ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('bl set_adj before: ${b.id} -> (${w}, ${h})')
		}
	}
	if b.width > w {
		w = b.width
	}
	if b.height > h {
		h = b.height
	}
	$if b_adj_size ? {
		if b.debug_ids.len == 0 || b.id in b.debug_ids {
			println('bl set_adj after: ${b.id} -> (${w}, ${h})')
		}
	}
	b.adj_width = w
	b.adj_height = h
}

fn (b &BoxLayout) adj_size() (int, int) {
	return b.adj_width, b.adj_height
}

fn (b &BoxLayout) get_children() []Widget {
	return b.children
}

// TODO: documentation
pub fn (mut b BoxLayout) update_layout() {
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
		} else if mut child is CanvasLayout {
			child.update_layout()
		} else if mut child is BoxLayout {
			child.update_layout()
		} else if mut child is SubWindow {
			child.update_layout()
		}
	}
	b.set_adjusted_size(b.ui)
	scrollview_update(b)
	b.set_drawing_children()
	scrollview_set_children_orig_xy(b, true)
}

fn (mut b BoxLayout) set_drawing_children() {
	// println("fdfbfd: ${b.children.map(it.id)}")
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
	b.drawing_children = b.drawing_children.filter(!b.is_box_hidden(it.id))
	b.sorted_drawing_children()
}

pub fn (b &BoxLayout) is_box_hidden(id string) bool {
	ind := b.cid.index(id)
	// println('is_box_hidden: ${b.id}  ${id} -> ${ind}')
	if ind < 0 {
		return false
	}
	box := b.child_box[ind]
	return box.is_null()
}

pub fn (mut b BoxLayout) register_child(child Widget) {
	mut window := b.ui.window
	window.register_child(child)
}

// deal with underscore '_' syntax to update a box expression
fn (mut b BoxLayout) update_child_current_box_expression(id string, bounding string) string {
	if !bounding.contains('_') {
		return bounding
	}
	mut tmp, mut vec := []string{}, []string{}
	mut res := bounding
	ind := b.child_id.index(id)
	if ind < 0 {
		return bounding // unmodified
	}
	box := b.child_box[ind]
	if bounding.contains('++') {
		tmp = bounding.split('++').map(it.trim_space())
		tmp[0] = tmp[0].find_between('(', ')')
		vec = tmp[0].split(',').map(it.trim_space())
		if vec.len == 2 { // z_index (vec.len == 3) has no need to be preserved since it is the default behavior
			if vec[0] == '_' {
				vec[0] = unsafe { box.x.str() }
			}
			if vec[1] == '_' {
				vec[1] = unsafe { box.y.str() }
			}
		}
		tmp[1] = tmp[1].find_between('(', ')')
		vec << tmp[1].split(',').map(it.trim_space())
		if vec.len == 4 {
			if vec[2] == '_' {
				match b.child_mode[ind] {
					.left_top_width_height { vec[2] = unsafe { box.width.str() } }
					.left_top_right_bottom { vec[2] = unsafe { (box.x_right - box.x_left).str() } }
					else {}
				}
			}
			if vec[3] == '_' {
				match b.child_mode[ind] {
					.left_top_width_height { vec[3] = unsafe { box.height.str() } }
					.left_top_right_bottom { vec[3] = unsafe { (box.y_bottom - box.y_top).str() } }
					else {}
				}
			}
			res = '(${vec[0]},${vec[1]}) ++ (${vec[2]},${vec[3]})'
		}
	} else if bounding.contains('->') {
		tmp = bounding.split('->').map(it.trim_space())
		tmp[0] = tmp[0].find_between('(', ')')
		vec = tmp[0].split(',').map(it.trim_space())
		println(vec)
		if vec.len == 2 { // z_index (vec.len == 3) has no need to be preserved since it is the default behavior
			if vec[0] == '_' {
				vec[0] = unsafe { box.x_left.str() }
			}
			if vec[1] == '_' {
				vec[1] = unsafe { box.y_top.str() }
			}
		}
		tmp[1] = tmp[1].find_between('(', ')')
		vec << tmp[1].split(',').map(it.trim_space())
		if vec.len == 4 {
			if vec[2] == '_' {
				match b.child_mode[ind] {
					.left_top_width_height { vec[2] = unsafe { (box.x + box.width).str() } }
					.left_top_right_bottom { vec[2] = unsafe { box.x_right.str() } }
					else {}
				}
			}
			if vec[3] == '_' {
				match b.child_mode[ind] {
					.left_top_width_height { vec[3] = unsafe { (box.y + box.height).str() } }
					.left_top_right_bottom { vec[3] = unsafe { box.y_bottom.str() } }
					else {}
				}
			}
			res = '(${vec[0]},${vec[1]}) -> (${vec[2]},${vec[3]})'
		}
	}
	return res
}

// parse child key and return id and bounding spec
fn parse_boxlayout_child_key(key string, bl_id string) (string, string) {
	tmp := key.split_any(':')
	return if tmp.len > 1 {
		tmp[0].trim_space(), tmp[1].trim_space()
	} else {
		bl_id + '/' + key, tmp[0]
	}
}

// parse child bounding and return
fn parse_boxlayout_child_bounding(bounding string) (string, []f32, bool, int, string) {
	mut vec4, mut mode, mut has_z_index, mut z_index, mut box_expr := []f32{}, '', false, 0, ''
	mut tmp2 := []string{}
	if bounding == 'hidden' {
		vec4 = [f32(0), 0, 0, 0] // hidden in drawing_children
		mode = 'rect'
	} else if bounding == 'stretch' {
		vec4 = [f32(0), 0, 1, 1] // stretch means full size
		mode = 'rect'
	} else if bounding.contains('@') { // pos or width from other and possibly current elements
		box_expr = bounding
		mode = 'box_expr'
	} else if bounding.contains('++') {
		tmp2 = bounding.split('++').map(it.trim_space())
		vec4, has_z_index, z_index = parse_bounding_with_possible_zindex(tmp2[0], tmp2[1])
		if vec4.len == 4 {
			mode = 'rect'
		}
	} else if bounding.contains('->') {
		tmp2 = bounding.split('->').map(it.trim_space())
		vec4, has_z_index, z_index = parse_bounding_with_possible_zindex(tmp2[0], tmp2[1])
		if vec4.len == 4 {
			mode = 'lt2rb'
		}
	}
	return mode, vec4, has_z_index, z_index, box_expr
}

// TODO: ?int does not work yet
fn parse_bounding_with_possible_zindex(left string, right string) ([]f32, bool, int) {
	mut has_z_index, mut z_index := false, 0
	mut tmp := left.find_between('(', ')')
	mut vec4 := []f32{}
	if !left.is_blank() {
		vec4 = tmp.split(',').map(it.f32())
		if vec4.len == 3 {
			has_z_index = true
			z_index = int(vec4[2])
			vec4 = vec4[0..2]
		}
		tmp2 := right.find_between('(', ')')
		vec4 << tmp2.split(',').map(it.f32())
		if vec4.len != 4 {
			return []f32{}, false, 0
		}
	}
	return vec4, has_z_index, z_index
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

pub fn (box Box) is_null() bool {
	return unsafe { box.x == 0 && box.y == 0 && box.width == 0 && box.height == 0 }
}
