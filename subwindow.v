module ui

import eventbus
import gx

const (
	sw_decoration    = 20
	sw_z_index       = 10000
	sw_z_index_top   = 1000
	sw_z_index_child = 100
)

[heap]
pub struct SubWindow {
pub mut:
	id       string
	x        int
	y        int
	z_index  int = ui.sw_z_index
	offset_x int
	offset_y int
	hidden   bool
	ui       &UI = 0
	// dragging
	drag     bool
	dragging bool
	drag_x   int
	drag_y   int
	// decoration
	decoration bool
	// main unique layout attached to the subwindow
	layout     Layout = empty_stack
	is_focused bool
	parent     Layout = empty_stack
	// component state for composable widget
	component voidptr
}

[params]
pub struct SubWindowConfig {
	id         string
	x          int
	y          int
	hidden     bool   = true
	layout     Layout = empty_stack
	drag       bool   = true
	decoration bool   = true
}

pub fn subwindow(c SubWindowConfig) &SubWindow {
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
	if l is Widget {
		mut w := l as Widget
		w.init(s)
	}

	// z_index of all children
	s.set_children_z_index(s.z_index + ui.sw_z_index_child)

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
	if s.hidden {
		return
	}
	offset_start(mut s)
	// possibly add window decoration
	if s.decoration {
		w, _ := s.size()
		s.ui.gg.draw_rounded_rect_filled(s.x, s.y, w, ui.sw_decoration, 5, gx.black)
	}
	s.layout.draw()

	offset_end(mut s)
}

[unsafe]
pub fn (s &SubWindow) free() {
	$if free ? {
		print('canvas_layout $s.id')
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
	if !window.is_top_widget(s, events.on_mouse_down) {
		return
	}
	// println("sw $s.id start dragging")
	if s.decoration && s.point_inside_bar(e.x, e.y) {
		s.as_top_subwindow()
		s.dragging = true
		s.drag_x, s.drag_y = s.x - e.x, s.y - e.y
		// println("drag down: $s.drag_x, $s.drag_y")
	}
}

fn sw_mouse_up(mut s SubWindow, e &MouseEvent, window &Window) {
	if s.hidden {
		return
	}
	s.dragging = false
}

fn sw_mouse_move(mut s SubWindow, e &MouseMoveEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if s.hidden {
		return
	}
	if s.dragging {
		s.set_pos(s.drag_x + int(e.x), s.drag_y + int(e.y))
		// println("sw $s.id dragging $s.x, $s.y")
		s.update_layout()
		// window.update_layout()
	}
}

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

fn (s &SubWindow) get_ui() &UI {
	return s.ui
}

pub fn (s &SubWindow) get_state() voidptr {
	parent := s.parent
	return parent.get_state()
}

fn (s &SubWindow) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (mut s SubWindow) resize(w int, h int) {
	s.layout.resize(w, h)
}

pub fn (s &SubWindow) get_children() []Widget {
	if s.layout is Widget {
		w := s.layout as Widget
		return [w]
	} else {
		return []
	}
}

fn (mut s SubWindow) set_children_z_index(z_inc int) {
	s.layout.update_children_z_index(z_inc)
	s.ui.window.evt_mngr.sorted_receivers(events.on_mouse_down)
}

fn (mut s SubWindow) is_top_subwindow() bool {
	return s.ui.window.subwindows.map(it.id).first() == s.id
}

fn (mut s SubWindow) as_top_subwindow() {
	mut sws := []&SubWindow{}
	for sw in s.ui.window.subwindows {
		if sw.id != s.id {
			sws << sw
		}
	}
	sws << s
	mut win := s.ui.window
	win.subwindows = sws
	// println("sws: ${win.subwindows.map(it.id)}")
	for mut sw in sws {
		sw.update_z_index(sw.id == s.id)
	}
}

fn (mut s SubWindow) update_z_index(top bool) {
	s.set_children_z_index(-s.z_index - ui.sw_z_index_child)
	s.z_index = ui.sw_z_index
	if top {
		s.z_index += ui.sw_z_index_top
	}
	// println("z_index: ${s.z_index + sw_z_index_child}")
	s.set_children_z_index(s.z_index + ui.sw_z_index_child)
	s.update_layout()
}
