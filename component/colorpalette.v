module component

import ui
import gx
import math

[heap]
struct ColorPaletteComponent {
pub mut:
	layout  &ui.Stack  // required
	colbtn  &ui.Button // current
	ncolors int
	color   &gx.Color = 0
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
	colbtn := colorbutton(id: ui.component_id(p.id, 'colbtn'), on_click: colorpalette_click)
	mut children := []ui.Widget{}
	children << [colbtn, ui.spacing()]
	for i in 0 .. p.ncolors {
		cb := colorbutton(id: ui.component_id(p.id, 'palette$i'), on_click: colorpalette_click)
		children << cb
	}
	mut sizes := [f64(30), 10]
	sizes << [f64(30)].repeat(p.ncolors)

	mut layout := match p.direction {
		.row {
			ui.row(
				id: ui.component_id(p.id, 'layout')
				bg_color: ui.no_color
				widths: sizes
				margin_: 5
				children: children
			)
		}
		.column {
			ui.column(
				id: ui.component_id(p.id, 'layout')
				bg_color: gx.hex(0xfcf4e4ff)
				heights: sizes
				margin_: 5
				children: children
			)
		}
	}
	cp := &ColorPaletteComponent{
		layout: layout
		colbtn: colbtn
		ncolors: p.ncolors
	}

	// match p.direction {
	// 	.row {
	// 		layout.widths = [f32(30), 10]
	// 		layout.widths << [f32(30)].repeat(cp.ncolors)
	// 	}
	// 	.column {
	// 		layout.heights = [f32(30), 10]
	// 		layout.heights << [f32(30)].repeat(cp.ncolors)
	// 	}
	// }
	// layout.spacings = [f32(2)].repeat(cp.ncolors + 1)
	ui.component_connect(cp, layout)
	return layout
}

// component common access
pub fn colorpalette_component(w ui.ComponentChild) &ColorPaletteComponent {
	return &ColorPaletteComponent(w.component)
}

pub fn colorpalette_component_from_id(w ui.Window, id string) &ColorPaletteComponent {
	cp := colorpalette_component(w.stack(ui.component_id(id, 'layout')))
	return cp
}

pub fn (mut cp ColorPaletteComponent) update_colors(colors []gx.Color) {
	for i in 0 .. math.min(cp.ncolors, colors.len) {
		child := cp.layout.children[i + 2]
		if child is ui.Button {
			mut cb := colorbutton_component_from_id(cp.layout.ui.window, child.id)
			cb.bg_color = colors[i]
		}
	}
}

pub fn (mut cp ColorPaletteComponent) update_colorbutton(color gx.Color) {
	unsafe {
		*(cp.colbtn.bg_color) = color
	}
}

pub fn (mut cp ColorPaletteComponent) connect_color(color &gx.Color) {
	unsafe {
		cp.color = color
	}
}

pub fn colorpalette_click(cb &ColorButtonComponent) {
	mut cp := colorpalette_component_from_id(cb.widget.ui.window, ui.component_parent_id(cb.widget.id))
	unsafe {
		*(cp.color) = cb.bg_color
	}
}
