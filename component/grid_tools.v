module component

import ui
import gx

[heap]
struct GridSettings {
pub mut:
	id     string
	layout &ui.Stack   = 0
	grid   &Grid       = 0
	lb     &ui.ListBox = 0
}

[params]
pub struct GridSettingsParams {
	id       string
	bg_color gx.Color = gx.light_blue
	grid     &Grid
}

pub fn gridsettings(p GridSettingsParams) &ui.Stack {
	lbl := ui.listbox(id: p.id + '_lb_left')
	lbr := ui.listbox(id: p.id + '_lb_right')
	btn := ui.button(id: p.id + '_btn_sort', text: 'sort', onclick: gs_sort_click)
	layout := ui.column(
		id: p.id + '_layout'
		bg_color: p.bg_color
		children: [
			ui.row(id: p.id + '_row', children: [lbl, lbr]),
			btn,
		]
	)
	gs := &GridSettings{
		id: p.id
		layout: layout
		lb: lbr
		grid: p.grid
	}
	ui.component_connect(gs, layout, lbl, lbr, btn)
	return layout
}

pub fn component_gridsettings(w ui.ComponentChild) &GridSettings {
	return &GridSettings(w.component)
}

fn gs_sort_click(a voidptr, mut b ui.Button) {
	gs := component_gridsettings(b)
	mut g := gs.grid
	mut vars, mut orders := []int{}, []int{}
	for item in gs.lb.items() {
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
