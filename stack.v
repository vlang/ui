// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
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
	width                int // To remove soon
	height               int // To remove soon
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing              Spacing = Spacing(0) // int
	stretch              bool
	direction            Direction
	margin               MarginConfig
	// children related
	widths                []f32   // children sizes
	heights               []f32
	align                 Alignments
	vertical_alignments   VerticalAlignments
	horizontal_alignments HorizontalAlignments
}

struct Stack {
	cache                 CachedSizes
mut:
	x                     int
	y                     int
	width                 int
	height                int
	parent                Layout
	root                  &Window = voidptr(0)
	ui                    &UI
	vertical_alignment    VerticalAlignment
	horizontal_alignment  HorizontalAlignment
	spacing               []int // int
	stretch               bool
	direction             Direction
	margin                Margin
	adj_width             int
	adj_height            int
	// children related
	children              []Widget
	widths                []f32 // children sizes
	heights               []f32
	vertical_alignments   VerticalAlignments // Flexible alignments by index overriding alignment.
	horizontal_alignments HorizontalAlignments
	alignments            Alignments
}

fn stack(c StackConfig, children []Widget) &Stack {
	// w, h := sizes_f32_to_int(c.width, c.height)
	mut s := &Stack{
		height: c.height // TODO to remove
		width: c.width // TODO to remove
		vertical_alignment: c.vertical_alignment
		horizontal_alignment: c.horizontal_alignment
		spacing: c.spacing.as_int_array(children.len - 1)
		stretch: c.stretch
		direction: c.direction
		margin: c.margin.as_margin()
		children: children
		widths: c.widths
		heights: c.heights
		vertical_alignments: c.vertical_alignments
		horizontal_alignments: c.horizontal_alignments
		alignments: c.align
		ui: 0
	}
	return s
}

