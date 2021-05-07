module ui

pub struct DoubleListBoxConfig {
	id    string
	title string
	items []string
}

[heap]
struct DoubleListBox {
pub mut:
	layout    &Stack // optional
	lb_left   &ListBox
	lb_right  &ListBox
	btn_left  &Button
	btn_right &Button
	btn_clear &Button
	// To become a component of a parent component
	component voidptr
}

pub fn doublelistbox(c DoubleListBoxConfig) &Stack {
	//
	mut items := map[string]string{}
	for item in c.items {
		items[item] = item
	}
	mut lb_left := listbox({ width: 50 }, items)
	mut lb_right := listbox({ width: 50 }, map[string]string{})
	mut btn_right := button(text: '>>', onclick: doublelistbox_move_right)
	mut btn_left := button(text: '<<', onclick: doublelistbox_move_left)
	mut btn_clear := button(text: 'clear', onclick: doublelistbox_clear)
	mut layout := row({
		title: c.title
		id: c.id
		widths: [4 * stretch, 2 * stretch, 4 * stretch]
		heights: stretch
		spacing: .05
	}, [
		lb_left,
		column({ widths: stretch, heights: compact, spacing: 10 }, [btn_right, btn_left, btn_clear]),
		lb_right,
	])
	dbl_lb := &DoubleListBox{
		layout: layout
		lb_left: lb_left
		lb_right: lb_right
		btn_left: btn_left
		btn_right: btn_right
		btn_clear: btn_clear
	}
	// attach to one component all the components
	lb_left.component = dbl_lb
	lb_right.component = dbl_lb
	btn_left.component = dbl_lb
	btn_right.component = dbl_lb
	btn_clear.component = dbl_lb

	layout.component = dbl_lb

	layout.component_type = 'DoubleListBox'
	// This needs to be added to the children tree
	return layout
}

// callback
fn doublelistbox_clear(a voidptr, btn &Button) {
	mut dlb := component_doublelistbox(btn)
	for item in dlb.lb_right.values() {
		dlb.lb_left.add_item(item, item)
		dlb.lb_right.remove_item(item)
	}
}

fn doublelistbox_move_left(a voidptr, btn &Button) {
	mut dlb := component_doublelistbox(btn)
	if dlb.lb_right.is_selected() {
		_, item := dlb.lb_right.selected() or { '', '' }
		println('move << $item')
		if !(item in dlb.lb_left.values()) {
			dlb.lb_left.add_item(item, item)
			dlb.lb_right.remove_item(item)
		}
	}
}

fn doublelistbox_move_right(a voidptr, btn &Button) {
	mut dlb := component_doublelistbox(btn)
	if dlb.lb_left.is_selected() {
		_, item := dlb.lb_left.selected() or { '', '' }
		// println("move >> $item")
		if !(item in dlb.lb_right.values()) {
			dlb.lb_right.add_item(item, item)
			dlb.lb_left.remove_item(item)
		}
	}
}

pub fn (dlb &DoubleListBox) values() []string {
	return dlb.lb_right.values()
}

// No need from now
// fn doublelistbox_change(app voidptr, lb &ListBox) {
// 	// println("selected: $lb.selection")
// }
