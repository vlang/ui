module component

import ui
import gx
import math

@[heap]
pub struct ColorPaletteComponent {
pub mut:
	id       string
	layout   &ui.Stack  = unsafe { nil } // required
	colbtn   &ui.Button = unsafe { nil } // current
	ncolors  int
	alpha    &AlphaComponent = unsafe { nil }
	color    &gx.Color       = unsafe { nil }
	selected string
}

@[params]
pub struct ColorPaletteParams {
pub:
	id        string
	title     string
	items     []string
	direction ui.Direction = .column
	ncolors   int          = 6
}

// TODO: documentation
pub fn colorpalette_stack(p ColorPaletteParams) &ui.Stack {
	mut colbtn := colorbutton(
		id:        ui.component_id(p.id, 'colbtn')
		on_click:  colorpalette_click
		left_side: true
	)
	colbtn.alpha_mode = true
	mut children := []ui.Widget{}
	children << [ui.label(text: 'colors', justify: ui.top_center), colbtn, ui.spacing()]
	for i in 0 .. p.ncolors {
		mut cb := colorbutton(
			id:        ui.component_id(p.id, 'palette${i}')
			on_click:  colorpalette_click
			left_side: true
		)
		cb.alpha_mode = true
		children << cb
	}
	alpha := alpha_stack(
		id:         ui.component_id(p.id, 'alpha')
		on_changed: fn (ac &AlphaComponent) {
			parent_id := ui.component_parent_id(ac.id)
			cpc := colorpalette_component_from_id(ac.layout.ui.window, parent_id)
			// println("alpha on_chnaged selected: $cpc.selected")
			mut cbc := colorbutton_component_from_id(ac.layout.ui.window, cpc.selected)
			cbc.bg_color.a = u8(ac.alpha)
		}
	)
	children << [ui.spacing(), ui.label(text: 'alpha', justify: ui.top_center), alpha]
	mut sizes := [ui.compact, f64(30), 10]
	sizes << [f64(30)].repeat(p.ncolors)
	sizes << [f64(10), ui.compact, 30]
	mut layout := match p.direction {
		.row {
			ui.row(
				id:       ui.component_id(p.id, 'layout')
				bg_color: ui.no_color
				widths:   sizes
				margin_:  5
				spacing:  5
				children: children
			)
		}
		.column {
			ui.column(
				id:       ui.component_id(p.id, 'layout')
				bg_color: gx.hex(0xfcf4e4ff)
				heights:  sizes
				margin_:  5
				spacing:  5
				children: children
			)
		}
	}
	mut cp := &ColorPaletteComponent{
		id:      p.id
		layout:  layout
		colbtn:  colbtn
		ncolors: p.ncolors
		alpha:   alpha_component(alpha)
	}
	// init selection
	cp.selected = ui.component_id(p.id, 'colbtn')
	ui.component_connect(cp, layout)
	return layout
}

// component common access
pub fn colorpalette_component(w ui.ComponentChild) &ColorPaletteComponent {
	return unsafe { &ColorPaletteComponent(w.component) }
}

// TODO: documentation
pub fn colorpalette_component_from_id(w ui.Window, id string) &ColorPaletteComponent {
	cp := colorpalette_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
	return cp
}

// TODO: documentation
pub fn (mut cp ColorPaletteComponent) update_colors(colors []gx.Color) {
	// println("palette update_colors: $colors")
	for i in 0 .. math.min(cp.ncolors, colors.len) {
		child := cp.layout.children[i + 3] // 3 = label + colorbtn + spacing
		if child is ui.Button {
			mut cb := colorbutton_component_from_id(cp.layout.ui.window, child.id)
			cb.bg_color = colors[i]
			// println("color $i: ${colors[i]} -> ${cb.bg_color}")
		}
	}
}

// TODO: documentation
pub fn (mut cp ColorPaletteComponent) update_colorbutton(color gx.Color) {
	unsafe {
		*(cp.colbtn.bg_color) = color
	}
}

// TODO: documentation
pub fn (mut cp ColorPaletteComponent) connect_color(color &gx.Color) {
	unsafe {
		cp.color = color
	}
}

// TODO: documentation
pub fn colorpalette_click(cb &ColorButtonComponent) {
	mut cp := colorpalette_component_from_id(cb.widget.ui.window, ui.component_parent_id(cb.widget.id))
	cp.selected = cb.widget.id
	unsafe {
		*(cp.color) = cb.bg_color
	}
	cp.alpha.set_alpha(cb.bg_color.a)
}
