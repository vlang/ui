// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import eventbus
import gx

pub type BuildFn = fn (layout voidptr, win &Window)

pub type InitFn = fn (layout voidptr)

pub const (
	empty_stack           = stack(id: '_empty_stack_')
	scrollview_empty_rect = Rect{}
)

pub enum Direction {
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
* container_size is simply: (s.width, s.height)
* real_size (s.real_width, s.real_height) saves the real sizes
* adjusted_size is (s.adj_width, s.adj_height) corresponding of the compact/fitted size inherited from children sizes
* fixed_size (s.fixed_width, s.fixed_height) is the input size which is of higher priority with repect to adj_size
* size() returns (full) real_size, i.e. container_size + margin_size
* adj_size() returns (s.adj_width, s.adj_height)
* total_spacing() returns spacing
* free_size() returns free_size_direct and free_size_opposite (in the proper order) where:
	* free_size_direct = container_size - total_spacing()
	* free_size_opposite = container_size
N.B.:
	* direct size is the size in the main direction of the stack: height for .column and width  for .row
	* opposite size is the converse
***********************************/

[heap]
pub struct Stack {
	cache CachedSizes
pub mut:
	id                   string
	offset_x             int
	offset_y             int
	x                    int
	y                    int
	width                int
	height               int
	z_index              int
	deactivated          bool
	parent               Layout = ui.empty_stack
	ui                   &UI    = unsafe { nil }
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacings             []f32 // []int // int
	stretch              bool
	direction            Direction
	margins              Margins
	real_x               int = -1
	real_y               int = -1
	real_width           int
	real_height          int
	adj_width            int
	adj_height           int
	fixed_width          int
	fixed_height         int
	title                string
	// children related
	children              []Widget
	drawing_children      []Widget
	widths                []f32 // children sizes
	heights               []f32
	vertical_alignments   VerticalAlignments // Flexible alignments by index overriding alignment.
	horizontal_alignments HorizontalAlignments
	alignments            Alignments
	hidden                bool
	clipping              bool
	is_root_layout        bool = true
	// Style
	theme_style  string
	style        StackShapeStyle
	style_params StackStyleParams
	// text styles
	text_styles TextStyles
	// component state for composable widget
	component voidptr
	on_build  BuildFn
	on_init   InitFn
	// scrollview
	has_scrollview   bool
	scrollview       &ScrollView = unsafe { nil }
	on_scroll_change ScrollViewChangedFn = ScrollViewChangedFn(0)
	// debug stuff to be removed
	debug_ids          []string
	debug_children_ids []string
}

[params]
struct StackParams {
	StackStyleParams
	id                   string
	width                int // useful for root_layout to init size
	height               int
	vertical_alignment   VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacings             []f32 // Spacing = Spacing(0) // int
	spacing              f32
	stretch              bool
	direction            Direction
	margins              Margins
	// children related
	title                 string
	widths                []f32 // children sizes
	heights               []f32
	align                 Alignments
	vertical_alignments   VerticalAlignments
	horizontal_alignments HorizontalAlignments
	theme                 string = no_style
	scrollview            bool
	clipping              bool
	children              []Widget
}

fn stack(c StackParams) &Stack {
	// w, h := sizes_f32_to_int(c.width, c.height)
	mut s := &Stack{
		id: c.id
		height: c.height // become real_height
		width: c.width // become real_width
		vertical_alignment: c.vertical_alignment
		horizontal_alignment: c.horizontal_alignment
		spacings: c.spacings
		stretch: c.stretch
		direction: c.direction
		margins: c.margins
		children: c.children
		widths: c.widths
		heights: c.heights
		clipping: c.clipping
		vertical_alignments: c.vertical_alignments
		horizontal_alignments: c.horizontal_alignments
		alignments: c.align
		style_params: c.StackStyleParams
		title: c.title
		ui: 0
	}
	s.style_params.style = c.theme
	if c.width > 0 {
		s.fixed_width = c.width
	}
	if c.height > 0 {
		s.fixed_height = c.height
	}
	if c.scrollview {
		scrollview_add(mut s)
		// to restrict drawing to visible children
	}
	return s
}

fn (mut s Stack) build(win &Window) {
	// init for component
	if s.on_build != BuildFn(0) {
		s.on_build(s, win)
	}
}

pub fn (mut s Stack) init(parent Layout) {
	s.parent = parent
	mut ui := parent.get_ui()
	s.ui = ui
	s.init_size()
	s.load_style()
	// Init all children recursively
	for mut child in s.children {
		child.init(s)
	}
	// init for component attached to s when it is the layout of a component
	if s.on_init != InitFn(0) {
		s.on_init(s)
	}
	s.set_root_layout()
	if has_scrollview(s) {
		s.scrollview.init(parent)
		s.ui.window.evt_mngr.add_receiver(s, [events.on_scroll])
	} else {
		scrollview_delegate_parent_scrollview(mut s)
	}
	$if sscroll ? {
		swid := if s.scrollview != 0 { s.scrollview.widget.id } else { 'no' }
		println('${s.id} stack (parent) scrollview ${has_scrollview_or_parent_scrollview(s)} ${swid} (${parent.id})')
	}
}

// Determine wheither Stack s is a root layout
fn (mut s Stack) set_root_layout() {
	if mut s.parent is Window {
		// TODO: before removing line below test if this is necessary
		// s.ui.window = unsafe { s.parent }
		mut window := unsafe { s.parent }
		if s.is_root_layout {
			window.root_layout = s
			s.real_x, s.real_y = 0, 0
			// window.update_layout()
		} else {
			s.update_layout()
		}
	} else {
		s.is_root_layout = false
	}
}

[manualfree]
pub fn (mut s Stack) cleanup() {
	for mut child in s.children {
		child.cleanup()
	}
	unsafe {
		if s.has_scrollview {
			s.scrollview.cleanup()
		}
		s.free()
	}
}

[unsafe]
pub fn (s &Stack) free() {
	$if free ? {
		print('stack ${s.id}')
	}
	unsafe {
		// s.cache.free()
		s.id.free()
		s.spacings.free()
		s.title.free()
		s.children.free()
		s.drawing_children.free()
		s.widths.free()
		s.heights.free()
		// if s.has_scrollview {
		// 	s.scrollview.free()
		// }
		free(s)
	}
	$if free ? {
		println(' -> freed')
	}
}

// used inside window.update_layout()
pub fn (mut s Stack) update_layout() {
	// Only once for all children recursively
	// 1) find all the adjusted sizes
	s.set_adjusted_size(0, true, s.ui)
	// 2) set cache sizes
	s.set_cache_sizes()
	$if cache ? {
		debug_show_cache(mut s, 0, '')
	}
	// 3) set all the sizes (could be updated possibly for resizing)
	s.set_children_sizes()
	// All sizes have to be set before positionning widgets
	// 4) Set the position of this stack (anchor could possibly be defined inside set_pos later as suggested by Kahsa)
	s.update_pos()
	// 5) children z_index
	s.set_drawing_children()
	// 6) set position for chilfren
	s.set_children_pos()
	// 7) set the origin sizes for scrollview
	// scrollview_widget_set_orig_xy(s, true)
	scrollview_set_children_orig_xy(s, true)
	// 8) update_layout children if CanvasLayout or BoxLayout
	for mut child in s.children {
		if mut child is CanvasLayout {
			child.update_layout()
		} else if mut child is BoxLayout {
			child.update_layout()
		}
	}
	// Only wheither s is window.root_layout
	if s.is_root_layout {
		window := s.ui.window
		mut to_resize := window.mode in [.fullscreen, .max_size, .resizable]
		$if android {
			to_resize = true
		}
		if to_resize {
			s.resize(window.width, window.height)
		}
	}
}

pub fn (mut s Stack) update_layout_without_pos() {
	s.set_adjusted_size(0, true, s.ui)
	s.set_cache_sizes()
	s.set_children_sizes()
	// N.B.: s.update_pos() removed!
	s.set_drawing_children()
	s.set_children_pos()
}

fn (mut s Stack) init_size() {
	parent := s.parent
	parent_width, parent_height := parent.size()
	$if s_is ? {
		s.debug_ids = env('UI_IDS').split(',').clone()
		if s.id in s.debug_ids {
			println('parent size: ${s.id} (${parent_width}, ${parent_height}) root_layout? ${s.is_root_layout}')
			// debug_show_sizes(mut s, "decode before -> ")
		}
	}
	if s.is_root_layout {
		// Default: same as s.stretch == true
		if s.parent is SubWindow {
			$if s_is ? {
				if s.id in s.debug_ids {
					println('Init_size ${s.id}: ${s.width}, ${s.height} ${s.adj_size()}')
				}
			}
			s.real_width, s.real_height = s.adj_size()
		} else {
			s.real_height = parent_height
			s.real_width = parent_width
		}
	}
	scrollview_update(s)
	s.height = s.real_height - s.margin(.top) - s.margin(.bottom)
	s.width = s.real_width - s.margin(.left) - s.margin(.right)
}

fn (mut s Stack) set_children_sizes() {
	// size of children from
	c := unsafe { &s.cache }
	widths, heights := s.children_sizes()
	$if s_scs ? {
		s.debug_ids = env('UI_IDS').split(',').clone()
	}
	// set children sizes
	for i, mut child in s.children {
		mut w, mut h := child.size()
		if child is Stack || child is Group || child is CanvasLayout || child is BoxLayout {
			w, h = widths[i], heights[i]
		} else {
			if c.width_type[i] in [.fixed, .stretch, .weighted] {
				w = widths[i]
			}
			if c.height_type[i] in [.fixed, .stretch, .weighted] {
				h = heights[i]
			}
		}
		$if s_scs ? {
			if s.debug_ids.len == 0 || s.id in s.debug_ids {
				wt, ht := c.width_type[i].str(), c.height_type[i].str()
				println('scs (${s.id}): propose_size ${i}) ${child.id} (${child.type_name()}) (${wt}: ${w}, ${ht}:${h})')
			}
		}
		child.propose_size(w, h)

		if mut child is Stack {
			child.set_children_sizes()
		}
	}
	// Only for debug stuff
	$if s_scsd ? {
		if s.debug_ids.len == 0 || s.id in s.debug_ids {
			debug_set_children_sizes(s, widths, heights, c)
		}
	}
}

fn (mut s Stack) children_sizes() ([]int, []int) {
	mut mcw, mut mch := [0].repeat(s.children.len), [0].repeat(s.children.len)

	// free size without margin and spacing
	mut free_width, mut free_height := s.free_size()

	mut c := unsafe { &s.cache }

	// free_width -= c.fixed_width
	// free_height -= c.fixed_height

	$if s_cs ? {
		s.debug_ids = env('UI_IDS').split(',').clone()
		s.debug_children_ids = env('UI_CIDS').split(',').clone()

		if s.debug_ids.len == 0 || s.id in s.debug_ids {
			println('----------------------------------------')
			println('| First pass: children_size: ${s.id} s.widths:  ${s.widths} s.heights:  ${s.heights} ')
			println('|    width [weight: widths: ${c.weight_widths}, mass: ${c.width_mass}]  fixed: [widths: ${c.fixed_widths}, width: ${c.fixed_width}, min: ${c.min_width}]')
			println('|    height [weight: (heights: ${c.weight_heights}, mass: ${c.height_mass})]  fixed: [heights: ${c.fixed_heights}, height: ${c.fixed_height}, min: ${c.min_height}]')
			println('|    type (w: ${c.width_type}, h: ${c.height_type})')
			println('|    real size: (${s.real_width}, ${s.real_height}) free size: (w: ${free_width}, h: ${free_height})')
			println('| Parent: ${s.parent.id} Children: ${s.children.map(it.id)}')
			println('|---------------------------------------')
		}
	}

	// IMPORTANT: weighted sizes have to be substracted in free sizes.
	// So one needs a preliminary pass for weighted.
	for i, child in s.children {
		match c.width_type[i] {
			.weighted {
				mut weight := c.weight_widths[i]
				if child.z_index == z_index_hidden {
					weight = 0
				}
				mcw[i] = int(weight * f32(s.real_width))
				if s.direction == .row {
					free_width -= mcw[i]
				}
			}
			.compact, .fixed {
				if child.z_index != z_index_hidden {
					mcw[i] = c.fixed_widths[i]
				}
				if s.direction == .row {
					free_width -= mcw[i]
				}
			}
			else {}
		}

		match c.height_type[i] {
			.weighted {
				mut weight := c.weight_heights[i]
				if child.z_index == z_index_hidden {
					weight = 0
				}
				// println("$child.id mch= $weight * $s.real_height")
				mch[i] = int(weight * f32(s.real_height))
				if s.direction == .column {
					free_height -= mch[i]
				}
			}
			.compact, .fixed {
				if child.z_index != z_index_hidden {
					mch[i] = c.fixed_heights[i]
				}
				if s.direction == .column {
					free_height -= mch[i]
				}
			}
			else {}
		}
		$if s_cs ? {
			if (s.debug_ids.len == 0 || s.id in s.debug_ids)
				&& (s.debug_children_ids.len == 0 || child.id in s.debug_children_ids) {
				wt, ht := c.width_type[i].str(), c.height_type[i].str()
				println('| ${i}) ${child.id} ${child.type_name()} (${mcw[i]}, ${mch[i]}) typ: (${wt}, ${ht})')
				println('|----------------------------------------')
			}
		}
	}
	$if s_cs ? {
		if s.debug_ids.len == 0 || s.id in s.debug_ids {
			println('| Second pass:   real size: (${s.real_width}, ${s.real_height}) free size: (w: ${free_width}, h: ${free_height})')
		}
	}
	for i, child in s.children {
		match c.width_type[i] {
			.stretch {
				if s.direction == .row {
					weight := c.weight_widths[i] / c.width_mass
					mcw[i] = int(weight * f32(free_width))
				} else {
					mcw[i] = free_width
				}
			}
			.weighted {}
			.compact, .fixed {
				// mcw[i] = c.fixed_widths[i]
			}
			.weighted_stretch {
				weight := c.weight_widths[i] / c.width_mass
				mcw[i] = int(weight * free_width)
			}
		}

		match c.height_type[i] {
			.stretch {
				if s.direction == .column {
					weight := c.weight_heights[i] / c.height_mass
					mch[i] = int(weight * f32(free_height))
					$if s_cs ? {
						if (s.debug_ids.len == 0 || s.id in s.debug_ids)
							&& (s.debug_children_ids.len == 0 || child.id in s.debug_children_ids) {
							println('stretch: ${weight} (=${c.weight_heights[i]} / ${c.height_mass}) * ${free_height} = ${mch[i]}')
						}
					} $else {
					}
				} else {
					mch[i] = free_height
				}
			}
			.weighted {}
			.compact, .fixed {
				// mch[i] = c.fixed_heights[i]
			}
			.weighted_stretch {
				weight := c.weight_heights[i] / c.height_mass
				mch[i] = int(weight * f32(free_height))
			}
		}
		$if s_cs ? {
			if (s.debug_ids.len == 0 || s.id in s.debug_ids)
				&& (s.debug_children_ids.len == 0 || child.id in s.debug_children_ids) {
				wt, ht := c.width_type[i].str(), c.height_type[i].str()
				println('| ${i}) ${child.id} ${child.type_name()} (${mcw[i]}, ${mch[i]}) typ: (${wt}, ${ht})')
				println('|----------------------------------------')
			}
		}
	}
	return mcw, mch
}

fn (mut s Stack) set_cache_sizes() {
	//
	s.default_sizes()
	//
	len := s.children.len
	mut c := unsafe { &s.cache }
	// size preallocated
	c.fixed_width, c.fixed_height = 0, 0
	c.min_width, c.min_height = 0, 0
	c.width_mass, c.height_mass = 0.0, 0.0
	// fixed_<size>s and weight_<size>s are cached in the Stack struct as private fields
	// since once they are determined, they would never be updated
	// above all, they would be used when resizing
	c.adj_widths, c.adj_heights = [0].repeat(len), [0].repeat(len)
	c.fixed_widths, c.fixed_heights = [0].repeat(len), [0].repeat(len)
	c.weight_widths, c.weight_heights = [0.0].repeat(len), [0.0].repeat(len)
	c.width_type, c.height_type = [ChildSize.compact].repeat(len), [ChildSize.compact].repeat(len)

	$if s_scas ? {
		s.debug_ids = env('UI_IDS').split(',').clone()
	}

	for i, mut child in s.children {
		mut cw := s.widths[i] or { 0.0 }
		mut ch := s.heights[i] or { 0.0 }

		// adjusted (natural size) child size
		mut adj_child_width, mut adj_child_height := child.size()

		if mut child is Stack {
			adj_child_width, adj_child_height = child.adj_size()
		}

		if mut child is Group {
			adj_child_width, adj_child_height = child.adj_size()
		}

		$if s_scas ? {
			if s.debug_ids.len == 0 || s.id in s.debug_ids {
				println('scas (${s.id}): ${i}) adj_child (${child.id}, ${child.type_name()}) size -> (${adj_child_width}, ${adj_child_height}) cw, ch = ${cw}, ${ch}')
			}
		}

		// fix compact when child has size 0
		if adj_child_width == 0 && cw == compact {
			if child !is Stack {
				s.widths[i] = stretch
				cw = stretch
			}
		}
		if adj_child_height == 0 && ch == compact {
			if child !is Stack {
				s.heights[i] = stretch
				ch = stretch
			}
		}

		$if s_scas ? {
			if s.debug_ids.len == 0 || s.id in s.debug_ids {
				println('scas (${s.id}): ${i}) cw, ch = ${cw}, ${ch}')
			}
		}

		// cw as child width with type f64
		if cw > 1 {
			c.width_type[i] = .fixed
			c.fixed_widths[i] = int(cw)
			if s.direction == .row { // sum rule
				c.fixed_width += c.fixed_widths[i]
				c.min_width += c.fixed_widths[i]
			} else { // max rule
				if c.fixed_widths[i] > c.fixed_width {
					c.fixed_width = c.fixed_widths[i]
				}
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else if cw > 0 {
			// weighted size
			c.width_type[i] = .weighted
			c.weight_widths[i] = cw
			// Internally, fixed_widths[i] is set to minimal fixed size
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row { // sum rule
				// c.width_mass += cw
				c.min_width += c.fixed_widths[i]
			} else { // max rule
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else if cw == 0 {
			// width for Widget and adj_width for Layout
			c.width_type[i] = .compact
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row { // sum rule
				c.fixed_width += c.fixed_widths[i]
				c.min_width += c.fixed_widths[i]
			} else { // max rule
				if c.fixed_widths[i] > c.fixed_width {
					c.fixed_width = c.fixed_widths[i]
				}
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else if cw >= -1 {
			// weight_widths means that the children can have their size updated from the parent
			// even reducing their size!!!
			c.width_type[i] = .weighted_stretch
			c.weight_widths[i] = -cw
			// This is the initial size
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row { // sum rule
				c.width_mass += c.weight_widths[i]
				c.min_width += c.fixed_widths[i]
			} else { // max rule
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		} else { // with stretch == -10000.0 it's impossible to have stretch * weight >= -1
			c.width_type[i] = .stretch
			if child.z_index == z_index_hidden {
				cw = 0
			}
			c.weight_widths[i] = cw / stretch
			c.fixed_widths[i] = adj_child_width
			if s.direction == .row { // sum rule
				c.width_mass += c.weight_widths[i]
				c.min_width += c.fixed_widths[i]
			} else { // max rule
				if c.fixed_widths[i] > c.min_width {
					c.min_width = c.fixed_widths[i]
				}
			}
		}

		// ch as child height with type f64
		if ch > 1 {
			// fixed size ?
			c.height_type[i] = .fixed
			c.fixed_heights[i] = int(ch)
			if s.direction == .column { // sum rule
				c.fixed_height += c.fixed_heights[i]
				c.min_height += c.fixed_heights[i]
			} else { // max rule
				if c.fixed_heights[i] > c.fixed_height {
					c.fixed_height = c.fixed_heights[i]
				}
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else if ch > 0 {
			// weighted size
			c.height_type[i] = .weighted
			c.weight_heights[i] = ch
			// Internally, fixed_heights[i] is set to minimal fixed size
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column { // sum rule
				// c.height_mass += ch
				c.min_height += c.fixed_heights[i]
			} else { // max rule
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else if ch == 0 {
			// height for Widget and adj_height for Layout
			c.height_type[i] = .compact
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column { // sum rule
				c.fixed_height += c.fixed_heights[i]
				c.min_height += c.fixed_heights[i]
			} else { // max rule
				if c.fixed_heights[i] > c.fixed_height {
					c.fixed_height = c.fixed_heights[i]
				}
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else if ch >= -1 {
			// weight_heights now  means that the children can have their size updated from the parent
			// even reducing their size!!!
			c.height_type[i] = .weighted_stretch
			c.weight_heights[i] = -cw
			// This is the initial size
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column { // sum rule
				c.height_mass += c.weight_heights[i]
				c.min_height += c.fixed_heights[i]
			} else { // max rule
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		} else { // with stretch == -10000.0 it's impossible to have stretch * weight >= -1
			c.height_type[i] = .stretch
			if child.z_index == z_index_hidden {
				ch = 0
			}
			c.weight_heights[i] = ch / stretch
			c.fixed_heights[i] = adj_child_height
			if s.direction == .column { // sum rule
				c.height_mass += c.weight_heights[i]
				c.min_height += c.fixed_heights[i]
			} else { // max rule
				if c.fixed_heights[i] > c.min_height {
					c.min_height = c.fixed_heights[i]
				}
			}
		}
		// recursively do the same for Stack children
		if mut child is Stack {
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

pub fn (s &Stack) adj_size() (int, int) {
	$if s_as ? {
		mut s2 := s
		s2.debug_ids = env('UI_IDS').split(',').clone()
		if s2.debug_ids.len == 0 || s2.id in s.debug_ids {
			println('adj_size ${s.id}: fixed: (${s.fixed_width}, ${s.fixed_height}) adj: (${s.adj_width}, ${s.adj_height}) ')
		}
	}
	return if s.fixed_width != 0 { s.fixed_width } else { s.adj_width }, if s.fixed_height != 0 {
		s.fixed_height
	} else {
		s.adj_height
	}
}

pub fn (mut s Stack) propose_size(w int, h int) (int, int) {
	$if sps ? {
		s.debug_ids = env('UI_IDS').split(',').clone()
		if s.debug_ids.len == 0 || s.id in s.debug_ids {
			println('propose_size ${s.id} : (${w}, ${h}) from ${s.parent.id}')
		}
	}
	s.real_width, s.real_height = w, h
	s.width, s.height = w - s.margin(.left) - s.margin(.right), h - s.margin(.top) - s.margin(.bottom)

	// println("${s.id} propose size ${w}, ${h} => ${s.width}, ${s.height} ")

	scrollview_update(s)
	return s.real_width, s.real_height
}

pub fn (s &Stack) size() (int, int) {
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

fn (mut s Stack) set_adjusted_size(i int, force bool, gui &UI) {
	mut h := 0
	mut w := 0
	// Comment/uncomment
	$if s_adj_size ? {
		s.debug_ids = env('UI_IDS').split(',').clone()
	}
	for mut child in s.children {
		$if s_adj_size ? {
			if s.debug_ids.len == 0 || s.id in s.debug_ids {
				println('set_adj_size ${child.id}) z_index:  ${child.z_index} > ${z_index_hidden}')
			}
		}
		if child.z_index > z_index_hidden { // taking into account only visible widgets
			mut child_width, mut child_height := 0, 0
			if mut child is Stack {
				if force || child.adj_width == 0 {
					$if s_adj_size ? {
						if s.debug_ids.len == 0 || s.id in s.debug_ids {
							println('set_adj_size : stack ${child.id} set_adjusted_size(${i + 1}, ${force}, gui)')
						}
					}
					child.set_adjusted_size(i + 1, force, gui)
				}
				child_width, child_height = child.adj_width + child.margin(.left) +
					child.margin(.right), child.adj_height + child.margin(.top) +
					child.margin(.bottom)
				$if s_adj_size ? {
					if s.debug_ids.len == 0 || s.id in s.debug_ids {
						println('set_adj_size ${s.id} (stack): child(${child.id}}) child_width = ${child_width} (=${child.adj_width} + ${child.margin(.left)} + ${child.margin(.right)})')
						println('                      child(${child.id}) child_height = ${child_height} (=${child.adj_height} + ${child.margin(.top)} + ${child.margin(.bottom)})')
					}
				} $else {
				} // because of a bug mixing $if and else
			} else if mut child is Group {
				if force || child.adj_width == 0 {
					child.set_adjusted_size(i + 1, gui)
				}
				child_width, child_height = child.adj_width + child.margin_left + child.margin_right,
					child.adj_height + child.margin_top + child.margin_bottom
				$if s_adj_size ? {
					if s.debug_ids.len == 0 || s.id in s.debug_ids {
						println('set_adj_size ${s.id} (group): child(${child.id}) child_width = ${child_width}  child_height = ${child_height})')
					}
				} $else {
				} // because of a bug mixing $if and else
			} else if mut child is CanvasLayout {
				if force || child.adj_width == 0 {
					child.set_adjusted_size(gui)
				}
				child_width, child_height = child.adj_width, child.adj_height
				$if s_adj_size ? {
					if s.debug_ids.len == 0 || s.id in s.debug_ids {
						println('set_adj_size ${s.id} (cvl): child(${child.id}) child_width = ${child_width}  child_height = ${child_height})')
					}
				}
				//$else {
				//} // because of a bug mixing $if and else
			} else {
				child_width, child_height = child.size()
				$if s_adj_size ? {
					if s.debug_ids.len == 0 || s.id in s.debug_ids {
						println('set_adj_size ${s.id} (widget): child (${child.id}) size ${child.type_name()}: (${child_width}, ${child_height}) ')
					}
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
	}
	$if s_adj_size ? {
		if s.debug_ids.len == 0 || s.id in s.debug_ids {
			println('set_adj_size (${s.id}) (before spacing): (${w}, ${h})')
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
	$if s_adj_size ? {
		if s.debug_ids.len == 0 || s.id in s.debug_ids {
			println('set_adj_size (${s.id}) end: (${s.adj_width}, ${s.adj_height}) vs real: (${s.width}, ${s.height})')
		}
	}
}

fn (mut s Stack) update_pos() {
	$if poss ? {
		println('update_pos(${s.id}):  $(${s.real_x}, ${s.real_y}) + (${s.margin(.left)}, ${s.margin(.top)})')
	}
	s.x = s.real_x + s.margin(.left)
	s.y = s.real_y + s.margin(.top)
}

pub fn (mut s Stack) set_pos(x int, y int) {
	scrollview_widget_save_offset(s)
	if s.real_x != x || s.real_y != y {
		// could depend on anchor in the future
		// Default is anchor=.top_left here (and could be .top_right, .bottom_left, .bottom_right)
		$if stack_pos ? {
			println('set_pos(${s.id}): $(${x}, ${y})')
		}
		s.real_x, s.real_y = x, y
	}
	s.update_pos()
	scrollview_widget_restore_offset(s, true)
}

pub fn (mut s Stack) set_children_pos() {
	mut x := s.x
	mut y := s.y
	$if scp ? {
		println('Stack  ${s.id} pos: (${x}, ${y})')
	}
	// z_index < ui.z_index_ hidden => hidden and without positionning
	mut children := s.children.filter(it.z_index > z_index_hidden)
	for i, mut child in children {
		child_width, child_height := child.size()
		s.set_child_pos(mut child, i, x, y)
		if s.direction == .row {
			$if scp ? {
				println('$.row ${i}): child_width=${child_width} x => ${x}')
			}
			x += child_width
			if i < s.children.len - 1 {
				x += s.spacing(i)
				$if scp ? {
					println('spacing(${i}): ${s.spacing(i)} x => ${x}')
				}
			}
		} else {
			$if scp ? {
				println('$.column ${i}): child_height=${child_height} y => ${y}')
			}
			y += child_height
			if i < s.children.len - 1 {
				y += s.spacing(i)
			}
		}
		if mut child is Stack {
			child.set_children_pos()
		} else if mut child is CanvasLayout {
			child.set_children_pos()
		} else if mut child is BoxLayout {
			child.set_children_pos()
		}
	}
}

fn (s &Stack) set_child_pos(mut child Widget, i int, x int, y int) {
	// IMPORT1NT: THIS NEEDS TO BE REDESIGNED!!!!
	// 1) there is AdjustableWidget
	// 2) there is alignment
	// => THIS IS CONFUSING SINCE IT DOES THE SAME THING
	// N.B.: AdjsuatbleWidget is less intrusive since (ax, ay) are completing (x,y)
	// As first I would remove alignment system since it modifies (x, y)

	// Only alignment along the opposite direction (ex: .row if direction is .column and vice-versa) is considered
	// TODO: alignment in the direct direction
	// (for these different cases, container size in the direct direction is more complicated to compute)
	$if scp ? {
		println('set_child_pos: ${i}) ${typeof(s).name}-${child.type_name()}')
	}
	mut aw, mut ah := 0.0, 0.0
	aw = match s.get_horizontal_alignment(i) {
		.left {
			0.0
		}
		.center {
			0.5
		}
		.right {
			1.0
		}
	}
	ah = match s.get_vertical_alignment(i) {
		.top {
			0.0
		}
		.center {
			0.5
		}
		.bottom {
			1.0
		}
	}
	offset_x, offset_y := get_align_offset_from_parent(mut child, aw, ah)

	if mut child is AdjustableWidget {
		mut w := child as AdjustableWidget
		// println('$child.id: $x + $offset_x, $y + $offset_y')
		w.set_adjusted_pos(x + offset_x, y + offset_y)
	} else {
		$if scp ? {
			if child.id in env('UI_IDS').split(',') {
				println('${child.id}: ${x} + ${offset_x}, ${y} + ${offset_y}')
			}
		}
		child.set_pos(x + offset_x, y + offset_y)
	}
}

fn (s &Stack) get_subscriber() &eventbus.Subscriber {
	parent := s.parent
	return parent.get_subscriber()
}

pub fn (mut s Stack) set_children_visible(state bool, children ...int) {
	for i, mut child in s.children {
		if i in children {
			child.set_visible(state)
		}
	}
	s.set_drawing_children()
}

pub fn (mut s Stack) set_children_depth(z_index int, children ...int) {
	for i, mut child in s.children {
		if i in children {
			child.z_index = z_index
		}
	}
	s.set_drawing_children()
}

pub fn (mut s Stack) set_drawing_children() {
	for mut child in s.children {
		if mut child is Stack {
			if child.z_index > z_index_hidden {
				child.set_drawing_children()
			}
		} else if mut child is CanvasLayout {
			if child.z_index > z_index_hidden {
				child.set_drawing_children()
			}
		} else if mut child is BoxLayout {
			if child.z_index > z_index_hidden {
				child.set_drawing_children()
			}
		}
		// println("z_index: ${child.type_name()} $child.z_index")
		if child.z_index > s.z_index {
			s.z_index = child.z_index - 1
		}
	}
	s.drawing_children = s.children.filter(!it.hidden && it.z_index > z_index_hidden)
	s.sorted_drawing_children()
}

fn (mut s Stack) draw() {
	s.draw_device(mut s.ui.dd)
}

fn (mut s Stack) draw_device(mut d DrawDevice) {
	if s.hidden {
		return
	}
	offset_start(mut s)
	defer {
		offset_end(mut s)
	}
	cstate := clipping_start(s, mut d) or { return }
	defer {
		clipping_end(s, mut d, cstate)
	}

	$if layout ? {
		if s.ui.layout_print {
			println('Stack(${s.id}): (${s.real_x}, ${s.real_y}, ${s.real_width}, ${s.real_height})')
		}
	}
	if s.style.bg_color != no_color {
		if s.style.bg_radius > 0 {
			radius := relative_size(s.style.bg_radius, s.real_width, s.real_height)
			d.draw_rounded_rect_filled(s.real_x, s.real_y, s.real_width, s.real_height,
				radius, s.style.bg_color)
		} else {
			// println("$s.id ($s.real_x, $s.real_y, $s.real_width, $s.real_height), $s.bg_color")
			d.draw_rect_filled(s.real_x, s.real_y, s.real_width, s.real_height, s.style.bg_color)
		}
	}
	scrollview_draw_begin(mut s, d)
	defer {
		scrollview_draw_end(s, d)
	}

	$if bb ? {
		debug_draw_bb_stack(s)
	}
	//$if sdraw_scroll ? {
	//	if Layout(s).has_scrollview_or_parent_scrollview() {
	//		// if s.scrollview != 0 {
	//		for i, mut child in s.drawing_children {
	//			if mut child !is Layout
	//				&& is_empty_intersection(s.scrollview.scissor_rect, child.bounds()) {
	//				sr := s.scrollview.scissor_rect
	//				cr := child.bounds()
	//				println('sdraw ${s.id} (${sr.x}, ${sr.y}, ${sr.width}, ${sr.height})  ${i}) ${child.type_name()} ${child.id} (${cr.x}, ${cr.y}, ${cr.width}, ${cr.height}) clipped')
	//			}
	//		}
	//	}
	//}

	$if s_draw_children ? {
		println('draw ${s.id}: ${s.children.map(it.id)} ${s.drawing_children.map(it.id)} ${s.drawing_children.map(it.z_index)}')
	}
	// REMARK: DO NOT REMOVE -> not used maybe update later
	// active_scrollview := Layout(s).has_scrollview_or_parent_scrollview() && scrollview_is_active(s)
	for mut child in s.drawing_children {
		// println("$child.type_name() $child.id")
		// if active_scrollview {
		// 	// TODO: calculate whether child falls outside clipping rect and
		// 	// continue (i.e., skip child drawing)
		// 	// if mut child is Layout
		// 	//	|| !is_empty_intersection(s.scrollview.scissor_rect, child.bounds()) {
		// 	//	child.draw_device(mut d)
		// 	//}
		// }
		child.draw_device(mut d)
	}

	// if Layout(s).has_scrollview_or_parent_scrollview() && scrollview_is_active(s) {
	//	// if s.scrollview != 0 {
	//	for mut child in s.drawing_children {
	//		// Widget(s).debug_gg_rect(s.scrollview.scissor_rect, gx.red)
	//		// Widget(s).debug_gg_rect(child.bounds(), gx.green)
	//		if mut child is Layout
	//			|| !is_empty_intersection(s.scrollview.scissor_rect, child.bounds()) {
	//			child.draw_device(mut d)
	//		}
	//	}
	//} else {
	//	$if s_draw_children ? {
	//		println('draw ${s.id}: ${s.drawing_children.map(it.id)} ${s.drawing_children.map(it.z_index)}')
	//	}
	//	for mut child in s.drawing_children {
	//		// println("$child.type_name() $child.id")
	//		child.draw_device(mut d)
	//	}
	//}

	// DO NOT REMOVE: test first if defer is working
	// scrollview_draw_end(s, d)
	if s.title != '' {
		text_width, text_height := s.ui.dd.text_size(s.title)
		// draw rectangle around stack
		d.draw_rect_empty(s.x - text_height / 2, s.y - text_height / 2, s.real_width + text_height,
			s.real_height + int(f32(text_height) * .75), gx.black)
		// draw mini frame
		tx := s.x + s.real_width / 2 - text_width / 2 - 3
		ty := s.y - int(f32(text_height) * 1.25)
		d.draw_rect_filled(tx, ty, text_width + 5, text_height, s.style.bg_color)
		d.draw_rect_empty(tx, ty, text_width + 5, text_height, gx.black)
		mut dtw := DrawTextWidget(s)
		dtw.draw_device_load_style(d)
		dtw.draw_device_text(d, tx, ty - 2, s.title)
	}
}

fn (s &Stack) margin(side Side) int {
	size := match side {
		.top { s.margins.top }
		.right { s.margins.right }
		.bottom { s.margins.bottom }
		.left { s.margins.left }
	}
	mut isize := int(size)
	if 0.0 < size && size < 1.0 {
		psize := if side in [.left, .right] { s.real_width } else { s.real_height }
		$if margin ? {
			println('margin(${side}) = ${size} * ${psize}')
		}
		isize = int(size * f32(psize))
	}
	$if margin ? {
		println('margin(${side}) = ${isize}')
	}
	if s.title != '' {
		text_height := s.ui.dd.text_height(s.title)
		match side {
			.top { isize += int(f32(text_height) * 1.25) }
			.bottom { isize += int(f32(text_height) * 0.75) }
			else { isize += text_height / 2 }
		}
	}
	return isize
}

fn (s &Stack) spacing(i int) int {
	size := s.spacings[i]
	mut isize := int(size)
	if 0.0 < size && size < 1.0 {
		psize := if s.direction == .row { s.real_width } else { s.real_height }
		$if spacing ? {
			println('spacing(${i}) = ${size} * ${psize}')
		}
		isize = int(size * f32(psize))
	}
	$if spacing ? {
		println('spacing(${i}) = ${isize}')
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

pub fn (s &Stack) point_inside(x f64, y f64) bool {
	return scrollview_widget_point_inside(s, x, y)
}

pub fn (mut s Stack) set_visible(state bool) {
	s.hidden = !state
	for mut child in s.children {
		child.set_visible(state)
	}
}

fn (mut s Stack) resize(width int, height int) {
	s.init_size()
	s.update_pos()
	// scrollview_widget_set_orig_xy(s, false)
	// scrollview_set_children_orig_xy(s, false)
	s.set_children_sizes()
	s.set_children_pos()
	// println("RESIZE: $width, $height")
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

// fn (s &Stack) set_child_pos_aligned(mut child Widget, i int, x int, y int) {
// 	child_width, child_height := child.size()
// 	horizontal_alignment, vertical_alignment := s.get_alignments(i)
// 	// set x_offset
// 	container_width := s.width
// 	mut x_offset := 0
// 	match horizontal_alignment {
// 		.left {
// 			x_offset = 0
// 		}
// 		.center {
// 			if container_width > child_width {
// 				x_offset = (container_width - child_width) / 2
// 			} else {
// 				x_offset = 0
// 			}
// 		}
// 		.right {
// 			if container_width > child_width {
// 				x_offset = (container_width - child_width)
// 			} else {
// 				x_offset = 0
// 			}
// 		}
// 	}
// 	// set y_offset
// 	container_height := s.height
// 	mut y_offset := 0
// 	match vertical_alignment {
// 		.top {
// 			y_offset = 0
// 		}
// 		.center {
// 			if container_height > child_height {
// 				y_offset = (container_height - child_height) / 2
// 			} else {
// 				y_offset = 0
// 			}
// 		}
// 		.bottom {
// 			if container_height > child_height {
// 				y_offset = container_height - child_height
// 			} else {
// 				y_offset = 0
// 			}
// 		}
// 	}
// 	child.set_pos(x + x_offset, y + y_offset)
// }

// fn (s &Stack) get_alignments(i int) (HorizontalAlignment, VerticalAlignment) {
// 	mut hor_align := s.horizontal_alignment
// 	mut ver_align := s.vertical_alignment
// 	if i in s.alignments.center {
// 		hor_align, ver_align = .center, .center
// 	} else if i in s.alignments.left_top {
// 		hor_align, ver_align = .left, .top
// 	} else if i in s.alignments.top {
// 		hor_align, ver_align = .center, .top
// 	} else if i in s.alignments.right_top {
// 		hor_align, ver_align = .right, .top
// 	} else if i in s.alignments.right {
// 		hor_align, ver_align = .right, .center
// 	} else if i in s.alignments.right_bottom {
// 		hor_align, ver_align = .right, .bottom
// 	} else if i in s.alignments.bottom {
// 		hor_align, ver_align = .center, .bottom
// 	} else if i in s.alignments.left_bottom {
// 		hor_align, ver_align = .left, .bottom
// 	} else if i in s.alignments.left {
// 		hor_align, ver_align = .left, .center
// 	}

// 	return hor_align, ver_align
// }

//**** ChildrenParams *****
[params]
pub struct ChildrenParams {
mut:
	// add or remove or migrate
	at      int  = -1
	widths  Size = Size(-1.0)
	heights Size = Size(-1.0)
	// add or move or migrate
	spacing  f64    = -1.0
	spacings []f64  = []f64{}
	child    Widget = ui.empty_stack
	children []Widget
	// move or migrate
	from int = -1
	to   int = -1
	// migrate
	target          &Stack = unsafe { nil }
	target_widths   Size   = Size(-1.0)
	target_heights  Size   = Size(-1.0)
	target_spacing  f64    = -1.0
	target_spacings []f64  = []f64{}
}

pub fn (mut s Stack) add(cfg_ ChildrenParams) {
	mut cfg := cfg_
	pos := if cfg.at == -1 { s.children.len } else { cfg.at }
	if 0 <= pos && pos <= s.children.len {
		if cfg.children.len > 0 {
			s.children.insert(pos, cfg.children)
			for mut w in cfg.children {
				w.init(s)
				s.register_child(*w)
			}
		} else {
			s.children.insert(pos, cfg.child)
			cfg.child.init(s)
			s.register_child(cfg.child)
		}
		s.update_widths(cfg, .add)
		s.update_heights(cfg, .add)
		s.update_spacings(cfg, .add)
		window := s.ui.window
		window.update_layout()
	}
}

pub fn (mut s Stack) remove(cfg ChildrenParams) {
	pos := if cfg.at == -1 { s.children.len - 1 } else { cfg.at }
	if 0 <= pos && pos < s.children.len {
		// mut children := []Widget{}
		// for i, child in s.children {
		// 	if i != pos {
		// 		children << child
		// 	}
		// }
		// s.children = children

		// set child hidden
		mut child := s.children[pos]
		child.set_visible(false)
		child.cleanup()
		// delete child in the children tree
		s.children.delete(pos)
		s.update_widths(cfg, .remove)
		s.update_heights(cfg, .remove)
		s.update_spacings(cfg, .remove)
		window := s.ui.window
		window.update_layout()
	}
}

pub fn (mut s Stack) move(cfg ChildrenParams) {
	if unsafe { cfg.target == 0 } {
		// move (inside same stack s)
		from_pos := if cfg.from == -1 { s.children.len - 1 } else { cfg.from }
		mut to_pos := if cfg.to == -1 { s.children.len } else { cfg.to }
		if 0 <= from_pos && from_pos < s.children.len && 0 <= to_pos && to_pos <= s.children.len {
			if from_pos < to_pos {
				to_pos--
			}
			mut child := s.children[from_pos]
			// remove
			s.children.delete(from_pos)
			// add the new one
			s.children.insert(to_pos, child)
			window := s.ui.window
			window.update_layout()
		}
	} else {
		// migration from stack s to other stack cfg.target
		mut target_s := cfg.target
		from_pos := if cfg.from == -1 { s.children.len - 1 } else { cfg.from }
		target_pos := if cfg.to == -1 { target_s.children.len } else { cfg.to }
		if 0 <= from_pos && from_pos < s.children.len && 0 <= target_pos
			&& target_pos <= target_s.children.len {
			println('migrate from ${from_pos} to ${target_pos}')
			child := s.children[from_pos]
			// remove
			s.children.delete(from_pos)
			s.update_widths(cfg, .remove)
			s.update_heights(cfg, .remove)
			s.update_spacings(cfg, .remove)
			// add the new one
			target_s.children.insert(target_pos, child)
			target_s.update_widths(cfg, .migrate)
			target_s.update_heights(cfg, .migrate)
			target_s.update_spacings(cfg, .migrate)
			window := s.ui.window
			window.update_layout()
		}
	}
}

enum ChildUpdateType {
	add
	remove
	move
	migrate
}

pub fn (mut s Stack) update_widths(cfg ChildrenParams, mode ChildUpdateType) {
	cfg_widths := if mode == .migrate { cfg.target_widths } else { cfg.widths }
	if cfg_widths is f64 {
		if cfg_widths == -1.0 {
			match mode {
				.add, .migrate {
					widths := if s.direction == .row { compact } else { stretch }
					s.widths = Size(widths).as_f32_array(s.children.len)
				}
				.remove {
					if s.children.len == 0 {
						s.widths = []f32{}
					} else {
						pos := if cfg.at == -1 { s.children.len } else { cfg.at }
						s.widths.delete(pos)
					}
				}
				.move {}
			}
		} else {
			s.widths = [f32(cfg_widths)].repeat(s.children.len)
		}
	} else {
		s.widths = cfg_widths.as_f32_array(s.children.len)
	}
}

pub fn (mut s Stack) update_heights(cfg ChildrenParams, mode ChildUpdateType) {
	cfg_heights := if mode == .migrate { cfg.target_heights } else { cfg.heights }
	if cfg_heights is f64 {
		if cfg_heights == -1.0 {
			match mode {
				.add, .migrate {
					heights := if s.direction == .row { stretch } else { compact }
					s.heights = Size(heights).as_f32_array(s.children.len)
				}
				.remove {
					if s.children.len == 0 {
						s.heights = []f32{}
					} else {
						pos := if cfg.at == -1 { s.children.len } else { cfg.at }
						s.heights.delete(pos)
					}
				}
				.move {}
			}
		} else {
			s.heights = [f32(cfg_heights)].repeat(s.children.len)
		}
	} else {
		s.heights = cfg_heights.as_f32_array(s.children.len)
	}
}

pub fn (mut s Stack) update_spacings(cfg ChildrenParams, mode ChildUpdateType) {
	cfg_spacing := if mode == .migrate { cfg.target_spacing } else { cfg.spacing }
	cfg_spacings := if mode == .migrate { cfg.target_spacings } else { cfg.spacings }
	if cfg_spacing != -1.0 || cfg_spacings.len != 0 {
		if s.children.len > 0 {
			s.spacings = spacings(cfg_spacing, cfg_spacings, s.children.len - 1)
		}
	} else {
		match mode {
			.add, .migrate {
				// TODO: to improve
				if s.children.len <= 1 {
					s.spacings = []f32{}
				} else {
					spacing := if s.spacings.len == 0 { f32(5.0) } else { s.spacings[0] }
					s.spacings = spacings(spacing, cfg_spacings, s.children.len - 1)
				}
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

pub fn (s &Stack) child(from ...int) Widget {
	if from.len > 0 {
		mut children := s.children.clone()
		for i, ind in from {
			if i < from.len - 1 {
				if ind >= 0 && ind < children.len {
					widget := children[ind]
					if widget is Stack {
						children = widget.children.clone()
					} else {
						eprintln('(ui warning) ${from} uncorrect: ${from}[${i}]=${ind} does not correspond to a Layout')
					}
				} else if i == -1 {
					widget := children[children.len - 1]
					if widget is Stack {
						children = widget.children.clone()
					}
				} else {
					eprintln('(ui warning) ${from} uncorrect: ${from}[${i}]=${ind} out of bounds')
				}
			} else {
				if ind >= 0 && ind < children.len {
					return children[ind]
				} else if ind == -1 {
					return children[children.len - 1]
				} else {
					eprintln('(ui warning) ${from} uncorrect: ${from}[${i}]=${ind} out of bounds')
				}
			}
		}
	}
	// by default returns s itself
	return s
}

pub fn (mut s Stack) transpose(size bool) {
	if s.direction == .row {
		s.direction = .column
	} else {
		s.direction = .row
	}
	if size {
		s.widths, s.heights = s.heights, s.widths
	}
}

fn (mut s Stack) register_child(child Widget) {
	mut window := s.ui.window
	window.register_child(child)
}

pub fn (s &Stack) child_index_by_id(id string) int {
	for i, child in s.children {
		if child.id() == id {
			return i
		}
	}
	return -1
}

// method implemented in Draggable
fn (s &Stack) get_window() &Window {
	return s.ui.window
}
