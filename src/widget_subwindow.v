module ui

import eventbus
import gx

pub const (
	sw_decoration    = 20
	sw_resize_border = 4
	sw_z_index       = 10000
	sw_z_index_top   = 1000
	sw_z_index_child = 100
)

[heap]
pub struct SubWindow {
pub mut:
	id                    string
	x                     int
	y                     int
	z_index               int = ui.sw_z_index
	z_index_children_orig []int
	offset_x              int
	offset_y              int
	hidden                bool
	ui                    &UI = unsafe { nil }
	// dragging
	drag         bool
	dragging     bool
	drag_mode    int // 0 = pos, 1 = size
	drag_xy_down [2]int
	drag_ltrb    [4]int
	// decoration
	decoration      bool
	border_dir      [2]int // direction border in x (possible values: -1, 0, 1, 10)
	prev_border_dir [2]int = [10, 10]!
	// main unique layout attached to the subwindow
	layout     Layout = empty_stack
	is_focused bool
	// related to wm
	is_top_wm bool
	parent    Layout = empty_stack
	// component state for composable widget
	component voidptr
}

[params]
pub struct SubWindowParams {
	id         string
	x          int
	y          int
	hidden     bool   = true
	layout     Layout = empty_stack
	drag       bool   = true
	decoration bool   = true
}

pub fn subwindow(c SubWindowParams) &SubWindow {
	mut s := &SubWindow{
		id: c.id
		x: c.x
		y: c.y
		layout: c.layout
		hidden: c.hidden
		drag: c.drag
		decoration: c.decoration
	}
	return s
}

fn (mut s SubWindow) init(parent Layout) {
	s.parent = parent
	pui := parent.get_ui()
	s.ui = pui
	// Subscriber needs here to be before initialization of all its children
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_mouse_down, sw_mouse_down, s)
	subscriber.subscribe_method(events.on_mouse_move, sw_mouse_move, s)
	subscriber.subscribe_method(events.on_mouse_up, sw_mouse_up, s)
	s.ui.window.evt_mngr.add_receiver(s, [events.on_mouse_down])
	// children initialized after so that subcribe_method
	mut l := s.layout
	if mut l is Widget {
		mut w := l as Widget
		w.init(s)
	}

	// z_index of all children
	s.set_children_depth(s.z_index + ui.sw_z_index_child)

	s.set_pos(s.x, s.y)
	s.update_layout()
	s.set_visible(!s.hidden)
}

[manualfree]
pub fn (mut s SubWindow) cleanup() {
	mut subscriber := s.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_mouse_down, s)
	subscriber.unsubscribe_method(events.on_mouse_move, s)
	subscriber.unsubscribe_method(events.on_mouse_up, s)
	mut ui := s.get_ui()
	ui.window.evt_mngr.rm_receiver(s, [events.on_mouse_down])
	unsafe { s.free() }
}

fn (mut s SubWindow) draw() {
	s.draw_device(mut s.ui.dd)
}

fn (mut s SubWindow) draw_device(mut d DrawDevice) {
	if s.hidden {
		return
	}
	offset_start(mut s)
	// possibly add window decoration
	if s.decoration {
		w, _ := s.size()
		$if sw_draw ? {
			println('${s.x}, ${s.y}, ${w}, ${ui.sw_decoration}')
		}
		d.draw_rounded_rect_filled(s.x, s.y, w, ui.sw_decoration, 5, gx.black)
	}
	s.layout.draw()

	offset_end(mut s)
}

