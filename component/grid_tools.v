module component

import ui
import gx

[heap]
struct GridSettings {
pub mut:
	id       string
	layout   &ui.Stack   = 0
	grid     &Grid       = 0
	lb_left  &ui.ListBox = 0
	lb_right &ui.ListBox = 0
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct GridSettingsParams {
	id       string
	bg_color gx.Color = gx.light_blue
	grid     &Grid
}

pub fn gridsettings(p GridSettingsParams) &ui.Stack {
	lbl := ui.listbox(id: p.id + '_lb_left', ordered: true)
	lbr := ui.listbox(id: p.id + '_lb_right')
	btn := ui.button(id: p.id + '_btn_sort', text: 'sort', onclick: gs_sort_click)
	mut layout := ui.column(
		id: p.id + '_layout'
		bg_color: p.bg_color
		margin_: 10
		heights: [ui.stretch, 20]
		children: [
			ui.row(
				id: p.id + '_row'
				children: [lbl, lbr]
			),
			btn,
		]
	)
	gs := &GridSettings{
		id: p.id
		layout: layout
		lb_left: lbl
		lb_right: lbr
		grid: p.grid
	}
	println('gridsettings $gs.id grid: $gs.grid.id $layout.id')
	ui.component_connect(gs, layout, lbl, lbr, btn)
	// init component
	layout.component_init = gridsettings_init
	return layout
}

pub fn component_gridsettings(w ui.ComponentChild) &GridSettings {
	return &GridSettings(w.component)
}

fn gs_sort_click(a voidptr, mut b ui.Button) {
	gs := component_gridsettings(b)
	mut g := gs.grid
	mut vars, mut orders := []int{}, []int{}
	for item in gs.lb_right.items() {
		for i, var in g.headers {
			if var == item.text {
				vars << i
				orders << if item.selected { 1 } else { -1 }
				break
			}
		}
	}
	g.init_ranked_grid_data(vars, orders)
}

// pub fn (mut gs GridSettings) update_sorted_vars() {
// 	g := gs.grid
// 	// println("update sorted vars $gs.id ${typeof(g).name} $g.id")
// 	gs.lb_left.update_items(g.headers)
// }

fn gridsettings_init(layout &ui.Stack) {
	println('hereeeeee')
	mut gs := component_gridsettings(layout)
	g := gs.grid
	println(g.headers)
	gs.lb_left.update_items(g.headers)
}
