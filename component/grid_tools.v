module component

import ui
import gx

[heap]
struct GridSettings {
pub mut:
	id     string
	layout &ui.Stack = 0
	grid   &Grid     = 0
}

[params]
pub struct GridSettingsParams {
	id       string
	bg_color gx.Color
	grid     &Grid
}

pub fn grid_settings(p GridSettingsParams) &ui.Stack {
	mut gs := &GridSettings{
		id: p.id
	}
	layout := ui.row()
	return layout
}

pub fn component_grid_settings(w ui.ComponentChild) &GridSettings {
	return &GridSettings(w.component)
}
