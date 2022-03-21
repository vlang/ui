module component

import ui
import gx

[heap]
struct ColorPaletteComponent {
pub mut:
	layout  &ui.Stack  // required
	colbtn  &ui.Button // current
	palette []ui.Button
}

[params]
pub struct ColorPaletteParams {
	id        string
	title     string
	items     []string
	direction ui.Direction = .row
	ncolors   int
}

pub fn colorpalette_stack(p ColorPaletteParams) &ui.Stack {
	mut layout := match p.direction {
		.row {
			ui.row(
				id: ui.component_part_id(p.id, 'layout')
				bg_color: gx.white
			)
		}
		.column {
			ui.column(
				id: ui.component_part_id(p.id, 'layout')
				bg_color: gx.white
			)
		}
	}
	mut palette := []ui.Button{}
	for i in 0 .. p.ncolors {
		palette << colorbutton(id: ui.component_part_id(p.id, 'palette$i'))
	}
	pa := &ColorPaletteComponent{
		layout: layout
		colbtn: colorbutton(id: ui.component_part_id(p.id, 'colbtn'))
		palette: palette
	}
	ui.component_connect(pa, layout)

	return layout
}

// component common access
pub fn colorpalette_component(w ui.ComponentChild) &ColorPaletteComponent {
	return &ColorPaletteComponent(w.component)
}

pub fn colorpalette_component_from_id(w ui.Window, id string) &ColorPaletteComponent {
	return colorpalette_component(w.stack(ui.component_part_id(id, 'layout')))
}
