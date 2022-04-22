module component

import ui

[heap]
struct MenuBarComponent {
pub mut:
	id     string
	layout &ui.Stack
	layer  &ui.CanvasLayout
	// on_changed MenuBarFn
}

// path of map have to be of the form id/id2/id3
// when final action is performed we can then close all the parents menus

[params]
pub struct MenuBarParams {
	id        string
	direction ui.Direction = .column
	buttons   []ui.Button
	menus     map[string]ui.Menu
	width     int
	height    int
	margin    int
	spacing   int
	// on_changed MenuBarFn      = MenuBarFn(0)
}

pub fn menubar_stack(p MenuBarParams) &ui.Stack {
	mut layout := match p.direction {
		.row {
			ui.row(
				id: ui.component_id(p.id, 'layout')
				margin_: p.margin
				spacing: p.spacing
				heights: [f64(p.height)].repeat(p.buttons.len)
				widths: [f64(p.width)].repeat(p.buttons.len)
				children: p.buttons.map(ui.Widget(it))
			)
		}
		.column {
			ui.column(
				id: ui.component_id(p.id, 'layout')
				heights: [f64(p.height)].repeat(p.buttons.len)
				widths: [f64(p.width)].repeat(p.buttons.len)
				margin_: p.margin
				spacing: p.spacing
				children: p.buttons.map(ui.Widget(it))
			)
		}
	}
	mut layer := layer_canvaslayout(
		id: ui.component_id(p.id, 'layer')
	)

	mb := &MenuBarComponent{
		id: p.id
		layout: layout
		layer: layer
	}
	ui.component_connect(mb, layout, layer)
	return layout
}
