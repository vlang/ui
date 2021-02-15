module ui

import gx

// Draw bounding box for Stack
fn (s &Stack) draw_bb() {
	mut col := gx.red
	if s.direction == .row {
		col = gx.green
	}
	w, h := s.size()
	s.ui.gg.draw_empty_rect(s.x - s.margin.left, s.y - s.margin.top, w, h, col)
	s.ui.gg.draw_empty_rect(s.x, s.y, w - s.margin.left - s.margin.right, h - s.margin.top - s.margin.bottom,
		col)
}

// Debug function
fn (mut s Stack) debug_show_cache(depth int, txt string) {
	if depth == 0 {
		println('Show cache =>')
	}
	$if bbd ? {
		w, h := s.size()
		println("BB ${s.name()}: ")
		println("  (s.x:$s.x - s.margin.left:$s.margin.left, s.y:$s.y - s.margin.top:$s.margin.top, w:$w, h:$h)")
		println("  (s.x:$s.x, s.y:$s.y, w:$w - s.margin.left:$s.margin.left - s.margin.right:$s.margin.right, h:$h - s.margin.top:$s.margin.top - s.margin.ttom:$s.margin.bottom)")
	}
	tab := '  '.repeat(depth)
	println('$tab ($depth) Stack $s.name() with $s.children.len children: ($s.cache.fixed_widths.len, $s.cache.fixed_heights.len)')
	free_width, free_height := s.free_size()
	println('$tab   free size: ($free_width, $free_height)')
	println('$tab   types: (${s.cache.width_type},${s.cache.height_type})')
	widths, heights := s.children_sizes()
	println(txt)
	for i, mut child in s.children {
		if child is Stack {
			mut tmp := '$tab      ($depth-$i) $child.name() :'
			tmp += '\n$tab      fixed(${s.cache.fixed_widths[i]},${s.cache.fixed_heights[i]}) weight: (${s.cache.weight_widths[i]},${s.cache.weight_heights[i]})'
			tmp += '\n$tab      size: (${widths[i]},${heights[i]})'
			child.debug_show_cache(depth + 1, tmp)
		} else {
			w, h := child.size()
			println('$tab      ($depth-$i) Widget $child.name() size($w, $h) fixed(${s.cache.fixed_widths[i]},${s.cache.fixed_heights[i]}) weight(${s.cache.weight_widths[i]},${s.cache.weight_heights[i]})')
		}
	}
}

fn (s &Stack) debug_show_size(t string) {
	print('${t}size of Stack $s.name()')
	C.printf(' %p: ', s)
	println(' ($s.width, $s.height)')
}

fn (s &Stack) debug_show_sizes(t string) {
	parent := s.parent
	sw, sh := s.size()
	print('${t}Stack $s.name()')
	C.printf(' %p', s)
	println(' => size ($sw, $sh), ($s.width, $s.height)  adj: ($s.adj_width, $s.adj_height) spacing: $s.spacing')
	if parent is Stack {
		print('	parent: $parent.name() ')
		C.printf(' %p', parent)
		println('=> size ($parent.width, $parent.height)  adj: ($parent.adj_width, $parent.adj_height) spacing: $parent.spacing')
	} else if parent is Window {
		println('	parent: Window => size ($parent.width, $parent.height)  adj: ($parent.adj_width, $parent.adj_height) ')
	}
	for i, child in s.children {
		w, h := child.size()
		print('		$i) $child.name()')
		C.printf(' %p', child)
		println(' size => $w, $h')
	}
}

// Mainly useful for debugging
pub fn (w &Stack) name() string {
	return if w.direction == .row { 'Row' } else { 'Column' }
}

pub fn (w &Group) name() string {
	return 'Group'
}

pub fn (w &TextBox) name() string {
	return 'TextBox'
}

pub fn (w &ListBox) name() string {
	return 'ListBox'
}

pub fn (w &Label) name() string {
	return 'Label'
}

pub fn (w &Radio) name() string {
	return 'Radio'
}

pub fn (w &Canvas) name() string {
	return 'Canvas'
}

pub fn (w &ProgressBar) name() string {
	return 'ProgressBar'
}

pub fn (w &Button) name() string {
	return 'Button'
}

pub fn (w &Rectangle) name() string {
	return 'Rectangle'
}

pub fn (w &Switch) name() string {
	return 'Switch'
}

pub fn (w &Transition) name() string {
	return 'Transition'
}

pub fn (w &Dropdown) name() string {
	return 'Dropdown'
}

pub fn (w &Menu) name() string {
	return 'Menu'
}

pub fn (w &Picture) name() string {
	return 'Picture'
}

pub fn (w &CheckBox) name() string {
	return 'CheckBox'
}

pub fn (w &Slider) name() string {
	return 'Slider'
}

// pub fn (w &Widget) get_width() int {
// 	return if w is Stack {
// 		w.width
// 	} else if w is Group {
// 		w.width
// 	} else {
// 		0
// 	}
// }

// pub fn (w &Widget) get_height() int {
// 	return if w is Stack {
// 		w.height
// 	} else if w is Group {
// 		w.height
// 	} else {
// 		0
// 	}
// }

pub fn set_width(mut w Widget, width int) {
	if w is Stack {
		w.width = width
	} else if w is Group {
		w.width = width
	}
}

pub fn set_height(mut w Widget, height int) {
	if w is Stack {
		w.height = height
	} else if w is Group {
		w.height = height
	}
}
