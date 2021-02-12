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
		println('	parent: $parent.name() => size ($parent.width, $parent.height)  adj: ($parent.adj_width, $parent.adj_height) spacing: $parent.spacing')
	} else if parent is Window {
		println('	parent: Window => size ($parent.width, $parent.height)  adj: ($parent.adj_width, $parent.adj_height) ')
	}
	for i, child in s.children {
		w, h := child.size()
		println('		$i) $child.name() size => $w, $h')
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
