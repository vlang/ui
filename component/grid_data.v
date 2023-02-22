module component

import ui
import gx

[heap]
pub struct DataGridComponent {
pub mut:
	layout   &ui.Stack      = unsafe { nil }
	grid     &GridComponent = unsafe { nil }
	settings &GridSettingsComponent = unsafe { nil }
}

[params]
pub struct DataGridParams {
	GridParams // for settings prepended by settings_
	settings_bg_color gx.Color = gx.light_blue
	settings_z_index  int      = 100
}

// TODO: documentation
pub fn datagrid_stack(p DataGridParams) &ui.Stack {
	mut pg := p.GridParams
	pg.id = ui.component_id(p.id, 'grid')
	gl := grid_canvaslayout(pg)
	mut g := grid_component(gl)
	// add shortcut
	mut sc := ui.Shortcutable(g)
	sc.add_shortcut('ctrl + o', fn (g &GridComponent) {
		l := g.layout.ui.window.get_or_panic[ui.Stack](ui.component_id(ui.component_parent_id(g.id),
			'hideable', 'layout'))
		mut h := hideable_component(l)
		h.toggle()
	})
	gsl := gridsettings_stack(
		id: ui.component_id(p.id, 'gridsettings')
		grid: g
		bg_color: p.settings_bg_color
		z_index: p.settings_z_index
	)
	mut gs := gridsettings_component(gsl)
	mut layout := ui.row(
		id: ui.component_id(p.id, 'layout')
		widths: [ui.stretch, ui.stretch * 3]
		children: [
			hideable_stack(
				id: ui.component_id(p.id, 'hideable')
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

[heap]
pub struct DataGridBoxLayoutComponent {
pub mut:
	layout &ui.BoxLayout  = unsafe { nil }
	grid   &GridComponent = unsafe { nil }
	// settings &GridSettingsComponent = unsafe { nil }
}

[params]
pub struct DataGridBoxLayoutParams {
	GridParams // for settings prepended by settings_
	// settings_bg_color gx.Color = gx.light_blue
	// settings_z_index  int      = 100
}

// TODO: documentation
pub fn datagrid_boxlayout(p DataGridBoxLayoutParams) &ui.BoxLayout {
	mut pg := p.GridParams
	pg.id = ui.component_id(p.id, 'grid')
	gl := grid_canvaslayout(pg)
	mut g := grid_component(gl)
	// add shortcut
	mut sc := ui.Shortcutable(g)
	sc.add_shortcut('ctrl + o', fn (g &GridComponent) {
		// l := g.layout.ui.window.get_or_panic[ui.BoxLayout](ui.component_id(ui.component_parent_id(g.id),
		// 	'hideable', 'layout'))
		// mut h := hideable_component(l)
		// h.toggle()
	})
	// gsl := gridsettings_stack(
	// 	id: ui.component_id(p.id, 'gridsettings')
	// 	grid: g
	// 	bg_color: p.settings_bg_color
	// 	z_index: p.settings_z_index
	// )
	// mut gs := gridsettings_component(gsl)
	mut layout := ui.box_layout(
		id: ui.component_id(p.id, 'layout')
		children: {
			'${ui.component_id(p.id, 'gl')}: (0,0) -> (1,1)': gl
		}
	)
	mut dg := &DataGridBoxLayoutComponent{
		layout: layout
		grid: g
		// settings: gs
	}
	// println("dg comp: <$dg.layout.id> <$dg.grid.id>")
	ui.component_connect(dg, layout)
	return layout
}
