module ui

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
	children []IWidgeter
	parent   ILayouter
	ui     &UI
	vertical_alignment VerticalAlignment
	horizontal_alignment HorizontalAlignment
	spacing int
	stretch bool
	direction Direction
	margin 	MarginConfig
}

fn (b mut Stack) init(p &ILayouter) {
	parent := *p
	b.parent = parent
	ui := parent.get_ui()
	w, h := parent.get_size()
	b.ui = ui

	if b.stretch {
		b.height = h
		b.width = w
	} else {
		if b.direction == .row {
			b.width = w
		} else {
			b.height = h
		}
	}
	b.height -= b.margin.top + b.margin.bottom
	b.width -= b.margin.left + b.margin.right
	b.set_pos(b.x, b.y)
	for child in b.children {
		child.init(b)
	}
}

fn stack(c StackConfig, children []IWidgeter) &Stack {
	mut b := &Stack{
		height: c.height
		width: c.width
		vertical_alignment: c.vertical_alignment
		horizontal_alignment: c.horizontal_alignment
		spacing: c.spacing
		stretch: c.stretch
		direction: c.direction
		margin: c.margin
		children: children
	}
	return b
}

fn (b mut Stack) set_pos(x, y int) {
	b.x = x + b.margin.left
	b.y = y + b.margin.top
}

fn (b &Stack) get_subscriber() &eventbus.Subscriber {
	parent := b.parent
	return parent.get_subscriber()
}

fn (b mut Stack) propose_size(w, h int) (int,int) {
	if b.stretch {
		b.width = w
		b.height = h
	}
	return b.width, b.height
}

fn (c &Stack) get_size() (int, int) {
	return c.width, c.height
}

fn (b mut Stack) draw() {
	mut per_child_size := b.get_height()
	mut pos := b.get_y_axis()
	mut size := 0
	for child in b.children {
		mut h := 0
		mut w := 0
		if b.direction == .row {
			h, w = child.propose_size(per_child_size, b.height)
			child.set_pos(pos, b.align(w))
		} else {
			w, h = child.propose_size(b.width, per_child_size)
			child.set_pos(b.align(w), pos)
		}
		if w > size {size = w}
		child.draw()
		pos += h + b.spacing
		per_child_size -= h + b.spacing
	}
	if b.stretch {return}
	b.set_height(pos - b.get_y_axis())
	s := b.get_width()
	if s == 0 || s < size {
		b.set_width(size)
	}
}
fn (b &Stack) align(size int) int {
	align := if b.direction == .row { int(b.vertical_alignment) } else { int(b.horizontal_alignment) }
	match align {
		0 {
			return b.get_x_axis()
		}
		1 {
			return b.get_x_axis() + ((b.get_width() - size) / 2)
		}
		2 {
			return (b.get_x_axis() + b.get_width()) - size
		}
		else {return b.get_x_axis()}
	}
}

fn (t &Stack) get_ui() &UI {
	return t.ui
}

fn (t &Stack) unfocus_all() {
	for child in t.children {
		child.unfocus()
	}
}

fn (t &Stack) get_user_ptr() voidptr {
	parent := t.parent
	return parent.get_user_ptr()
}

fn (t &Stack) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (b mut Stack) focus() {
	// b.is_focused = true
	println('')
}

fn (b mut Stack) unfocus() {
	// b.is_focused = false
	println('')
}

fn (t &Stack) is_focused() bool {
	return false // t.is_focused
}


/* Helpers to correctly get height, width, x, y for both row & column
   Column & Row are identical except everything is reversed. These methods
   get/set reverse values for row.
   Height -> Width
   Width -> Height
   X -> Y
   Y -> X
 */
fn (b &Stack) get_height() int {
	return if b.direction == .row {b.width} else {b.height}
}
fn (b &Stack) get_width() int {
	return if b.direction == .row {b.height} else {b.width}
}
fn (b &Stack) get_y_axis() int {
	return if b.direction == .row {b.x} else {b.y}
}
fn (b &Stack) get_x_axis() int {
	return if b.direction == .row {b.y} else {b.x}
}
fn (b mut Stack) set_height(h int) int {
	return if b.direction == .row {b.width = h} else {b.height = h}
}
fn (b mut Stack) set_width(w int) int {
	return if b.direction == .row {b.height = w} else {b.width = w}
}