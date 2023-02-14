module component

import ui
import gx

type ColorButtonFn = fn (b &ColorButtonComponent)

[heap]
pub struct ColorButtonComponent {
pub mut:
	widget     &ui.Button
	bg_color   gx.Color = gx.white
	alpha      int
	on_click   ColorButtonFn
	on_changed ColorButtonFn
	left_side  bool
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
	radius       f64 // = 5.0
	padding      f64
	left_side    bool
	bg_color     &gx.Color = unsafe { nil }
	on_click     ColorButtonFn
	on_changed   ColorButtonFn
}

// TODO: documentation
pub fn colorbutton(c ColorButtonParams) &ui.Button {
	mut b := &ui.Button{
		id: c.id
		width_: c.width
		height_: c.height
		z_index: c.z_index
		bg_color: c.bg_color
		// theme_cfg: ui.no_theme
		tooltip: ui.TooltipMessage{c.tooltip, c.tooltip_side}
		on_click: colorbutton_click
		style_params: ui.button_style(radius: f32(c.radius))
		padding: f32(c.padding)
		// ui: 0
	}
	cbc := &ColorButtonComponent{
		widget: b
		on_click: c.on_click
		on_changed: c.on_changed
		left_side: c.left_side
	}
	if unsafe { b.bg_color == 0 } {
		b.bg_color = &cbc.bg_color
	}
	ui.component_connect(cbc, b)
	return b
}

// component access
pub fn colorbutton_component(w ui.ComponentChild) &ColorButtonComponent {
	return unsafe { &ColorButtonComponent(w.component) }
}

// TODO: documentation
pub fn colorbutton_component_from_id(w ui.Window, id string) &ColorButtonComponent {
	return colorbutton_component(w.get_or_panic[ui.Button](id))
}

fn colorbutton_click(mut b ui.Button) {
	cbc := colorbutton_component(b)
	// println("here $b.ui.keymods")
	if b.ui.btn_down[1] {
		colorbox_subwindow_connect(b.ui.window, b.bg_color, cbc, .toggle)
		// move only if s.x and s.y == 0 first use
		mut s := b.ui.window.get_or_panic[ui.SubWindow](colorbox_subwindow_id)
		if s.x == 0 && s.y == 0 {
			w, h := b.size()
			if cbc.left_side {
				sw, _ := s.size()
				s.set_pos(b.x + w / 2 - sw, b.y + h / 2)
			} else {
				s.set_pos(b.x + w / 2, b.y + h / 2)
			}
			s.update_layout()
		}
	} else {
		mut s := b.ui.window.get_or_panic[ui.SubWindow](colorbox_subwindow_id)
		if s.is_visible() {
			colorbox_subwindow_connect(b.ui.window, b.bg_color, cbc, .show)
		}
	}
	// on_click initialization if necessary
	if cbc.on_click != ColorButtonFn(0) {
		cbc.on_click(cbc)
	}
}
