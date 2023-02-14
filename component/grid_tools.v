module component

import ui
import gx

[heap]
pub struct GridSettingsComponent {
pub mut:
	id       string
	layout   &ui.Stack      = unsafe { nil }
	grid     &GridComponent = unsafe { nil }
	lb_left  &ui.ListBox    = unsafe { nil }
	lb_right &ui.ListBox    = unsafe { nil }
}

[params]
pub struct GridSettingsParams {
	id       string
	bg_color gx.Color       = gx.light_blue
	grid     &GridComponent = unsafe { nil }
	z_index  int = 100
}

// TODO: documentation
pub fn gridsettings_stack(p GridSettingsParams) &ui.Stack {
	lbl := ui.listbox(
		id: ui.component_id(p.id, 'lb_left')
		ordered: true
		selectable: false
		z_index: p.z_index
	)
	lbr := ui.listbox(
		id: ui.component_id(p.id, 'lb_right')
		multi: true
		ordered: true
		z_index: p.z_index
	)
	btn := ui.button(
		id: ui.component_id(p.id, 'btn_sort')
		text: 'sort'
		on_click: gs_sort_click
		radius: .3
		z_index: p.z_index + 10
	)
	mut layout := ui.column(
		id: ui.component_id(p.id, 'layout')
		bg_color: p.bg_color
		margin_: 10
		spacing: 10
		heights: [20.0, ui.stretch]
		children: [
			btn,
			ui.row(
				id: ui.component_id(p.id, 'row')
				children: [lbl, lbr]
			),
		]
	)
	gs := &GridSettingsComponent{
		id: p.id
		layout: layout
		lb_left: lbl
		lb_right: lbr
		grid: p.grid
	}
	// println('gridsettings <$gs.id> grid: <$gs.grid.id> <$layout.id>')
	ui.component_connect(gs, layout, lbl, lbr, btn)
	// init component
	layout.on_init = gridsettings_init
	return layout
}

// component constructor
pub fn gridsettings_component(w ui.ComponentChild) &GridSettingsComponent {
	return unsafe { &GridSettingsComponent(w.component) }
}

// TODO: documentation
pub fn gridsettings_component_from_id(w ui.Window, id string) &GridSettingsComponent {
	return gridsettings_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

fn gs_sort_click(mut b ui.Button) {
	gs := gridsettings_component(b)
	mut g := gs.grid
	mut vars, mut orders := []int{}, []int{}
	for item in gs.lb_right.items() {
		orders << if item.selected { -1 } else { 1 }
		if item.text == '.id' {
			vars << -1
		} else {
			for i, var in g.headers {
				if var == item.text {
					vars << i
					break
				}
			}
		}
	}
	println('sort: ${vars}, ${orders}')
	g.unselect()
	g.init_ranked_grid_data(vars, orders)
}

// TODO: documentation
pub fn (mut gs GridSettingsComponent) update_sorted_vars() {
	g := gs.grid
	// println("update sorted vars <$gs.id> ${typeof(g).name} <$g.id>")
	mut headers := ['.id']
	headers << g.headers
	gs.lb_left.update_items(headers)
}

fn gridsettings_init(layout &ui.Stack) {
	mut gs := gridsettings_component(layout)
	gs.update_sorted_vars()
}
