// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import eventbus

enum Direction {
	row
	column
}

struct StackConfig {
	width                int
	height               int
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing              int
	stretch              bool
	direction            Direction
	margin               MarginConfig
}

struct Stack {
mut:
	x                    int
	y                    int
	width                int
	height               int
	children             []Widget
	parent               Layout
	ui                   &UI
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing              int
	stretch              bool
	direction            Direction
	margin               MarginConfig
}

/*
Column & Row are identical except everything is reversed:
   Row is treated like a column turned by 90 degrees, so values for row are reversed.
   Width  -> Height
   Height -> Width
   X -> Y
   Y -> X
*/
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
	mut x := s.x
	mut y := s.y
	// println('\nstack children')
	for child in s.children {
		child.init(s)
		child_width, child_height := child.size()
		// Set correct position for each child
		mut yy := y
		if s.vertical_alignment == .bottom {
			_, parent_height := s.parent.size()
			yy = parent_height - s.height
		}
		if s.direction == .row {
			x += s.spacing
		} else {
			y += s.spacing
		}
		// println('setting widget pos $x, $yy $s.margin')
		// if child is TextBox {
		// println('txtbox $child.placeholder')
		//}
		child.set_pos(x, yy)
		if s.direction == .row {
			x += child_width
		} else {
			y += child_height
		}
	}
	// println('\n')
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

fn (mut s Stack) set_pos(x int, y int) {
	s.x = x + s.margin.left
	s.y = y + s.margin.top
}

fn (s &Stack) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (mut s Stack) propose_size(w int, h int) (int, int) {
	if s.stretch {
		s.width = w
		if s.height == 0 {
			s.height = h
		}
	}
	return s.width, s.height
}

fn (c &Stack) size() (int, int) {
	return c.width, c.height
}

fn (mut s Stack) draw() {
	// child_len := s.children.len
	// total_spacing := (child_len - 1) * s.spacing
	mut pos_y := s.y
	if s.vertical_alignment == .bottom {
		// Move the stack to the bottom. First find the biggest height.
		_, parent_height := s.parent.size()
		// println('parent_height=$parent_height s.height= $s.height')
		pos_y = parent_height - s.height
	}
	// s.ui.gg.draw_empty_rect(0, pos_y, 500, 30, gx.red) // for debugging
	for child in s.children {
		child.draw()
	}
	/*
	per_child_height := if child_len > 0 {
 (s.get_oriented_height() - total_spacing) / child_len } else { 0 }
	mut pos_y := s.get_oriented_y_axis()
	if s.vertical_alignment == .bottom {
		// Move the stack to the bottom. First find the biggest height.
		_, parent_height := s.parent.size()
	println('parent_height=$parent_height xxx $s.height')
		pos_y = parent_height - s.height
	}
	mut size_x := 0

	for child in s.children {
		mut w := 0
		mut h := 0
		if s.direction == .column || s.vertical_alignment == .bottom {
			w, h = child.propose_size(s.width, per_child_height)
			child.set_pos(s.align(w), pos_y)
		} else  {//if s.direction == .row {
			h, w = child.propose_size(per_child_height, s.height)
			child.set_pos(pos_y, s.align(w))
		}
		if w > size_x {
			size_x = w
		}
		child.draw()
		pos_y += h + s.spacing
	}
	if s.stretch {
		return
	}
	pos_y -= s.spacing
	if s.height == 0 {
	//s.set_oriented_height(pos_y - s.get_oriented_y_axis())
	}
	w := s.get_oriented_width()
	if w == 0 || w < size_x {
		s.set_oriented_width(size_x)
	}
	*/
}

fn (s &Stack) align(size int) int {
	align := if s.direction == .column {
		int(s.horizontal_alignment)
	} else {
		int(s.vertical_alignment)
	}
	match align {
		0 { return s.get_oriented_x_axis() }
		1 { return s.get_oriented_x_axis() + ((s.get_oriented_width() - size) / 2) }
		2 { return (s.get_oriented_x_axis() + s.get_oriented_width()) - size }
		else { return s.get_oriented_x_axis() }
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

fn (s &Stack) point_inside(x f64, y f64) bool {
	return false // x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height
}

fn (mut s Stack) focus() {
	// s.is_focused = true
	// println('')
}

fn (mut s Stack) unfocus() {
	s.unfocus_all()
	// s.is_focused = false
	// println('')
}

fn (s &Stack) is_focused() bool {
	return false // s.is_focused
}

fn (s &Stack) resize(width int, height int) {
}

// Helpers to correctly get width, height, x, y for both row & column.
fn (s &Stack) get_oriented_height() int {
	return if s.direction == .column {
		s.height
	} else {
		s.width
	}
}

fn (s &Stack) get_oriented_width() int {
	return if s.direction == .column {
		s.width
	} else {
		s.height
	}
}

fn (s &Stack) get_oriented_y_axis() int {
	return if s.direction == .column {
		s.y
	} else {
		s.x
	}
}

fn (s &Stack) get_oriented_x_axis() int {
	return if s.direction == .column {
		s.x
	} else {
		s.y
	}
}

fn (mut s Stack) set_oriented_height(h int) int {
	if s.direction == .column {
		if s.height == 0 {
			s.height = h
		}
	} else {
		s.width = h
	}
	return h
}

fn (mut s Stack) set_oriented_width(w int) int {
	if s.direction == .column {
		s.width = w
	} else {
		if s.height == 0 {
			s.height = w
		}
	}
	return w
}