[unsafe]
pub fn (s &SubWindow) free() {
	$if free ? {
		print('canvas_layout ${s.id}')
	}
	unsafe {
		s.id.free()
		free(s)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn sw_mouse_down(mut s SubWindow, e &MouseEvent, window &Window) {
	// println("sw_md: $s.id -> ${window.point_inside_receivers(events.on_mouse_down)}")
	if s.hidden {
		return
	}
	if s.point_inside_border(e.x, e.y) {
		println('drag mode 1')
		s.drag_mode = 1
		s.dragging = true
		w, h := s.size()
		s.drag_xy_down[0], s.drag_xy_down[1] = e.x, e.y
		s.drag_ltrb[0], s.drag_ltrb[1] = s.x, s.y
		s.drag_ltrb[2], s.drag_ltrb[3] = s.drag_ltrb[0] + w, s.drag_ltrb[1] + h
	} else if s.decoration && s.point_inside_bar(e.x, e.y) {
		s.drag_mode = 0
		s.as_top_subwindow()
		s.dragging = true
		s.drag_xy_down[0], s.drag_xy_down[1] = e.x, e.y
		s.drag_ltrb[0], s.drag_ltrb[1] = s.x, s.y
	}
}

fn sw_mouse_up(mut s SubWindow, e &MouseEvent, window &Window) {
	if s.hidden {
		return
	}
	s.dragging = false
	s.delegate_pos()
	s.delegate_size()
}

fn sw_mouse_move(mut s SubWindow, e &MouseMoveEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if s.hidden {
		return
	}
	if s.is_top_subwindow() {
		// dragging for change of position or size
		if s.dragging {
			// two modes size or pos
			if s.drag_mode == 1 {
				// println("$s.drag_mode => $s.border_dir")
				mut new_ltrb := s.drag_ltrb
				match s.border_dir[0] {
					-1 { new_ltrb[0] += int(e.x) - s.drag_xy_down[0] }
					// 0 {}
					1 { new_ltrb[2] += int(e.x) - s.drag_xy_down[0] }
					else {}
				}
				match s.border_dir[1] {
					-1 { new_ltrb[1] += int(e.y) - s.drag_xy_down[1] }
					// 0 {}
					1 { new_ltrb[3] += int(e.y) - s.drag_xy_down[1] }
					else {}
				}
				s.set_pos(new_ltrb[0], new_ltrb[1])
				s.propose_size(new_ltrb[2] - new_ltrb[0], new_ltrb[3] - new_ltrb[1])
				s.update_layout()
			} else if s.drag_mode == 0 {
				w, _ := s.size()
				new_x, new_y := s.drag_ltrb[0] + int(e.x) - s.drag_xy_down[0], s.drag_ltrb[1] +
					int(e.y) - s.drag_xy_down[1]
				// println("($new_x, $new_y)")
				if new_x + w - ui.sw_decoration >= 0 && new_y + ui.sw_decoration / 2 >= 0
					&& new_x + ui.sw_decoration <= s.ui.window.width
					&& new_y + ui.sw_decoration / 2 <= s.ui.window.height {
					s.set_pos(new_x, new_y)
					// println("sw $s.id dragging $s.x, $s.y")
					s.update_layout()
					// window.update_layout()
				}
			}
		} else {
			// icon management for border resizement
			if s.point_inside_border(e.x, e.y) {
				if s.prev_border_dir != s.border_dir {
					s.prev_border_dir = s.border_dir
					s.ui.window.mouse.start('_system_:resize_' +
						(if s.border_dir[0] in [-1, 1] { 'ew' } else { 'ns' }))
				}
			} else {
				s.border_dir = [10, 10]!
				if s.prev_border_dir != s.border_dir {
					s.ui.window.mouse.stop_last('_system_:resize_' +
						(if s.prev_border_dir[0] in [-1, 1] { 'ew' } else { 'ns' }))
					s.prev_border_dir = s.border_dir
				}
			}
		}
	}
}

// fn (mut sw SubWindow) mouse_enter(e &MouseMoveEvent) {

// }

// fn (mut sw SubWindow) mouse_leave(e &MouseMoveEvent) {
// 	if sw.is_top_subwindow() {
// 		sw.ui.window.mouse.stop_last('_system_:resize_' +
// 					(if sw.prev_border_dir[0] in [-1,1] { 'ew' } else { 'ns' }))
// 		sw.prev_border_dir = [10, 10]!
// 	}
// }

pub fn (mut s SubWindow) update_layout() {
	s.layout.update_layout()
}

fn (mut s SubWindow) set_adjusted_size(ui &UI) {
}

fn (mut s SubWindow) point_inside_bar(x f64, y f64) bool {
	// add possible decoration
	if s.decoration {
		w, _ := s.size()
		return x > s.x && x < s.x + w && y > s.y && y < s.y + ui.sw_decoration
	} else {
		return false
	}
}

fn (mut s SubWindow) point_inside_border(x f64, y f64) bool {
	w, h := s.size()
	s.border_dir[0] = if x > s.x && x < s.x + ui.sw_resize_border {
		-1
	} else if x > s.x + ui.sw_resize_border && x < s.x + w - ui.sw_resize_border {
		0
	} else if x > s.x + w - ui.sw_resize_border && x < s.x + w {
		1
	} else {
		10
	}
	s.border_dir[1] = if y > s.y && y < s.y + ui.sw_resize_border {
		-1
	} else if y > s.y + ui.sw_resize_border && y < s.y + h - ui.sw_resize_border {
		0
	} else if y > s.y + h - ui.sw_resize_border && y < s.y + h {
		1
	} else {
		10
	}
	return s.border_dir[0] + s.border_dir[1] in [-2, -1, 1, 2]
}

fn (mut s SubWindow) point_inside(x f64, y f64) bool {
	// add possible decoration
	if s.decoration {
		w, h := s.size()
		// println('point_inside $s.id $w, $h')
		return x > s.x && x < s.x + w && y > s.y && y < s.y + h + ui.sw_decoration
	} else {
		if s.layout is Widget {
			mut w := s.layout as Widget
			// println(" ${w.point_inside(x, y)}")
			return w.point_inside(x, y)
		} else {
			return false
		}
	}
}

pub fn (mut s SubWindow) set_pos(x int, y int) {
	s.x = x
	s.y = y
	if s.layout is Widget {
		mut w := s.layout as Widget
		// println("sw set_pos: $s.x, $s.y $s.decoration")
		w.set_pos(x, y + if s.decoration { ui.sw_decoration } else { 0 })
	}
}

pub fn (mut s SubWindow) delegate_pos() {
	if mut s.parent is BoxLayout { // could be done for other Layout???
		// update pos in the parent
		ind := s.parent.cid.index(s.id)
		s.parent.update_child_bounding('${s.parent.child_id[ind]}: (${s.x},${s.y}) ++ (_,_)')
	}
}

pub fn (mut s SubWindow) delegate_size() {
	if mut s.parent is BoxLayout { // could be done for other Layout???
		// update pos in the parent
		ind := s.parent.cid.index(s.id)
		w, h := s.size()
		s.parent.update_child_bounding('${s.parent.child_id[ind]}: (_,_) ++ (${w},${h})')
	}
}

pub fn (mut s SubWindow) propose_size(width int, height int) (int, int) {
	if s.layout is Widget {
		mut ws := s.layout as Widget
		w, mut h := ws.propose_size(width, height)
		if s.decoration {
			h += ui.sw_decoration
		}
		return w, h
	} else {
		return -1, -1
	}
}

pub fn (s SubWindow) size() (int, int) {
	w, mut h := s.layout.size()
	if s.decoration {
		h += ui.sw_decoration
	}
	// println("subw $s.id (layout: $s.layout.id) $w, $h")
	return w, h
}

pub fn (mut s SubWindow) set_visible(state bool) {
	s.hidden = !state
	if s.layout is Widget {
		mut w := s.layout as Widget
		w.set_visible(state)
	}
	if !s.hidden {
		s.ui.window.update_layout()
	}
}

pub fn (s &SubWindow) is_visible() bool {
	return !s.hidden
}

fn (s &SubWindow) get_ui() &UI {
	return s.ui
}

fn (s &SubWindow) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (mut s SubWindow) resize(w int, h int) {
	s.layout.resize(w, h)
	if s.parent is BoxLayout {
		// update the size of parent
	}
}

pub fn (s &SubWindow) get_children() []Widget {
	if s.layout is Widget {
		w := s.layout as Widget
		return [w]
	} else {
		return []
	}
}

fn (mut s SubWindow) set_children_depth(z_inc int) {
	s.layout.incr_children_depth(z_inc)
	s.ui.window.evt_mngr.sorted_receivers(events.on_mouse_down)
}

fn (mut s SubWindow) is_top_subwindow() bool {
	return s.ui.window.subwindows.map(it.id).last() == s.id
}

fn (mut s SubWindow) as_top_subwindow() {
	$if atsw ? {
		println('as top subw ${s.id}')
		Layout(s).debug_show_children_tree(0)
	}
	mut sws := []&SubWindow{}
	for sw in s.ui.window.subwindows {
		if sw.id != s.id {
			sws << sw
		}
	}
	sws << s
	mut win := s.ui.window
	win.subwindows = sws
	// println("atp sws: ${win.subwindows.map(it.id)}")
	for mut sw in sws {
		sw.update_depth(sw.id == s.id)
	}
	$if atsw ? {
		println('atp end')
		Layout(s).debug_show_children_tree(0)
	}
}

fn (mut s SubWindow) update_depth(top bool) {
	// reset first the children
	s.set_children_depth(-s.z_index - ui.sw_z_index_child)
	// inc z_index
	s.z_index = ui.sw_z_index
	if top {
		s.z_index += ui.sw_z_index_top
	}
	// propagate to children
	// println("z_index: ${s.z_index + sw_z_index_child}")
	s.set_children_depth(s.z_index + ui.sw_z_index_child)
	s.update_layout()
}
