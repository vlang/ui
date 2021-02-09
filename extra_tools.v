module ui

import gx

// Tool to convert width and height from f32 to int
pub fn convert_size_f32_to_int(width f32, height f32) (int, int) {
	// Convert c.width and c.height from f32 to int used as a trick to deal with relative size with respect to parent 
	mut w := int(width)
	mut h := int(height)
	if 0 < width && width <= 1 {
		w = -int(width * 100) // to be converted in percentage of parent size inside init call
	}
	if 0 < height && height <= 1 {
		w = -int(height * 100) // to be converted in percentage of parent size inside init call
	}
	return w, h
}

// if size is negative, it is relative in percentage of the parent 
pub fn relative_size_from_parent(size int, parent_size int, spacing int) int {
	return if size < 0 {
		percent := f32(-size) / 100
		free_size := parent_size - spacing
		new_size := int(percent * free_size)
		println('relative size: $size $new_size -> $percent * ($parent_size - $spacing) ')
		new_size
	} else {
		size
	}
}

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
