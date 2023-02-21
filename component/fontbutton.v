module component

import ui
import gx

[heap]
pub struct FontButtonComponent {
pub mut:
	btn &ui.Button
	dtw ui.DrawTextWidget
}

[params]
pub struct FontButtonParams {
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
	bg_color     &gx.Color = unsafe { nil }
}

// TODO: documentation
pub fn fontbutton(c FontButtonParams) &ui.Button {
	b := &ui.Button{
		id: c.id
		text: c.text
		width_: c.width
		height_: c.height
		z_index: c.z_index
		bg_color: c.bg_color
		// theme_cfg: ui.no_theme
		tooltip: ui.TooltipMessage{c.tooltip, c.tooltip_side}
		on_click: font_button_click
		style_params: ui.button_style(radius: f32(c.radius))
		padding: f32(c.padding)
		ui: 0
	}
	mut fb := &FontButtonComponent{
		btn: b
		dtw: c.dtw
	}
	ui.component_connect(fb, b)
	return b
}

// TODO: documentation
pub fn fontbutton_component(w ui.ComponentChild) &FontButtonComponent {
	return unsafe { &FontButtonComponent(w.component) }
}

// TODO: documentation
pub fn fontbutton_component_from_id(w ui.Window, id string) &FontButtonComponent {
	return fontbutton_component(w.get_or_panic[ui.Button](id))
}

fn font_button_click(mut b ui.Button) {
	fb := fontbutton_component(b)
	// println('fb_click $fb.dtw.id')
	fontchooser_connect(b.ui.window, fb.dtw)
	fontchooser_subwindow_visible(b.ui.window)
	mut s := b.ui.window.get_or_panic[ui.SubWindow](fontchooser_subwindow_id)
	if s.x == 0 && s.y == 0 {
		w, h := b.size()
		s.set_pos(b.x + w / 2, b.y + h / 2)
		s.update_layout()
	}
}
