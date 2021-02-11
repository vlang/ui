// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import eventbus

enum Direction {
	row
	column
}

/*
Column & Row are identical except everything is reversed:
   Row is treated like a column turned by 90 degrees, so values for row are reversed.
   Width  -> Height
   Height -> Width
   X -> Y
   Y -> X
*/

/********** different size's definitions ************
* container_size is simply: (width, height)
* adjusted_size is (adj_width, adj_height) corresponding of the compact/fitted size inherited from children sizes
* size() returns full_size, i.e. container_size + margin_size 
* total_spacing() returns spacing
* free_size() returns free_size_direct and free_size_opposite (in the proper order) where:
	* free_size_direct = container_size - total_spacing()
	* free_size_opposite = container_size

N.B.:
	* direct size is the size in the main direction of the stack: height for .column and width  for .row
	* opposite size is the converse
	* no needs of functions: container_size() and adjusted_size()
***********************************/

struct StackConfig {
	width                f32 // No more int to offer relative size
	height               f32
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing              int
	stretch              bool
	direction            Direction
	margin               MarginConfig
	// children related
	widths                []f32 // children sizes
	heights               []f32
	vertical_alignments   VerticalAlignments
	horizontal_alignments HorizontalAlignments
}

struct Stack {
mut:
	x                     int
	y                     int
	width                 int
	height                int
	widths                []f32 // children sizes
	heights               []f32
	children              []Widget
	parent                Layout
	root                  &Window = voidptr(0)
	ui                    &UI
	vertical_alignment    VerticalAlignment
	horizontal_alignment  HorizontalAlignment
	vertical_alignments   VerticalAlignments // Flexible alignments by index overriding alignment.
	horizontal_alignments HorizontalAlignments
	spacing               int
	stretch               bool
	direction             Direction
	margin                Margin
	adj_width             int
	adj_height            int
}

fn stack(c StackConfig, children []Widget) &Stack {
	w, h := sizes_f32_to_int(c.width, c.height)
	mut s := &Stack{
		height: h
		width: w
		widths: c.widths
		heights: c.heights
		vertical_alignment: c.vertical_alignment
		horizontal_alignment: c.horizontal_alignment
		vertical_alignments: c.vertical_alignments
		horizontal_alignments: c.horizontal_alignments
		spacing: c.spacing
		stretch: c.stretch
		direction: c.direction
		margin: c.margin.as_margin()
		children: children
		ui: 0
	}
	return s
}

