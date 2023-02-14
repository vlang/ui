module component

import ui
import gx

const splitpanel_btn_size = 6

[heap]
pub struct SplitPanelComponent {
pub mut:
	id        string
	layout    &ui.Stack
	child1    &ui.Widget
	child2    &ui.Widget
	direction ui.Direction
	active    bool
	weight    f32
	btn_size  int
}

[params]
pub struct SplitPanelParams {
	id        string
	child1    &ui.Widget
	child2    &ui.Widget
	direction ui.Direction = .row
	weight    f64 = 50.0
	btn_size  int = component.splitpanel_btn_size
}

// TODO: documentation
pub fn splitpanel_stack(p SplitPanelParams) &ui.Stack {
	splitbtn := ui.button(
		id: ui.component_id(p.id, 'splitbtn')
		on_mouse_down: splitpanel_btn_mouse_down
		on_mouse_up: splitpanel_btn_mouse_up
		on_mouse_move: splitpanel_btn_mouse_move
		hoverable: true
		// TODO: to adapt to chosen style
		bg_color_hover: gx.gray
		bg_color: gx.light_gray
		bg_color_pressed: gx.black
		on_mouse_enter: fn (mut b ui.Button, e &ui.MouseMoveEvent) {
			sp := splitpanel_component(b)
			b.ui.window.mouse.start('_system_:resize_' +
				(if sp.direction == .row { 'ew' } else { 'ns' }))
		}
		on_mouse_leave: fn (mut b ui.Button, e &ui.MouseMoveEvent) {
			sp := splitpanel_component(b)
			b.ui.window.mouse.stop_last('_system_:resize_' +
				(if sp.direction == .row { 'ew' } else { 'ns' }))
		}
	)
	mut layout := if p.direction == .row {
		ui.row(
			widths: [p.weight * ui.stretch, p.btn_size, (100.0 - p.weight) * ui.stretch]
			heights: ui.stretch
			id: ui.component_id(p.id, 'layout')
			children: [p.child1, splitbtn, p.child2]
		)
	} else {
		ui.column(
			widths: ui.stretch
			heights: [p.weight * ui.stretch, p.btn_size, (100.0 - p.weight) * ui.stretch]
			id: ui.component_id(p.id, 'layout')
			children: [p.child1, splitbtn, p.child2]
		)
	}

	mut sp := &SplitPanelComponent{
		id: p.id
		layout: layout
		child1: p.child1
		child2: p.child2
		direction: p.direction
		weight: f32(p.weight)
		btn_size: p.btn_size
	}
	ui.component_connect(sp, layout, splitbtn)
	return layout
}

// TODO: documentation
pub fn splitpanel_component(w ui.ComponentChild) &SplitPanelComponent {
	return unsafe { &SplitPanelComponent(w.component) }
}

// TODO: documentation
pub fn splitpanel_component_from_id(w ui.Window, id string) &SplitPanelComponent {
	return splitpanel_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

fn splitpanel_btn_mouse_down(b &ui.Button, e &ui.MouseEvent) {
	mut sp := splitpanel_component(b)
	sp.active = true
}

fn splitpanel_btn_mouse_up(b &ui.Button, e &ui.MouseEvent) {
	mut sp := splitpanel_component(b)
	sp.active = false
}

fn splitpanel_btn_mouse_move(b &ui.Button, e &ui.MouseMoveEvent) {
	mut sp := splitpanel_component(b)
	if sp.active {
		if sp.direction == .row {
			w, _ := sp.layout.size()
			if e.x < sp.layout.x {
				sp.weight = f32(0.1)
			} else if e.x > sp.layout.x + w {
				sp.weight = f32(99.9)
			} else {
				sp.weight = f32(e.x - sp.layout.x) / f32(w) * 100.0
			}
			// println("$e.x $sp.layout.x $w = > $sp.weight")
			sp.layout.widths = [sp.weight * ui.stretch, sp.btn_size, (100.0 - sp.weight) * ui.stretch]
			// sp.layout.widths = [ui.stretch ]
		} else {
			_, h := sp.layout.size()
			if e.y < sp.layout.y {
				sp.weight = f32(0.0)
			} else if e.y > sp.layout.y + h {
				sp.weight = f32(100.0)
			} else {
				sp.weight = f32(e.y - sp.layout.y) / f32(h) * 100.0
			}
			// println("${e.y - sp.layout.y} / $h")
			sp.layout.heights = [sp.weight * ui.stretch, sp.btn_size,
				(100.0 - sp.weight) * ui.stretch]
		}
		// println("toto $sp.weight")
		sp.layout.update_layout()
		// b.ui.window.update_layout()
	}
}