fn (mut s Stack) init(parent Layout) {
	s.parent = parent
	mut ui := parent.get_ui()
	s.ui = ui

	s.init_size(parent)

	if parent is Window {
		s.root = parent
		// Only once for all children recursively
		// 1) find all the adjusted sizes
		s.set_adjusted_size(0, true, s.ui)
		// 2) set cache sizes
		s.set_cache_sizes()
		$if debug_cache ? {
			s.debug_show_cache(0, "")
		}
		// 3) set all the sizes (could be updated possibly for resizing)
		$if devel  ? {
			s.set_children_sizes()
		} $else {
			s.set_children_sizes_old(parent)
		}
		
	} else if parent is Stack {
		s.root = parent.root
	}

	// All sizes have to be set before positionning widgets
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

fn (mut s Stack) set_children_sizes_old(parent Layout) {
	$if debug_sizes ? {s.debug_show_sizes("BEGIN set_children_size_old ")}

	//* size of children from *

	// set children sizes
	$if debug_sizes ? { println('s.widths: $s.widths s.heights: $s.heights')}
	free_width, free_height := s.free_size()
	for i, mut child in s.children {
		w,h := s.set_child_size(child, i, free_width, free_height)
		
		child.propose_size(w, h)

		if child is Stack {
			child.set_children_sizes_old(s)
		}
	}
	$if debug_sizes ? {s.debug_show_sizes("END set_children_size_old ")} 
}

// default values for s.widths and s.heights
fn (mut s Stack) default_sizes() {
	mut st := f32(1)
	$if devel ? {
		st = f32(ui.stretch)
	}
	if s.direction == .row {
		if s.heights.len == 0 {
			s.heights = [st].repeat(s.children.len)
		}
		if s.widths.len == 0 {
			p := if is_children_have_widget(s.children) {
				ui.compact
			} else {
				// equispaced
				f32(1) / f32(s.children.len)
			}
			s.widths = [p].repeat(s.children.len)
		}
	} else {
		if s.widths.len == 0 {
			s.widths = [st].repeat(s.children.len)
		}
		if s.heights.len == 0 {
			p := if is_children_have_widget(s.children) {
				ui.compact
			} else {
				// equispaced
				f32(1) / f32(s.children.len)
			}
			s.heights = [p].repeat(s.children.len)
		}
	}
}

fn (mut s Stack) set_child_size(mut child Widget, i int, free_width int, free_height int) (int, int) {
	// set initial child size
	if child is Stack {
		child.adjustable_size()
	}
	mut w, mut h := child.size()

	// TODO: replace set_width and set_height by with propose_size
	if i < s.widths.len && s.widths[i] > 0 {
		w = size_f32_to_int(s.widths[i])
		// println('widths[$i]=  $w <- ${s.widths[i]}')
		w = relative_size_from_parent(w, free_width)
		// println('w[$i]=  $w')
	}
	if i < s.heights.len && s.heights[i] > 0 {
		h = size_f32_to_int(s.heights[i])
		// println('heights[$i]= $h <- ${s.heights[i]}')
		h = relative_size_from_parent(h, free_height)
		// println('h[$i]=  $h')
	}
	return w, h
}

fn (mut s Stack) adjustable_size() {
	if s.height == 0 {
		$if debug_adjustable ? {
			print('stack $s.name() ')
			C.printf(' %p', s)
			println(' adjusted height $s.height <- $s.adj_height')
		}
		s.height = s.adj_height
	}
	if s.width == 0 {
		$if debug_adjustable ? {
			print('stack $s.name() ')
			C.printf(' %p', s)
			println(' adjusted width $s.width <- $s.adj_width')
		}
		s.width = s.adj_width
	}
	// println('stack $s.name() => size ($s.width, $s.height) cfg: ($s.cfg_width, $s.cfg_height) adj: ($s.adj_width, $s.adj_height) ')
	// s.debug_show_sizes('init -> ')
}

/*********************
How to interpret weight ?
if weight_<size>s[i] is :
== 0 then fixed size
in ]0,1] then weighted size with two different cases: 1) fixed < 0 (updatable widget with propose_size) and 2) fixed ==0 (static)
== -2 then adjusted size
***********************/

fn (mut s Stack) set_cache_sizes() {
	// 
	s.default_sizes()
	//
	len := s.children.len
	mut c := &s.cache
	// size preallocated
	c.fixed_width, c.fixed_height = 0, 0
	c.min_width, c.min_height = 0, 0
	c.width_mass, c.height_mass = 0., 0.
	// fixed_<size>s and weight_<size>s can be cached in the Stack struct as private fields
	// since once they are determined, they would never be updated
	// above all, they would be used when resizing
	c.fixed_widths, c.fixed_heights = [0].repeat(len), [0].repeat(len)
	c.weight_widths, c.weight_heights = [0.].repeat(len), [0.].repeat(len) 
	
	for i, mut child in s.children {
		// adjusted (natural size) child size
		if child is Stack {
			child.adjustable_size()
		}
		adj_child_width, adj_child_height := child.size()

		// cw as child width with type f64 
		cw := s.widths[i] or { 0. }
		if cw > 1 { 
			// fixed size ?
			if cw == int(cw) {
				c.fixed_widths[i] = int(cw)
				if s.direction == .row {
					c.fixed_width += c.fixed_widths[i]
					c.min_width += c.fixed_widths[i]
				} else {
					if c.fixed_widths[i] > c.fixed_width {c.fixed_width = c.fixed_widths[i]}
					if c.fixed_widths[i] > c.min_width {c.min_width = c.fixed_widths[i]}
				}
			} else {
				// Possibly useful for Stack children: 200.6 as 200 as minimal size and .6 as weight
				c.fixed_widths[i] = int(cw)
				c.weight_widths[i] = cw - int(cw)
				if s.direction == .row {
					c.fixed_width += c.fixed_widths[i]
					c.min_width += c.fixed_widths[i]
					c.width_mass += c.weight_widths[i]
				} else {
					if c.fixed_widths[i] > c.fixed_width {c.fixed_width = c.fixed_widths[i]}
					if c.fixed_widths[i] > c.min_width {c.min_width = c.fixed_widths[i]}
				}
			}
		} else if cw > 0 {
			// weighted size
			c.weight_widths[i] = cw
			// Internally, fixed_widths[i] is set to minimal fixed size
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row {
				c.width_mass += cw
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.min_width {c.min_width = c.fixed_widths[i]}
			}
		} else if cw == 0 {
			// width for Widget and adj_width for Layout
			c.fixed_widths[i] = adj_child_width
			// Internally, weight_widths = -1 means that the sizes inherit from children
			c.weight_widths[i] = -2.
			if s.direction == .row {
				c.fixed_width += c.fixed_widths[i]
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.fixed_width {c.fixed_width = c.fixed_widths[i]}
				if c.fixed_widths[i] > c.min_width {c.min_width = c.fixed_widths[i]}
			}
		} else if cw >= -1 {
			// weight_widths is now  means that the children can have their size updated from the parent
			// even reducing their size!!!
			c.weight_widths[i] = -cw
			// This is the initial size
			c.fixed_widths[i] = -adj_child_width
			if s.direction == .row {
				c.width_mass += -cw
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.min_width {c.min_width = c.fixed_widths[i]}
			}
		} else if cw == ui.stretch {
			c.weight_widths[i] = 1.0
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row {
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.min_width {c.min_width = c.fixed_widths[i]}
			}
		}
		// ch as child height with type f64 
		ch := s.heights[i] or { 0. }
		if ch > 1 {
			// fixed size ?
			if ch == int(ch) {
				c.fixed_heights[i] = int(ch)
				if s.direction == .column {
					c.fixed_height += c.fixed_heights[i]
					c.min_height += c.fixed_heights[i]
				} else {
					if c.fixed_heights[i] > c.fixed_height {c.fixed_height = c.fixed_heights[i]}
					if c.fixed_heights[i] > c.min_height {c.min_height = c.fixed_heights[i]}
				}
			} else {
				// Possibly useful for Stack children: 200.6 as 200 as minimal size and .6 as weight
				c.fixed_heights[i] = int(ch)
				c.weight_heights[i] = ch - int(ch)
				if s.direction == .column {
					c.fixed_height += c.fixed_heights[i]
					c.min_height += c.fixed_heights[i]
					c.height_mass += c.weight_heights[i]
				} else {
					if c.fixed_heights[i] > c.fixed_height {c.fixed_height = c.fixed_heights[i]}
					if c.fixed_heights[i] > c.min_height {c.min_height = c.fixed_heights[i]}
				}
			}
		} else if ch > 0 {
			// weighted size
			c.weight_heights[i] = ch
			// Internally, fixed_heights[i] is set to minimal fixed size
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column {
				c.height_mass += ch
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.min_height {c.min_height = c.fixed_heights[i]}
			}
		} else if ch == 0 {
			// height for Widget and adj_height for Layout
			c.fixed_heights[i] = adj_child_height
			// N.B.: Internally, weight_heights = 0 means that the sizes inherit from children
			c.weight_heights[i] = -2.
			if s.direction == .column {
				c.fixed_height += c.fixed_heights[i]
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.fixed_height {c.fixed_height = c.fixed_heights[i]}
				if c.fixed_heights[i] > c.min_height {c.min_height = c.fixed_heights[i]}
			}
		} else if ch >= -1 {
			// weight_heights is now  means that the children can have their size updated from the parent
			// even reducing their size!!!
			c.weight_heights[i] = cw
			// This is the initial size
			c.fixed_heights[i] = -adj_child_height
			if s.direction == .column {
				c.height_mass += -ch
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.min_height {c.min_height = c.fixed_heights[i]}
			}
		} else if ch == ui.stretch {
			c.weight_heights[i] = 1.
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column {
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.min_height {c.min_height = c.fixed_heights[i]}
			}
		}

		// recursively do the same for Stack children
		if child is Stack {
			child.set_cache_sizes()
		}
	}
}

fn (s &Stack) children_sizes() ([]int, []int) {
	mut mcw, mut mch := [0].repeat(s.children.len), [0].repeat(s.children.len)
	// free size without margin and spacing
	free_width, free_height := s.free_size()
	c := &s.cache
	for i, _ in s.children {
		if s.widths[i] == ui.stretch {
			mcw[i] = free_width
		} else if c.weight_widths[i] > 0 {
			weight := c.weight_widths[i] / c.width_mass
			mcw[i] = int(weight * free_width)
		} else {
			mcw[i] = c.fixed_widths[i]
		}

		if s.heights[i] == ui.stretch {
			mch[i] = free_height
		} else if c.weight_heights[i] > 0 {
			weight := c.weight_heights[i] / c.height_mass
			mch[i] = int(weight * free_height)
		} else {
			mch[i] = c.fixed_heights[i]
		}
	}
	return mcw, mch
}


fn (mut s Stack) set_children_sizes() {
	$if debug_sizes ? {s.debug_show_sizes("BEGIN set_children_size ")}

	//* size of children from *
	c := &s.cache
	widths, heights := s.children_sizes()

	// set children sizes
	$if debug_sizes ? { println('s.widths: $s.widths s.heights: $s.heights')}
	free_width, free_height := s.free_size()
	for i, mut child in s.children {
		mut w, mut h := child.size()
		if child is Stack {
			w, h= widths[i], heights[i]
		} else {
			// For widget, only when proposed mode accepted 
			if s.widths[i] == ui.stretch || c.weight_widths[i] < 0 {
				w = widths[i]
			}
			if s.heights[i] == ui.stretch || c.weight_heights[i] < 0 {
				h = heights[i]
			}
		}
		
		child.propose_size(w, h)

		if child is Stack {
			child.set_children_sizes()
		}
	}
	$if debug_sizes ? {s.debug_show_sizes("END set_children_size ")} 
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

fn (mut s Stack) set_children_pos() {
	mut x := s.x
	mut y := s.y
	for i, mut child in s.children {
		child_width, child_height := child.size()
		s.set_child_pos(child, i, x, y)
		if s.direction == .row {
			x += child_width
			if i < s.children.len - 1 {
				x += s.spacing[i]
			}
		} else {
			y += child_height
			if i < s.children.len - 1 {
				y += s.spacing[i]
			}
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

fn (s &Stack) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

fn (mut s Stack) draw() {
	for child in s.children {
		child.draw()
	}
	// DEBUG MODE: Uncomment to display the bounding boxes
	$if debug_bb ? {
		s.draw_bb()
	}
}

fn (s &Stack) total_spacing() int {
	mut total_spacing := 0
	// println('len $s.children.len $s.spacing')
	if s.spacing.len > 0 && s.children.len > 1 {
		for i in 0 .. (s.children.len - 1) {
			total_spacing += s.spacing[i]
		}
	}
	// println('len $total_spacing')
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

fn (s &Stack) set_child_pos_aligned(mut child Widget, i int, x int, y int) {
	child_width, child_height := child.size()
	horizontal_alignment, vertical_alignment := s.get_alignments(i)
	// set x_offset
	container_width := s.width
	mut x_offset := 0
	match horizontal_alignment {
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
	// set y_offset
	container_height := s.height
	mut y_offset := 0
	match vertical_alignment {
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
	child.set_pos(x + x_offset, y + y_offset)
}

fn (s &Stack) get_alignments(i int) (HorizontalAlignment, VerticalAlignment)  {
	mut hor_align := s.horizontal_alignment
	mut ver_align := s.vertical_alignment
	if i in s.alignments.center {
		hor_align, ver_align = .center, .center
	} else if i in s.alignments.left_top {
		hor_align, ver_align = .left, .top
	} else if i in s.alignments.top {
		hor_align, ver_align = .center, .top
	} else if i in s.alignments.right_top  {
		hor_align, ver_align = .right, .top
	} else if i in s.alignments.right {
		hor_align, ver_align = .right, .center
	} else if i in s.alignments.right_bottom {
		hor_align, ver_align = .right, .bottom
	} else if i in s.alignments.bottom {
		hor_align, ver_align = .center, .bottom
	} else if i in s.alignments.left_bottom {
		hor_align, ver_align = .left, .bottom
	} else if i in s.alignments.left {
		hor_align, ver_align = .left, .center
	}

	return hor_align, ver_align
}
