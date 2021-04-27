module ui

pub struct DoubleListBoxConfig {
	id    string
	items []string
}

struct DoubleListBox {
pub mut:
	layout    Stack
	id        string
	lb_left   ListBox
	lb_right  ListBox
	btn_left  Button
	btn_right Button
	btn_clear Button
}

pub fn doublelistbox(c DoubleListBoxConfig) &Stack {
	mut items := map[string]string{}
	for item in c.items {
		items[item] = item
	}
	mut lb_left := listbox({}, items)
	mut lb_right := listbox({}, map[string]string{})
	mut btn_right := button(text: '>>') //, onclick: doublelistbox_move_right)
	mut btn_left := button(text: '<<') //, onclick: doublelistbox_move_left)
	mut btn_clear := button(text: 'clear') //, onclick: doublelistbox_clear)
	mut layout := row({
		id: c.id
	}, [
		lb_left,
		column({ widths: stretch, heights: compact }, [btn_right, btn_left, btn_clear]),
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
	btn_left.state_ = dbl_lb
	btn_right.state_ = dbl_lb
	btn_left.state_ = dbl_lb
	btn_right.state_ = dbl_lb
	btn_clear.state_ = dbl_lb
	layout.state_ = dbl_lb
	return layout
}