fn (mut s Stack) init(parent Layout) {
	s.parent = parent
	mut ui := parent.get_ui()
	s.ui = ui

	// Before position all sizes need to be determined
	s.set_all_sizes(parent)

	// Set the position of this stack (anchor could possibly be defined inside set_pos later as suggested by Kahsa)
	s.set_pos(s.x, s.y)

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

fn (mut s Stack) set_all_sizes(parent Layout) {
	// Only once for all children recursively find all the adjusted sizes
	if parent is Window {
		s.set_adjusted_size(0, true, s.ui)
	}

	s.init_size(parent)

	// if s.direction == .column {
	if s.height == 0 {
		println('stack adjusted height')
		s.height = s.adj_height
	} else {
		s.height -= s.margin.top + s.margin.bottom
	}
	// } else {
	if s.width == 0 {
		s.width = s.adj_width
	} else {
		s.width -= s.margin.left + s.margin.right
	}
	// println('stack $s.name() => size ($s.width, $s.height) cfg: ($s.cfg_width, $s.cfg_height) adj: ($s.adj_width, $s.adj_height) ')
	s.debug_show_sizes('init -> ')

	//** size of children from **
	// default values for widths and heights
	if s.direction == .row {
		if s.heights.len == 0 {
			s.heights = [f32(1)].repeat(s.children.len)
		}
		if s.widths.len == 0 {
			// equispaced
			p := f32(1) / f32(s.children.len)
			s.widths = [p].repeat(s.children.len)
		}
	} else {
		if s.widths.len == 0 {
			s.widths = [f32(1)].repeat(s.children.len)
		}
		if s.heights.len == 0 {
			// equispaced
			p := f32(1) / f32(s.children.len)
			s.heights = [p].repeat(s.children.len)
		}
	}

	// set children sizes
	println('s.widths: $s.widths s.heights: $s.heights')
	mut w := 0
	mut h := 0
	free_width, free_height := s.free_size()
	for i, mut child in s.children {
		// TODO: replace set_width and set_height by with propose_size
		w = size_f32_to_int(s.widths[i])
		println('widths[$i]=  $w <- ${s.widths[i]}')
		h = size_f32_to_int(s.heights[i])
		println('heights[$i]= $h <- ${s.heights[i]}')
		w = relative_size_from_parent(w, free_width)
		println('w[$i]=  $w')
		h = relative_size_from_parent(h, free_height)
		println('h[$i]=  $h')
		child.propose_size(w, h)
	}
	//** end size of children **
}

/*
The rules for internal decoding of size (no need for the user to know that) are:
* size < 0 (get from relative parent size) =>
*/
fn (mut s Stack) init_size(parent Layout) {
	parent_width, parent_height := parent.size()
	// s.debug_show_sizes("decode before -> ")
	if parent is Window {
		// Default: like stretch = strue
		s.height = parent_height - s.margin.top - s.margin.right
		s.width = parent_width - s.margin.left - s.margin.right
	} else if s.stretch {
		if s.direction == .row {
			s.height = parent_height - s.margin.top - s.margin.right
		} else {
			s.width = parent_width - s.margin.left - s.margin.right
		}
	}
}

fn (mut s Stack) set_children_pos() {
	mut x := s.x
	mut y := s.y
	for i, mut child in s.children {
		child_width, child_height := child.size()
		s.set_child_pos(child, i, x, y)
		if s.direction == .row {
			x += child_width + s.spacing
		} else {
			y += child_height + s.spacing
		}
		if child is Stack {
			child.set_children_pos()
		}
	}
}

fn (s &Stack) set_child_pos(mut child Widget, i int, x int, y int) {
	// Only alignment along the opposite direction (ex: .row if direction is .column and vice-versa) is considered
	// TODO: alignment in the direct direction
	// (for these different cases, container size in the direct direction is more complicated to compute)

	child_width, child_height := child.size()
	if s.direction == .column {
		container_width := s.width
		mut x_offset := 0
		match s.get_horizontal_alignment(i) {
			.left {
				x_offset = 0
			}
			.center {
				if container_width > child_width {
					x_offset = (container_width - child_width) / 2
				} else {
					x_offset = 0
				}
			}
			.right {
				if container_width > child_width {
					x_offset = (container_width - child_width)
				} else {
					x_offset = 0
				}
			}
		}
		child.set_pos(x + x_offset, y)
	} else {
		container_height := s.height
		mut y_offset := 0
		match s.get_vertical_alignment(i) {
			.top {
				y_offset = 0
			}
			.center {
				if container_height > child_height {
					y_offset = (container_height - child_height) / 2
				} else {
					y_offset = 0
				}
			}
			.bottom {
				if container_height > child_height {
					y_offset = container_height - child_height
				} else {
					y_offset = 0
				}
			}
		}
		child.set_pos(x, y + y_offset)
	}
}

fn (mut s Stack) set_adjusted_size(i int, force bool, ui &UI) {
	mut h := 0
	mut w := 0
	for mut child in s.children {
		mut child_width, mut child_height := 0, 0
		if child is Stack {
			if force || child.adj_width == 0 {
				child.set_adjusted_size(i + 1, force, ui)
			}
			child_width, child_height = child.adj_width + child.margin.left + child.margin.right, 
				child.adj_height + child.margin.top + child.margin.bottom
		} else if child is Group {
			if force || child.adj_width == 0 {
				child.set_adjusted_size(i + 1, ui)
			}
			child_width, child_height = child.adj_width + child.margin_left + child.margin_right, 
				child.adj_height + child.margin_top + child.margin_bottom
		} else {
			if child is Label {
				child.set_ui(ui)
			} else if child is Button {
				child.set_ui(ui)
			}
			child_width, child_height = child.size()
		}
		if s.direction == .column {
			h += child_height // height of vertical stack means adding children's height
			if child_width > w { // width of vertical stack means greatest children's width
				w = child_width
			}
		} else {
			w += child_width // width of horizontal stack means adding children's width
			if child_height > h { // height of horizontal stack means greatest children's height
				h = child_height
			}
		}
	}
	// adding total spacing between children
	if s.direction == .column {
		h += s.total_spacing()
	} else {
		w += s.total_spacing()
	}
	s.adj_width = w
	s.adj_height = h
}

fn (mut s Stack) set_pos(x int, y int) {
	// could depend on anchor in the future 
	// Default is anchor=.top_left here (and could be .top_right, .bottom_left, .bottom_right)
	s.x = x + s.margin.left
	s.y = y + s.margin.top
}

fn (s &Stack) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (mut s Stack) propose_size(w int, h int) (int, int) {
	// if s.stretch {
	// 	s.width = w
	// 	if s.height == 0 {
	// 		s.height = h
	// 	}
	// }
	s.width, s.height = w - s.margin.left - s.margin.right, h - s.margin.top - s.margin.bottom
	return s.width, s.height
}

fn (s &Stack) size() (int, int) {
	mut w := s.width
	mut h := s.height
	// TODO: this has to disappear (not depending on adjusted_size)
	// if s.width < s.adj_width {
	// 	w = s.adj_width
	// }
	// if s.height < s.adj_height {
	// 	h = s.adj_height
	// }
	w += s.margin.left + s.margin.right
	h += s.margin.top + s.margin.bottom
	return w, h
}

fn (s &Stack) free_size() (int, int) {
	mut w := s.width
	mut h := s.height
	if s.direction == .row {
		w -= s.total_spacing()
	} else {
		h -= s.total_spacing()
	}
	return w, h
}

fn (mut s Stack) draw() {
	for child in s.children {
		child.draw()
	}
	// DEBUG MODE: Uncomment to display the bounding boxes
	s.draw_bb()
}

fn (s &Stack) total_spacing() int {
	total_spacing := (s.children.len - 1) * s.spacing
	return total_spacing
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

pub fn (s &Stack) get_children() []Widget {
	return s.children
}

pub fn (mut s Stack) set_children(c []Widget) {
	s.children = c
}

fn (s &Stack) get_vertical_alignment(i int) VerticalAlignment {
	mut align := s.vertical_alignment
	if i in s.vertical_alignments.top {
		align = .top
	} else if i in s.vertical_alignments.center {
		align = .center
	} else if i in s.vertical_alignments.bottom {
		align = .bottom
	}
	return align
}

fn (s &Stack) get_horizontal_alignment(i int) HorizontalAlignment {
	mut align := s.horizontal_alignment
	if i in s.horizontal_alignments.left {
		align = .left
	} else if i in s.horizontal_alignments.center {
		align = .center
	} else if i in s.horizontal_alignments.right {
		align = .right
	}
	return align
}
