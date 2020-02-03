module ui

pub enum FillLayoutAlignment {
	vertical = 0
	horizontal = 1
}

pub struct FillLayoutConfig {
	width  int
	height int
	align FillLayoutAlignment
}

pub struct FillLayout {
mut:
	x		 int
	y        int
	width    int
	height   int
	children []IWidgeter
	parent   ILayouter
	ui     &UI
	align FillLayoutAlignment
}

fn (b mut FillLayout) init(p &ILayouter) {
	parent := *p
	b.parent = parent
	ui := parent.get_ui()
	w, h := parent.get_size()
	b.ui = ui

	b.width = w
	b.height = h
	b.set_pos(b.x, b.y)
	for child in b.children {
		child.init(b)
	}

    mut widgets := b.children
    if b.align == FillLayoutAlignment.vertical {
        mut start_y := 0
        mut height := h/widgets.len
        for widget in widgets {
        	widget.set_pos(0, start_y)
        	widget.propose_size(w, height)
        	start_y = start_y + height
        }
    }else{
        mut start_x := 0
        mut width := w/widgets.len
        for widget in widgets {
        	widget.set_pos(start_x, 0)
        	widget.propose_size(width, h)
        	start_x = start_x + width
        }
    }
}

pub fn fill_layout(c FillLayoutConfig, children []IWidgeter) &FillLayout {
	mut b := &FillLayout{
		height: c.height
		width: c.width
		align: c.align
		children: children
	}
	return b
}

fn (b mut FillLayout) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b &FillLayout) get_subscriber() &eventbus.Subscriber {
	parent := b.parent
	return parent.get_subscriber()
}

fn (b mut FillLayout) propose_size(w, h int) (int,int) {
	b.width = w
	b.height = h
	return b.width, b.height
}

fn (c &FillLayout) get_size() (int, int) {
	return c.width, c.height
}

fn (b mut FillLayout) draw() {
	for child in b.children {
		child.draw()
	}
}

fn (t &FillLayout) get_ui() &UI {
	return t.ui
}

fn (t &FillLayout) unfocus_all() {
	for child in t.children {
		child.unfocus()
	}
}

fn (t &FillLayout) get_user_ptr() voidptr {
	parent := t.parent
	return parent.get_user_ptr()
}

fn (t &FillLayout) point_inside(x, y f64) bool {
	return false
}

fn (b mut FillLayout) focus() {}

fn (b mut FillLayout) unfocus() {}

fn (t &FillLayout) is_focused() bool {
	return false
}
