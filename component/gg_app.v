module component

import ui
// import time
import gg

[heap]
struct GGAppComponent {
	id string
pub mut:
	layout &ui.CanvasLayout = unsafe { nil }
	app    ui.GGApp
}

[params]
pub struct GGAppComponentParams {
	id  string = 'gg_app'
	app ui.GGApp
}

pub fn gg_canvaslayout(p GGAppComponentParams) &ui.CanvasLayout {
	mut layout := ui.canvas_plus(
		id: ui.component_id(p.id, 'layout')
		delegate_evt_mngr: true
		on_draw: gg_draw
		on_delegate: gg_on_delegate
		on_bounding_change: gg_on_bounding_change
	)
	mut ggc := &GGAppComponent{
		id: p.id
		layout: layout
		app: p.app
	}
	ui.component_connect(ggc, layout)
	layout.on_init = gg_init
	return layout
}

// component access
pub fn gg_component(w ui.ComponentChild) &GGAppComponent {
	return unsafe { &GGAppComponent(w.component) }
}

pub fn gg_component_from_id(w ui.Window, id string) &GGAppComponent {
	return gg_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

fn gg_init(layout &ui.CanvasLayout) {
	mut ggc := gg_component(layout)
	if layout.ui.dd is ui.DrawDeviceContext {
		ggc.app.gg = &layout.ui.dd.Context
	}
	mut app := ggc.app
	app.on_init()
}

fn gg_draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	mut ggc := gg_component(c)
	mut app := ggc.app
	app.on_draw()
}

fn gg_on_delegate(c &ui.CanvasLayout, e &gg.Event) {
	mut ggc := gg_component(c)
	mut app := ggc.app
	app.on_delegate(e)
}

fn gg_on_bounding_change(c &ui.CanvasLayout, bb gg.Rect) {
	mut ggc := gg_component(c)
	mut app := ggc.app
	app.set_bounds(bb)
}
