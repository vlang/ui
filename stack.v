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
	mut ui := parent.get_ui()
	parent_width, parent_height := parent.size()
	s.ui = ui
	if s.stretch {
		s.height = parent_height
		s.width = parent_width
	} else {
		if s.direction == .column {
			s.height = parent_height
		} else {
			s.width = parent_width
		}
	}
	s.height -= s.margin.top + s.margin.bottom
	s.width -= s.margin.left + s.margin.right
	s.set_pos(s.x, ui.y_offset + s.y)
	// Init all children recursively
	for mut child in s.children {
		child.init(s)
	}
	// Set all children's positions recursively
	s.set_children_pos()
	for mut child in s.children {
		if child is Stack {
			child.set_children_pos()
		}
	}
}

fn (mut s Stack) set_children_pos() {
	mut ui := s.parent.get_ui()
	_, parent_height := s.parent.size()
	mut x := s.x
	mut y := s.y
	for mut child in s.children {
		child_width, child_height := child.size()
		ui.y_offset = y
		if s.vertical_alignment == .bottom {
			child.set_pos(x, parent_height - s.height)
		} else {
			child.set_pos(x, y)
		}
		if s.direction == .row {
			width := s.width / s.children.len
			child.propose_size(width - s.spacing / 2, s.height)
			x += child_width + s.spacing
		} else {
			y += child_height + s.spacing
		}
		if child is Stack {
			child.set_children_pos()
		}
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
