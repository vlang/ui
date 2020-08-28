module ui

import eventbus

enum Direction {
	row
	column
}

struct StackConfig {
	width  int
	height int
	vertical_alignment VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing int
	stretch bool
	direction Direction
	margin	MarginConfig
}

struct Stack {
mut:
	x		 int
	y        int
	width    int
	height   int
	children []Widget
	parent   Layout
	ui     &UI
	vertical_alignment VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing int
	stretch bool
	direction Direction
	margin 	MarginConfig
}

fn (mut s Stack) init(parent Layout) {
	s.parent = parent
	ui := parent.get_ui()
	w, h := parent.size()
	s.ui = ui

	if s.stretch {
		s.height = h
		s.width = w
	} else {
		if s.direction == .column {
			s.height = h
		} else {
			s.width = w
		}
	}
	s.height -= s.margin.top + s.margin.bottom
	s.width -= s.margin.left + s.margin.right
	s.set_pos(s.x, s.y)
	for child in s.children {
		child.init(s)
	}
}

fn stack(c StackConfig, children []Widget) &Stack {
	mut s := &Stack{
		height: c.height
		width: c.width
		vertical_alignment: c.vertical_alignment
		horizontal_alignment: c.horizontal_alignment
		spacing: c.spacing
		stretch: c.stretch
		direction: c.direction
		margin: c.margin
		children: children
		ui: 0
	}
	return s
}

fn (mut s Stack) set_pos(x, y int) {
	s.x = x + s.margin.left
	s.y = y + s.margin.top
}

fn (s &Stack) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (mut s Stack) propose_size(w, h int) (int,int) {
	if s.stretch {
		s.width = w
		s.height = h
	}
	return s.width, s.height
}

fn (c &Stack) size() (int, int) {
	return c.width, c.height
}

fn (mut s Stack) draw() {
	mut per_child_size := s.get_oriented_height()
	mut pos := s.get_oriented_y_axis()
	mut size := 0
	for child in s.children {
		mut w := 0
		mut h := 0
		if s.direction == .column {
			w, h = child.propose_size(s.width, per_child_size)
			child.set_pos(s.align(w), pos)
		} else {
			h, w = child.propose_size(per_child_size, s.height)
			child.set_pos(pos, s.align(w))
		}
		if w > size {size = w}
		child.draw()
		pos += h + s.spacing
		per_child_size -= h + s.spacing
	}
	if s.stretch {return}
	s.set_oriented_height(pos - s.get_oriented_y_axis())
	w := s.get_oriented_width()
	if w == 0 || w < size {
		s.set_oriented_width(size)
	}
}
fn (s &Stack) align(size int) int {
	align := if s.direction == .column { int(s.horizontal_alignment) } else { int(s.vertical_alignment) }
	match align {
		0 {
			return s.get_oriented_x_axis()
		}
		1 {
			return s.get_oriented_x_axis() + ((s.get_oriented_width() - size) / 2)
		}
		2 {
			return (s.get_oriented_x_axis() + s.get_oriented_width()) - size
		}
		else {return s.get_oriented_x_axis()}
	}
}

fn (s &Stack) get_ui() &UI {
	return s.ui
}

fn (s &Stack) unfocus_all() {
	for child in s.children {
		child.unfocus()
	}
}

fn (s &Stack) get_state() voidptr {
	parent := s.parent
	return parent.get_state()
}

fn (s &Stack) point_inside(x, y f64) bool {
	return false // x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height
}

fn (mut s Stack) focus() {
	// s.is_focused = true
	//println('')
}

fn (mut s Stack) unfocus() {
	// s.is_focused = false
	//println('')
}

fn (s &Stack) is_focused() bool {
	return false // s.is_focused
}

fn (s &Stack) resize(width, height int) {
}

/* Helpers to correctly get height, width, x, y for both row & column
   Column & Row are identical except everything is reversed.
   Row is treated like a column turned by 90 degrees, so these methods
   get/set reverse values for row.
   Width  -> Height
   Height -> Width
   X -> Y
   Y -> X
 */
fn (s &Stack) get_oriented_height() int {
	return if s.direction == .column {s.height} else {s.width}
}
fn (s &Stack) get_oriented_width() int {
	return if s.direction == .column {s.width} else {s.height}
}
fn (s &Stack) get_oriented_y_axis() int {
	return if s.direction == .column {s.y} else {s.x}
}
fn (s &Stack) get_oriented_x_axis() int {
	return if s.direction == .column {s.x} else {s.y}
}
fn (mut s Stack) set_oriented_height(h int) int {
	if s.direction == .column {s.height = h} else {s.width = h}
	return h
}
fn (mut s Stack) set_oriented_width(w int) int {
	if s.direction == .column {s.width = w} else {s.height = w}
	return w
}
