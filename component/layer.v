module component

import ui

// type LayerInitFn = fn (l &LayerComponent)

[heap]
struct LayerComponent {
pub mut:
	id     string
	layout &ui.CanvasLayout
}

[params]
pub struct LayerParams {
	id       string
	width    int
	height   int
	children []ui.Widget
}

pub fn layer_canvaslayout(p LayerParams) &ui.CanvasLayout {
	mut layout := ui.canvas_layout(
		id: ui.component_id(p.id, 'layout')
		bg_color: ui.no_color // no background
		children: p.children
	)
	// layout.point_inside_visible = true
	l := &LayerComponent{
		id: p.id
		layout: layout
	}
	ui.component_connect(l, layout)
	layout.on_init = layer_init
	return layout
}

pub fn layer_component(w ui.ComponentChild) &LayerComponent {
	return &LayerComponent(w.component)
}

pub fn layer_component_from_id(w &ui.Window, id string) &LayerComponent {
	return layer_component(w.canvas_layout(ui.component_id(id, 'layout')))
}

fn layer_init(mut cl ui.CanvasLayout) {
	// same size of window (like absolute coordinates)
	cl.propose_size(cl.ui.window.width, cl.ui.window.height)
}

pub fn (l &LayerComponent) move_at(id string, x int, y int) {
	mut w := l.layout.ui.window.widgets[id]
	w.set_pos(x, y)
}
