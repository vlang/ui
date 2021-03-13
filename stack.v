// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import eventbus
// import gg

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
	spacings             []f32 // Spacing = Spacing(0) // int
	spacing              f32
	stretch              bool
	direction            Direction
	margins              Margins
	// children related
	widths                []f32 // children sizes
	heights               []f32
	align                 Alignments
	vertical_alignments   VerticalAlignments
	horizontal_alignments HorizontalAlignments
}

struct Stack {
	cache CachedSizes
mut:
	x                    int
	y                    int
	width                int
	height               int
	z_index              int
	parent               Layout
	ui                   &UI
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacings             []f32 // []int // int
	stretch              bool
	direction            Direction
	margins              Margins
	real_width           int
	real_height          int
	adj_width            int
	adj_height           int
	// children related
	children              []Widget
	drawing_children      []Widget
	widths                []f32 // children sizes
	heights               []f32
	vertical_alignments   VerticalAlignments // Flexible alignments by index overriding alignment.
	horizontal_alignments HorizontalAlignments
	alignments            Alignments
	hidden                bool
}

fn stack(c StackConfig, children []Widget) &Stack {
	// w, h := sizes_f32_to_int(c.width, c.height)
	mut s := &Stack{
		height: c.height // become real_height
		width: c.width // become real_width
		vertical_alignment: c.vertical_alignment
		horizontal_alignment: c.horizontal_alignment
		spacings: c.spacings
		stretch: c.stretch
		direction: c.direction
		margins: c.margins
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

	s.init_size()

	// Init all children recursively
	for mut child in s.children {
		child.init(s)
	}

	if parent is Window {
		ui.window = parent
		mut window := parent
		window.root_layout = s
		window.update_layout() // i.e s.update_all_children_recursively(parent)
	}
}

// used inside window.update_layout()
pub fn (mut s Stack) update_all_children_recursively(parent Window) {
	// Only once for all children recursively
	// 1) find all the adjusted sizes
	s.set_adjusted_size(0, true, s.ui)
	// 2) set cache sizes
	s.set_cache_sizes()
	$if cache ? {
		s.debug_show_cache(0, '')
	}
	// 3) set all the sizes (could be updated possibly for resizing)
	s.set_children_sizes()
	// All sizes have to be set before positionning widgets
	// 4) Set the position of this stack (anchor could possibly be defined inside set_pos later as suggested by Kahsa)
	s.set_pos(s.x, s.y)
	// 5) children z_index
	s.set_drawing_children()
	// 6) set position for chilfren
	s.set_children_pos()
	$if android {
		s.resize(parent.width, parent.height)
	} $else {
		if parent.mode in [.fullscreen, .max_size, .resizable] {
			s.resize(parent.width, parent.height)
		}
	}
}

fn (mut s Stack) init_size() {
	parent := s.parent
	parent_width, parent_height := parent.size()
	// s.debug_show_sizes("decode before -> ")
	if parent is Window {
		// Default: like stretch = strue
		s.real_height = parent_height
		s.real_width = parent_width
	}
	// else if s.stretch {
	// 	if s.direction == .row {
	// 		s.real_height = parent_height
	// 		s.real_width = s.width
	// 	} else {
	// 		s.real_width = parent_width
	// 		s.real_height = s.height
	// 	}
	// } else {
	// 	s.real_width = s.width
	// 	s.real_height = s.height
	// }
	s.height = s.real_height - s.margin(.top) - s.margin(.bottom)
	s.width = s.real_width - s.margin(.left) - s.margin(.right)
}

fn (mut s Stack) set_children_sizes() {
	$if scs ? {
		s.debug_show_sizes('BEGIN set_children_size ')
	}
	//* size of children from *
	c := &s.cache
	widths, heights := s.children_sizes()

	// set children sizes
	$if scs ? {
		println('s.widths: $s.widths s.heights: $s.heights widths: $widths heights: $heights')
	}

	for i, mut child in s.children {
		mut w, mut h := child.size()
		$if scs ? {
			println('before propose_size $i) $child.type_name() ($w,$h) ')
		}
		if child is Stack || child is Group {
			w, h = widths[i], heights[i]
		} else {
			$if scs ? {
				// tmp := (s.widths[i] == ui.stretch)
				// tmp2 := (c.weight_widths[i] <= 0)
				// tmp3 := (s.heights[i] == ui.stretch)
				// tmp4 := (c.weight_heights[i] <= 0)
				// println("tmp=$tmp tmp2=$tmp2 tmp3=$tmp3 tmp4=$tmp4")
			}
			if c.width_type[i] in [.stretch, .weighted] {
				w = widths[i]
			}
			if c.height_type[i] in [.stretch, .weighted] {
				h = heights[i]
			}
		}
		$if scs ? {
			println('propose_size $i) $child.type_name() ($w,$h)')
		}
		child.propose_size(w, h)

		if child is Stack {
			child.set_children_sizes()
		}
	}
	$if scs ? {
		s.debug_show_sizes('END set_children_size ')
	}
}

fn (s &Stack) children_sizes() ([]int, []int) {
	mut mcw, mut mch := [0].repeat(s.children.len), [0].repeat(s.children.len)
	// free size without margin and spacing
	mut free_width, mut free_height := s.free_size()
	mut c := &s.cache
	free_width -= c.fixed_width
	free_height -= c.fixed_height
	$if cs ? {
		println(' children_size: ${typeof(s).name} s.widths:  $s.widths s.heights:  $s.heights ')
		println('    w weight: ($c.weight_widths, $c.width_mass)  fixed: ($c.fixed_widths, $c.fixed_width, $c.min_width)')
		println('    h weight: ($c.weight_heights, $c.height_mass)  fixed: ($c.fixed_heights, $c.fixed_height, $c.min_height)')
		println('    type w: $c.width_type h: $c.height_type')
		println('    free w: $free_width h: $free_height ')
	}
	for i, child in s.children {
		// child_w, child_h := child.size()
		$if cs ? {
			println('$i) $child.type_name()')
		}

		match c.width_type[i] {
			.stretch {
				if s.direction == .row {
					$if cs2 ? {
						println('$i) .stretch width row: weight = ${c.weight_widths[i]} / $c.width_mass')
					}
					weight := c.weight_widths[i] / c.width_mass
					mcw[i] = int(weight * free_width)
				} else {
					$if cs2 ? {
						println('$i) .stretch width col:  free_w=$free_width')
					}
					mcw[i] = free_width
				}
			}
			.weighted, .weighted_minsize {
				weight := c.weight_widths[i] / c.width_mass
				mcw[i] = int(weight * free_width)
			}
			.propose, .compact, .fixed {
				mcw[i] = c.fixed_widths[i]
			}
		}

		match c.height_type[i] {
			.stretch {
				if s.direction == .column {
					$if cs2 ? {
						println('$i) .stretch height col: weight = ${c.weight_heights[i]} / $c.height_mass')
					}
					weight := c.weight_heights[i] / c.height_mass
					mch[i] = int(weight * free_height)
				} else {
					$if cs2 ? {
						println('$i) .stretch height row : $free_width')
					}
					mch[i] = free_height
				}
				$if cs2 ? {
					println('.Stretch height:  $i) $child.type_name() ${mch[i]}')
				}
			}
			.weighted, .weighted_minsize, .propose {
				weight := c.weight_heights[i] / c.height_mass
				mch[i] = int(weight * free_height)
			}
			.compact, .fixed {
				mch[i] = c.fixed_heights[i]
			}
		}
	}
	$if cs ? {
		println('mcw: $mcw mch: $mch')
	}
	return mcw, mch
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
	c.width_type, c.height_type = [ChildSize(0)].repeat(len), [ChildSize(0)].repeat(len)

	for i, mut child in s.children {
		mut cw := s.widths[i] or { 0. }
		mut ch := s.heights[i] or { 0. }
		// adjusted (natural size) child size
		mut adj_child_width, mut adj_child_height := child.size()
		// if ! (child is Stack) {
		if child is Stack {
			adj_child_width, adj_child_height = child.adjustable_size()
		}
		if adj_child_width == 0 && cw == 0 {
			$if ui_stack_c0 ? {
				println('WARNINNGS222: Bad compact widths for ${typeof(s).name} $s.widths[$i]')
			}
			s.widths[i] = stretch
			cw = stretch
		}
		if adj_child_height == 0 && ch == 0 {
			$if ui_stack_c0 ? {
				println('WARNINNGS222: Bad compact heights for $child.type_name() $s.heights[$i]')
			}
			s.heights[i] = stretch
			ch = stretch
		}
		// }
		// adj_child_width, adj_child_height := child.size()
		// TODO: here test if widget is zero sized????
		// cw as child width with type f64
		if cw > 1 {
			// fixed size ?
			if cw == int(cw) {
				c.width_type[i] = .fixed
				c.fixed_widths[i] = int(cw)
				if s.direction == .row {
					c.fixed_width += c.fixed_widths[i]
					c.min_width += c.fixed_widths[i]
				} else {
					if c.fixed_widths[i] > c.fixed_width {
						c.fixed_width = c.fixed_widths[i]
					}
					if c.fixed_widths[i] > c.min_width {
						c.min_width = c.fixed_widths[i]
					}
				}
			} else {
				// Possibly useful for Stack children: 200.6 as 200 as minimal size and .6 as weight
				c.width_type[i] = .weighted_minsize
				c.fixed_widths[i] = int(cw)
				c.weight_widths[i] = cw - int(cw)
				if s.direction == .row { // sum rule
					c.fixed_width += c.fixed_widths[i]
					c.min_width += c.fixed_widths[i]
					c.width_mass += c.weight_widths[i]
				} else { // max rule
					if c.fixed_widths[i] > c.fixed_width {
						c.fixed_width = c.fixed_widths[i]
					}
					if c.fixed_widths[i] > c.min_width {
						c.min_width = c.fixed_widths[i]
					}
				}
			}
		} else if cw > 0 {
			// weighted size
			c.width_type[i] = .weighted
			c.weight_widths[i] = cw
			// Internally, fixed_widths[i] is set to minimal fixed size
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row {
				c.width_mass += cw
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else if cw == 0 {
			// width for Widget and adj_width for Layout
			c.width_type[i] = .compact
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row {
				c.fixed_width += c.fixed_widths[i]
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.fixed_width {
					c.fixed_width = c.fixed_widths[i]
				}
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else if cw >= -1 {
			// weight_widths is now  means that the children can have their size updated from the parent
			// even reducing their size!!!
			c.width_type[i] = .propose
			c.weight_widths[i] = -cw
			// This is the initial size
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row {
				c.width_mass += c.weight_widths[i]
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else if cw == stretch {
			c.width_type[i] = .stretch
			c.weight_widths[i] = 1.0
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row {
				c.width_mass += c.weight_widths[i]
				c.min_width += c.fixed_widths[i]
			} else {
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		}
		// ch as child height with type f64 
		if ch > 1 {
			// fixed size ?
			if ch == int(ch) {
				c.height_type[i] = .fixed
				c.fixed_heights[i] = int(ch)
				if s.direction == .column {
					c.fixed_height += c.fixed_heights[i]
					c.min_height += c.fixed_heights[i]
				} else {
					if c.fixed_heights[i] > c.fixed_height {
						c.fixed_height = c.fixed_heights[i]
					}
					if c.fixed_heights[i] > c.min_height {
						c.min_height = c.fixed_heights[i]
					}
				}
			} else {
				// Possibly useful for Stack children: 200.6 as 200 as minimal size and .6 as weight
				c.height_type[i] = .weighted_minsize
				c.fixed_heights[i] = int(ch)
				c.weight_heights[i] = ch - int(ch)
				if s.direction == .column {
					c.fixed_height += c.fixed_heights[i]
					c.min_height += c.fixed_heights[i]
					c.height_mass += c.weight_heights[i]
				} else {
					if c.fixed_heights[i] > c.fixed_height {
						c.fixed_height = c.fixed_heights[i]
					}
					if c.fixed_heights[i] > c.min_height {
						c.min_height = c.fixed_heights[i]
					}
				}
			}
		} else if ch > 0 {
			// weighted size
			c.height_type[i] = .weighted
			c.weight_heights[i] = ch
			// Internally, fixed_heights[i] is set to minimal fixed size
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column {
				c.height_mass += ch
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else if ch == 0 {
			// height for Widget and adj_height for Layout
			c.height_type[i] = .compact
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column {
				c.fixed_height += c.fixed_heights[i]
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.fixed_height {
					c.fixed_height = c.fixed_heights[i]
				}
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else if ch >= -1 {
			// weight_heights is now  means that the children can have their size updated from the parent
			// even reducing their size!!!
			c.height_type[i] = .propose
			c.weight_heights[i] = -cw
			// This is the initial size
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column {
				c.height_mass += c.weight_heights[i]
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else if ch == stretch {
			c.height_type[i] = .stretch
			c.weight_heights[i] = 1.
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column {
				c.height_mass += c.weight_heights[i]
				c.min_height += c.fixed_heights[i]
			} else {
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		}
		// recursively do the same for Stack children
		if child is Stack {
			child.set_cache_sizes()
		}
	}
}

// default values for s.widths and s.heights
fn (mut s Stack) default_sizes() {
	st := f32(stretch)
	// comp := f32(ui.compact)
	p_equi := f32(1) / f32(s.children.len)
	if s.direction == .row {
		mut nb := s.heights.len
		if nb < s.children.len {
			for i, _ in s.children {
				// println("i=$i nb=$nb child_len=${s.children.len}  h_len= ${s.heights.len} ")
				if i < nb {
					continue
				}
				s.heights << st // if child is Stack || child is Group { st } else { comp }
			}
		}
		// println("1) nb=$nb child_len=${s.children.len}  h_len= ${s.heights.len} ")
		nb = s.widths.len
		if nb < s.children.len {
			for i, _ in s.children {
				// println("i=$i nb=$nb child_len=${s.children.len}  w_len= ${s.widths.len} ")
				if i < nb {
					continue
				}
				p := if is_children_have_widget(s.children) {
					compact
				} else {
					// equispaced
					p_equi
				}
				s.widths << p
			}
		}
		// println("2) nb=$nb child_len=${s.children.len}  w_len= ${s.widths.len} ")
	} else {
		mut nb := s.widths.len
		if nb < s.children.len {
			for i, _ in s.children {
				// println("i=$i nb=$nb child_len=${s.children.len}  w_len= ${s.widths.len} ")
				if i < nb {
					continue
				}
				s.widths << st // if child is Stack || child is Group { st } else { comp }
			}
		}
		// println("3) nb=$nb child_len=${s.children.len}  w_len= ${s.widths.len} ")
		nb = s.heights.len
		if nb < s.children.len {
			for i, _ in s.children {
				// println("i=$i nb=$nb child_len=${s.children.len}  h_len= ${s.heights.len} ")
				if i < nb {
					continue
				}
				p := if is_children_have_widget(s.children) {
					compact
				} else {
					// equispaced
					p_equi
				}
				s.heights << p
			}
		}
		// println("4) nb=$nb child_len=${s.children.len}  h_len= ${s.heights.len} ")
	}
}

fn (mut s Stack) adjustable_size() (int, int) {
	mut w, mut h := s.width, s.height
	if s.height == 0 {
		$if adj ? {
			print('stack ${typeof(s).name} ')
			C.printf(' %p', s)
			println(' adjusted height $s.height <- $s.adj_height')
		}
		h = s.adj_height
	}
	if s.width == 0 {
		$if adj ? {
			print('stack ${typeof(s).name} ')
			C.printf(' %p', s)
			println(' adjusted width $s.width <- $s.adj_width')
		}
		w = s.adj_width
	}
	return w, h
}

fn (mut s Stack) propose_size(w int, h int) (int, int) {
	s.real_width, s.real_height = w, h
	s.width, s.height = w - s.margin(.left) - s.margin(.right), h - s.margin(.top) - s.margin(.bottom)
	return s.width, s.height
}

fn (s &Stack) size() (int, int) {
	return s.real_width, s.real_height
}

fn (s &Stack) free_size() (int, int) {
	mut w, mut h := s.real_width - s.margin(.left) - s.margin(.right), s.real_height - s.margin(.top) - s.margin(.bottom)
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
			child_width, child_height = child.adj_width + child.margin(.left) + child.margin(.right), 
				child.adj_height + child.margin(.top) + child.margin(.bottom)
		} else if child is Group {
			if force || child.adj_width == 0 {
				child.set_adjusted_size(i + 1, ui)
			}
			child_width, child_height = child.adj_width + child.margin_left + child.margin_right, 
				child.adj_height + child.margin_top + child.margin_bottom
		} else {
			child_width, child_height = child.size()
			$if adj_size ? {
				println('adj size child $child.type_name(): ($child_width, $child_height) ')
			}
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
	s.x = x + s.margin(.left)
	s.y = y + s.margin(.top)
}

fn (mut s Stack) set_children_pos() {
	mut x := s.x
	mut y := s.y
	$if scp ? {
		println('Stack  pos: ($s.x, $s.y)')
	}
	for i, mut child in s.children {
		child_width, child_height := child.size()
		s.set_child_pos(child, i, x, y)
		if s.direction == .row {
			$if scp ? {
				println('$.row $i): child_width=$child_width x => $x')
			}
			x += child_width
			if i < s.children.len - 1 {
				x += s.spacing(i)
				$if scp ? {
					println('spacing($i): ${s.spacing(i)} x => $x')
				}
			}
		} else {
			y += child_height
			if i < s.children.len - 1 {
				y += s.spacing(i)
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
	$if scp ? {
		println('set_child_pos: $i) ${typeof(s).name}-$child.type_name()')
	}

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
		$if scp ? {
			println(' set_pos ($x,$y + $y_offset)')
		}
		child.set_pos(x, y + y_offset)
	}
}

fn (s &Stack) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

pub fn (mut s Stack) set_children_visible(state bool, children ...int) {
	for i, child in s.children {
		if i in children {
			child.set_visible(state)
		}
	}
	s.set_drawing_children()
}

fn (mut s Stack) set_drawing_children() {
	for mut child in s.children {
		if child is Stack {
			child.set_drawing_children()
		}
		// println("z_index: ${child.type_name()} $child.z_index")
		if child.z_index > s.z_index {
			s.z_index = child.z_index
		}
	}
	// println("Stack: z_index $s.z_index ")
	// s.drawing_children = s.children.clone()
	s.drawing_children = s.children.filter(!it.hidden)
	s.drawing_children.sort(a.z_index < b.z_index)
}

fn (mut s Stack) draw() {
	// DEBUG MODE: Uncomment to display the bounding boxes
	$if bb ? {
		s.draw_bb()
	}
	for child in s.drawing_children {
		// println("$child.type_name()")
		child.draw()
	}
}

fn (s &Stack) margin(side MarginSide) int {
	size := match side {
		.top { s.margins.top }
		.right { s.margins.right }
		.bottom { s.margins.bottom }
		.left { s.margins.left }
	}
	mut isize := int(size)
	if 0. < size && size < 1. {
		psize := if side in [.left, .right] { s.real_width } else { s.real_height }
		$if margin ? {
			println('margin($side) = $size * $psize')
		}
		isize = int(size * f32(psize))
	}
	$if margin ? {
		println('margin($side) = $isize')
	}
	return isize
}

fn (s &Stack) spacing(i int) int {
	size := s.spacings[i]
	mut isize := int(size)
	if 0. < size && size < 1. {
		psize := if s.direction == .row { s.real_width } else { s.real_height }
		$if spacing ? {
			println('spacing($i) = $size * $psize')
		}
		isize = int(size * f32(psize))
	}
	$if spacing ? {
		println('spacing($i) = $isize')
	}
	return isize
}

fn (s &Stack) total_spacing() int {
	mut total_spacing := 0
	// println('len $s.children.len $s.spacings')
	if s.spacings.len > 0 && s.children.len > 1 {
		for i in 0 .. (s.children.len - 1) {
			total_spacing += s.spacing(i)
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

fn (mut s Stack) set_visible(state bool) {
	s.hidden = state
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

fn (mut s Stack) resize(width int, height int) {
	s.init_size()
	s.set_children_sizes()
	s.set_children_pos()
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

fn (s &Stack) get_alignments(i int) (HorizontalAlignment, VerticalAlignment) {
	mut hor_align := s.horizontal_alignment
	mut ver_align := s.vertical_alignment
	if i in s.alignments.center {
		hor_align, ver_align = .center, .center
	} else if i in s.alignments.left_top {
		hor_align, ver_align = .left, .top
	} else if i in s.alignments.top {
		hor_align, ver_align = .center, .top
	} else if i in s.alignments.right_top {
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

//**** ChildrenConfig *****
pub struct ChildrenConfig {
mut:
	// add or remove
	at      int  = -1
	widths  Size = Size(-1.)
	heights Size = Size(-1.)
	// add
	spacing  f64   = -1.
	spacings []f64 = []f64{}
	child    Widget
	children []Widget
	// move
	from int = -1
	to   int = -1
}

pub fn (mut s Stack) add(cfg ChildrenConfig) {
	pos := if cfg.at == -1 { s.children.len } else { cfg.at }
	if 0 <= pos && pos <= s.children.len {
		if cfg.children.len > 0 {
			s.children.insert(pos, cfg.children)
			for w in cfg.children {
				w.init(s)
			}
		} else {
			s.children.insert(pos, cfg.child)
			cfg.child.init(s)
		}
		s.update_widths(cfg, .add)
		s.update_heights(cfg, .add)
		s.update_spacings(cfg, .add)
		window := s.ui.window
		window.update_layout()
	}
}

pub fn (mut s Stack) remove(cfg ChildrenConfig) {
	pos := if cfg.at == -1 { s.children.len - 1 } else { cfg.at }
	if 0 <= pos && pos < s.children.len {
		mut children := []Widget{}
		for i, child in s.children {
			if i != pos {
				children << child
			}
		}
		s.children = children
		s.update_widths(cfg, .remove)
		s.update_heights(cfg, .remove)
		s.update_spacings(cfg, .remove)
		window := s.ui.window
		window.update_layout()
	}
}

pub fn (mut s Stack) move(cfg ChildrenConfig) {
	from_pos := if cfg.from == -1 { s.children.len - 1 } else { cfg.from }
	mut to_pos := if cfg.to == -1 { s.children.len } else { cfg.to }
	if 0 <= from_pos && from_pos < s.children.len && 0 <= to_pos && to_pos <= s.children.len {
		if from_pos < to_pos {
			to_pos--
		}
		child := s.children[from_pos]
		// remove
		mut children := []Widget{}
		for i, ch in s.children {
			if i != from_pos {
				children << ch
			}
		}
		s.children = children
		// add the new one
		s.children.insert(to_pos, child)
		window := s.ui.window
		window.update_layout()
	}
}

// pub fn (mut s Stack) move_to_stack(cfg ChildrenConfig, to_s Stack, to_cfg ChildrenConfig) {
// 	pos := if cfg.at == -1 { s.children.len - 1 } else { cfg.at }

// 	to_pos := if to_cfg.at == -1 { to_s.children.len} } else { to_cfg.at }
// 	if 0 <= pos && pos < s.children.len && 0 <= target_pos && target_pos <= to_s.children.len {
// 			if from_pos < to_pos {to_pos--}
// 			child := s.children[from_pos]
// 			// remove
// 			from_begin, from_end := s.children[..from_pos], s.children[(from_pos + 1)..]
// 			s.children = from_begin
// 			s.children << from_end
// 			// add the new one
// 			to_begin, target_end := s.children[..to_pos], s.children[to_pos..]
// 			s.children = to_begin
// 			s.children << child
// 			s.children << to_end

// 		} else {
// 			child := s.children[from_pos]
// 			from_begin, from_end := s.children[..pos], s.children[(pos + 1)..]
// 			to_begin, target_end := to_s.children[..target_pos], s.children[target_pos..]
// 		}
// 	}
// }

enum ChildUpdateType {
	add
	remove
	move
}

pub fn (mut s Stack) update_widths(cfg ChildrenConfig, mode ChildUpdateType) {
	if cfg.widths is f64 {
		if cfg.widths == -1. {
			match mode {
				.add {
					widths := if s.direction == .row { stretch } else { compact }
					s.widths = Size(widths).as_f32_array(s.children.len)
				}
				.remove {
					if s.children.len == 0 {
						s.widths = []f32{}
					} else {
						pos := if cfg.at == -1 { s.children.len } else { cfg.at }
						widths_end := s.widths[(pos + 1)..]
						s.widths = s.widths[..pos]
						s.widths << widths_end
					}
				}
				.move {}
			}
		} else {
			s.widths = [f32(cfg.widths)].repeat(s.children.len)
		}
	} else {
		s.widths = cfg.widths.as_f32_array(s.children.len)
	}
}

pub fn (mut s Stack) update_heights(cfg ChildrenConfig, mode ChildUpdateType) {
	if cfg.heights is f64 {
		if cfg.heights == -1. {
			match mode {
				.add {
					heights := if s.direction == .row { compact } else { stretch }
					s.heights = Size(heights).as_f32_array(s.children.len)
				}
				.remove {
					if s.children.len == 0 {
						s.heights = []f32{}
					} else {
						pos := if cfg.at == -1 { s.children.len } else { cfg.at }
						heights_end := s.heights[(pos + 1)..]
						s.heights = s.heights[..pos]
						s.heights << heights_end
					}
				}
				.move {}
			}
		} else {
			s.heights = [f32(cfg.heights)].repeat(s.children.len)
		}
	} else {
		s.heights = cfg.heights.as_f32_array(s.children.len)
	}
}

pub fn (mut s Stack) update_spacings(cfg ChildrenConfig, mode ChildUpdateType) {
	if cfg.spacing != -1. || cfg.spacings.len != 0 {
		if s.children.len > 0 {
			s.spacings = spacings(cfg.spacing, cfg.spacings, s.children.len - 1)
		}
	} else {
		match mode {
			.add {
				// TODO: to improve
				s.spacings = spacings(s.spacings[0], cfg.spacings, s.children.len - 1)
			}
			.remove {
				// update spacings
				if s.children.len < 2 {
					s.spacings = []f32{}
				} else {
					s.spacings = s.spacings[0..(s.spacings.len - 1)]
				}
			}
			.move {}
		}
	}
}

pub fn (s &Stack) get_child(from ...int) ?Widget {
	mut children := s.children
	for i, ind in from {
		if i < from.len - 1 {
			if ind >= 0 && ind < children.len {
				widget := children[ind]
				if widget is Stack {
					children = widget.children
				} else {
					return error('$from uncorrect: $from[$i]=$ind does not correspond to a Layout')
				}
			} else if i == -1 {
				widget := children[children.len - 1]
				if widget is Stack {
					children = widget.children
				}
			} else {
				return error('$from uncorrect: $from[$i]=$ind out of bounds')
			}
		} else {
			if ind >= 0 && ind < children.len {
				return children[ind]
			} else if ind == -1 {
				return children[children.len - 1]
			} else {
				return error('$from uncorrect: $from[$i]=$ind out of bounds')
			}
		}
	}
}
