module ui

import eventbus

[heap]
pub struct SubWindow {
pub mut:
	id         string
	x          int
	y          int
	z_index    int
	offset_x   int
	offset_y   int
	hidden     bool   = true
	layout     Layout = empty_stack
	is_focused bool
	// component state for composable widget
	component voidptr
mut:
	parent Layout = empty_stack
}

pub struct SubWindowConfig {
	id      string
	x       int
	y       int
	z_index int
	layout  Layout = empty_stack
}

pub fn subwindow(c SubWindowConfig) &SubWindow {
	mut s := &SubWindow{
		id: c.id
		x: c.x
		y: c.y
		z_index: c.z_index
		layout: c.layout
	}
	return s
}

fn (mut s SubWindow) init(parent Layout) {
	s.parent = parent
	mut l := s.layout
	if l is Widget {
		mut w := l as Widget
		w.init(s)
	}
	if mut l is Stack {
		l.update_layout()
	}
}

[manualfree]
pub fn (mut s SubWindow) cleanup() {
	unsafe { s.free() }
}

fn (mut s SubWindow) draw() {
	if s.hidden {
		return
	}
	offset_start(mut s)
	// possibly add window decoration
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

pub fn (mut s SubWindow) update_layout() {
	// s.layout.update_layout()
}

fn (mut s SubWindow) set_adjusted_size(ui &UI) {
}

fn (s &SubWindow) point_inside(x f64, y f64) bool {
	// add possible decoration
	if s.layout is Widget {
		mut w := s.layout as Widget
		return w.point_inside(x, y)
	} else {
		return false
	}
}

pub fn (mut s SubWindow) set_pos(x int, y int) {
	s.x = x
	s.y = y
}

pub fn (mut s SubWindow) propose_size(width int, height int) (int, int) {
	if s.layout is Widget {
		mut w := s.layout as Widget
		return w.propose_size(width, height)
	} else {
		return -1, -1
	}
}

pub fn (mut s SubWindow) size() (int, int) {
	return s.layout.size()
}

pub fn (mut s SubWindow) set_visible(state bool) {
	s.hidden = !state
	if s.layout is Widget {
		mut w := s.layout as Widget
		w.set_visible(state)
	}
}

fn (s &SubWindow) get_ui() &UI {
	return s.parent.get_ui()
}

pub fn (s &SubWindow) get_state() voidptr {
	parent := s.parent
	return parent.get_state()
}

fn (s &SubWindow) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (s &SubWindow) resize(width int, height int) {
	s.layout.resize(width, height)
}

pub fn (s &SubWindow) get_children() []Widget {
	if s.layout is Widget {
		w := s.layout as Widget
		return [w]
	} else {
		return []
	}
}
