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
	direction ui.Direction = .column
	ncolors   int = 6
}

pub fn colorpalette_stack(p ColorPaletteParams) &ui.Stack {
	mut layout := match p.direction {
		.row {
			ui.row(
				id: ui.component_part_id(p.id, 'layout')
				bg_color: gx.black
				margin_: 5
			)
		}
		.column {
			ui.column(
				id: ui.component_part_id(p.id, 'layout')
				bg_color: gx.black
				margin_: 5
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
	layout.children = [pa.colbtn, ui.spacing()]
	// Weird: for v in palette {layout.children << v} fails
	// Also layout.children << palette
	// unsafe { layout.children << palette }
	for i, _ in palette {
		layout.children << palette[i]
	}

	match p.direction {
		.row {
			layout.widths = [f32(30), 10]
			layout.widths << [f32(30)].repeat(p.ncolors)
		}
		.column {
			layout.heights = [f32(30), 10]
			layout.heights << [f32(30)].repeat(p.ncolors)
		}
	}
	layout.spacings = [f32(2)].repeat(p.ncolors + 1)
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
