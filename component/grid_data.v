module component

import ui
import gx

[heap]
struct DataGridComponent {
pub mut:
	layout   &ui.Stack
	grid     &GridComponent
	settings &GridSettingsComponent
}

[params]
pub struct DataGridComponentParams {
	GridComponentParams // for settings prepended by settings_
	settings_bg_color gx.Color = gx.light_blue
	settings_z_index  int      = 100
}

pub fn datagrid_stack(p DataGridComponentParams) &ui.Stack {
	mut pg := p.GridComponentParams
	pg.id = ui.component_part_id(p.id, 'grid')
	gl := grid_canvaslayout(pg)
	mut g := grid_component(gl)
	g.shortcuts[15] = ui.Shortcut{
		is_char: true
		mods: .ctrl
		key_fn: fn (comp voidptr) {
			g := &GridComponent(comp)
			l := g.layout.ui.window.stack(ui.component_part_id(ui.component_id(g.id),
				'hideable', 'layout'))
			mut h := hideable_component(l)
			h.toggle()
		}
	}
	gsl := gridsettings_stack(
		id: ui.component_part_id(p.id, 'gridsettings')
		grid: g
		bg_color: p.settings_bg_color
		z_index: p.settings_z_index
	)
	mut gs := gridsettings_component(gsl)
	mut layout := ui.row(
		id: ui.component_part_id(p.id, 'layout')
		widths: [ui.stretch, ui.stretch * 3]
		children: [
			hideable_stack(
				id: ui.component_part_id(p.id, 'hideable')
				layout: gsl
			),
			gl,
		]
	)
	mut dg := &DataGridComponent{
		layout: layout
		grid: g
		settings: gs
	}
	// println("dg comp: <$dg.layout.id> <$dg.grid.id>")
	ui.component_connect(dg, layout)
	return layout
}
