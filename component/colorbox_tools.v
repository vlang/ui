module component

import ui
import gx

const (
	colorbox_subwindow_id        = '_sw_cbox'
	colorbox_subwindow_layout_id = ui.component_part_id('_sw_cbox', 'layout')
)

// Append colorbox to window
pub fn colorbox_subwindow_add(mut w ui.Window) {
	// only once
	if !ui.Layout(w).has_child_id(component.colorbox_subwindow_id) {
		w.subwindows << ui.subwindow(
			id: component.colorbox_subwindow_id
			layout: colorbox_stack(id: component.colorbox_subwindow_id, light: true, hsl: false)
		)
	}
}

// to connect the colorbox to gx.Color reference
pub fn colorbox_subwindow_connect(w &ui.Window, col &gx.Color, colbtn &ColorButtonComponent) {
	mut s := w.subwindow(component.colorbox_subwindow_id)
	cb_layout := w.stack(component.colorbox_subwindow_layout_id)
	mut cb := colorbox_component(cb_layout)
	if col != 0 {
		cb.connect(col)
		cb.update_from_rgb(col.r, col.g, col.b)
	}
	// connect also the colbtn of cb
	if colbtn != 0 {
		// println("connect ${colbtn.widget.id} ${colbtn.on_changed != ColorButtonChangedFn(0)}")
		cb.connect_colorbutton(colbtn)
	}
	s.set_visible(s.hidden)
	s.update_layout()
}

type ColorButtonChangedFn = fn (b &ColorButtonComponent)

struct ColorButtonComponent {
pub mut:
	widget     &ui.Button
	on_click   ui.ButtonClickFn
	bg_color   gx.Color = gx.white
	on_changed ColorButtonChangedFn = ColorButtonChangedFn(0)
}

[params]
pub struct ColorButtonParams {
	id           string
	text         string
	height       int
	width        int
	z_index      int
	tooltip      string
	tooltip_side ui.Side = .top
	radius       f64     = .25
	padding      f64
	bg_color     &gx.Color = 0
	on_click     ui.ButtonClickFn
	on_changed   ColorButtonChangedFn
}

pub fn colorbutton(c ColorButtonParams) &ui.Button {
	mut b := &ui.Button{
		id: c.id
		width_: c.width
		height_: c.height
		z_index: c.z_index
		bg_color: c.bg_color
		theme_cfg: ui.no_theme
		tooltip: ui.TooltipMessage{c.tooltip, c.tooltip_side}
		onclick: colorbutton_click
		radius: f32(c.radius)
		padding: f32(c.padding)
		ui: 0
	}
	cbc := &ColorButtonComponent{
		widget: b
		on_click: c.on_click
		on_changed: c.on_changed
	}
	if b.bg_color == 0 {
		b.bg_color = &cbc.bg_color
	}
	ui.component_connect(cbc, b)
	return b
}

// component access
pub fn colorbutton_component(w ui.ComponentChild) &ColorButtonComponent {
	return &ColorButtonComponent(w.component)
}

pub fn colorbutton_component_from_id(w ui.Window, id string) &ColorButtonComponent {
	return colorbutton_component(w.button(id))
}

fn colorbutton_click(a voidptr, mut b ui.Button) {
	clc := colorbutton_component(b)
	colorbox_subwindow_connect(b.ui.window, b.bg_color, clc)
	// move only if s.x and s.y == 0 first use
	mut s := b.ui.window.subwindow(component.colorbox_subwindow_id)
	if s.x == 0 && s.y == 0 {
		w, h := b.size()
		s.set_pos(b.x + w / 2, b.y + h / 2)
		s.update_layout()
	}
	// on_click initialization if necessary
	bcc := colorbutton_component(b)
	if bcc.on_click != ui.ButtonClickFn(0) {
		bcc.on_click(a, b)
	}
}
