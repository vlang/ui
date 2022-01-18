module component

import ui
import gx

[heap]
struct ButtonFont {
pub mut:
	btn &ui.Button
	dtw ui.DrawTextWidget
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct ButtonFontParams {
	id           string
	dtw          ui.DrawTextWidget = ui.canvas_plus()
	text         string
	height       int
	width        int
	z_index      int
	tooltip      string
	tooltip_side ui.Side = .top
	radius       f64     = .25
	padding      f64
	bg_color     &gx.Color = 0
}

pub fn button_font(c ButtonFontParams) &ui.Button {
	b := &ui.Button{
		id: c.id
		text: c.text
		width_: c.width
		height_: c.height
		z_index: c.z_index
		bg_color: c.bg_color
		theme_cfg: ui.no_theme
		tooltip: ui.TooltipMessage{c.tooltip, c.tooltip_side}
		onclick: button_font_click
		radius: f32(c.radius)
		padding: f32(c.padding)
		ui: 0
	}
	mut fb := &ButtonFont{
		btn: b
		dtw: c.dtw
	}
	ui.component_connect(fb, b)
	return b
}

pub fn component_button_font(w ui.ComponentChild) &ButtonFont {
	return &ButtonFont(w.component)
}

fn button_font_click(a voidptr, mut b ui.Button) {
	fb := component_button_font(b)
	// println('fb_click $fb.dtw.id')
	fontchooser_connect(b.ui.window, fb.dtw)
	fontchooser_subwindow_visible(b.ui.window)
	mut s := b.ui.window.subwindow(fontchooser_subwindow_id)
	if s.x == 0 && s.y == 0 {
		w, h := b.size()
		s.set_pos(b.x + w / 2, b.y + h / 2)
		s.update_layout()
	}
}
