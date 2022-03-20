module component

import ui

[heap]
struct DoubleListBoxComponent {
pub mut:
	layout    &ui.Stack // required
	lb_left   &ui.ListBox
	lb_right  &ui.ListBox
	btn_left  &ui.Button
	btn_right &ui.Button
	btn_clear &ui.Button
}

[params]
pub struct DoubleListBoxParams {
	id    string
	title string
	items []string
}

pub fn doublelistbox_stack(c DoubleListBoxParams) &ui.Stack {
	mut items := map[string]string{}
	for item in c.items {
		items[item] = item
	}
	mut lb_left := ui.listbox(id: c.id + '_left', width: 50, items: items, ordered: true)
	mut lb_right := ui.listbox(
		id: c.id + '_right'
		width: 50
		ordered: true
		items: map[string]string{}
	)
	mut btn_right := ui.button(
		id: c.id + '_btn_right'
		text: '>>'
		onclick: doublelistbox_move_right
	)
	mut btn_left := ui.button(id: c.id + '_btn_left', text: '<<', onclick: doublelistbox_move_left)
	mut btn_clear := ui.button(id: c.id + '_btn_clear', text: 'clear', onclick: doublelistbox_clear)
	mut layout := ui.row(
		title: c.title
		id: ui.component_part_id(c.id, 'layout')
		widths: [4 * ui.stretch, 2 * ui.stretch, 4 * ui.stretch]
		heights: ui.stretch
		spacing: .05
		children: [
			lb_left,
			ui.column(
				widths: ui.stretch
				heights: ui.compact
				spacing: 10
				children: [btn_right, btn_left, btn_clear]
			),
			lb_right,
		]
	)
	dbl_lb := &DoubleListBoxComponent{
		layout: layout
		lb_left: lb_left
		lb_right: lb_right
		btn_left: btn_left
		btn_right: btn_right
		btn_clear: btn_clear
	}
	// link to one component all the components
	ui.component_connect(dbl_lb, layout, lb_left, lb_right, btn_left, btn_right, btn_clear)

	// This needs to be added to the children tree
	return layout
}

// component common access
pub fn doublelistbox_component(w ui.ComponentChild) &DoubleListBoxComponent {
	return &DoubleListBoxComponent(w.component)
}

pub fn doublelistbox_component_from_id(w ui.Window, id string) &DoubleListBoxComponent {
	return doublelistbox_component(w.stack(ui.component_part_id(id, 'layout')))
}

// callback
fn doublelistbox_clear(a voidptr, btn &ui.Button) {
	mut dlb := doublelistbox_component(btn)
	for item in dlb.lb_right.values() {
		dlb.lb_left.add_item(item, item)
		dlb.lb_right.remove_item(item)
	}
}

fn doublelistbox_move_left(a voidptr, btn &ui.Button) {
	mut dlb := doublelistbox_component(btn)
	if dlb.lb_right.is_selected() {
		_, item := dlb.lb_right.selected() or { '', '' }
		if item !in dlb.lb_left.values() {
			dlb.lb_left.add_item(item, item)
			dlb.lb_right.remove_item(item)
		}
	}
}

fn doublelistbox_move_right(a voidptr, btn &ui.Button) {
	mut dlb := doublelistbox_component(btn)
	if dlb.lb_left.is_selected() {
		_, item := dlb.lb_left.selected() or { '', '' }
		// println("move >> $item")
		if item !in dlb.lb_right.values() {
			dlb.lb_right.add_item(item, item)
			dlb.lb_left.remove_item(item)
		}
	}
}

pub fn (dlb &DoubleListBoxComponent) values() []string {
	return dlb.lb_right.values()
}

// No need from now
// fn doublelistbox_change(app voidptr, lb &ListBox) {
// 	// println("selected: $lb.selection")
// }
