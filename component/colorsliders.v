module component

import ui
import gx

const slider_min = 0
const slider_max = 255
const slider_val = (slider_max + slider_min) / 2

type ColorSlidersFn = fn (cs &ColorSlidersComponent)

@[heap]
pub struct ColorSlidersComponent {
	id string
pub mut:
	layout         &ui.Stack = unsafe { nil } // required
	orientation    ui.Orientation
	r_slider       &ui.Slider  = unsafe { nil }
	r_textbox      &ui.TextBox = unsafe { nil }
	g_slider       &ui.Slider  = unsafe { nil }
	g_textbox      &ui.TextBox = unsafe { nil }
	b_slider       &ui.Slider  = unsafe { nil }
	b_textbox      &ui.TextBox = unsafe { nil }
	r_textbox_text string
	g_textbox_text string
	b_textbox_text string
	on_changed     ColorSlidersFn = unsafe { ColorSlidersFn(0) }
}

@[params]
pub struct ColorSlidersParams {
pub:
	id          string
	color       gx.Color       = gx.white
	orientation ui.Orientation = .vertical
	on_changed  ColorSlidersFn = unsafe { ColorSlidersFn(0) }
}

// TODO: documentation
pub fn colorsliders_stack(p ColorSlidersParams) &ui.Stack {
	r_textbox := ui.textbox(
		max_len:    3
		read_only:  false
		is_numeric: true
		on_char:    on_r_char
	)
	g_textbox := ui.textbox(
		max_len:    3
		read_only:  false
		is_numeric: true
		on_char:    on_g_char
	)
	b_textbox := ui.textbox(
		max_len:    3
		read_only:  false
		is_numeric: true
		on_char:    on_b_char
	)
	r_slider := ui.slider(
		orientation:         p.orientation
		min:                 slider_min
		max:                 slider_max
		val:                 p.color.r
		focus_on_thumb_only: true
		rev_min_max_pos:     p.orientation == .vertical
		on_value_changed:    on_r_value_changed
		thumb_color:         gx.light_red
	)
	g_slider := ui.slider(
		orientation:         p.orientation
		min:                 slider_min
		max:                 slider_max
		val:                 p.color.g
		focus_on_thumb_only: true
		rev_min_max_pos:     p.orientation == .vertical
		on_value_changed:    on_g_value_changed
		thumb_color:         gx.light_green
	)
	b_slider := ui.slider(
		orientation:         p.orientation
		min:                 slider_min
		max:                 slider_max
		val:                 p.color.b
		focus_on_thumb_only: true
		rev_min_max_pos:     p.orientation == .vertical
		on_value_changed:    on_b_value_changed
		thumb_color:         gx.light_blue
	)
	valign := ui.TextVerticalAlign.top // if p.orientation == .vertical {ui.TextVerticalAlign.middle} else {ui.TextVerticalAlign.top}
	r_label := ui.label(text: 'R', justify: ui.top_center, text_vertical_align: valign)
	g_label := ui.label(text: 'G', justify: ui.top_center, text_vertical_align: valign)
	b_label := ui.label(text: 'B', justify: ui.top_center, text_vertical_align: valign)
	mut layout := if p.orientation == .vertical {
		w := [ui.stretch, 40.0, 2 * ui.stretch, 40, 2 * ui.stretch, 40, ui.stretch]
		ui.column(
			id:      ui.component_id(p.id, 'layout')
			margin_: 10
			spacing: 5
			// alignments: ui.HorizontalAlignments{
			// 	center: [0, 1, 2, 3]
			// }
			heights:  [ui.stretch, 5 * ui.stretch, ui.stretch]
			children: [
				ui.row(
					id:       ui.component_id(p.id, 'r_row')
					widths:   w
					children: [ui.spacing(), r_textbox, ui.spacing(), g_textbox, ui.spacing(),
						b_textbox, ui.spacing()]
				),
				ui.row(
					id:       ui.component_id(p.id, 'g_row')
					widths:   w
					children: [ui.spacing(), r_slider, ui.spacing(), g_slider, ui.spacing(),
						b_slider, ui.spacing()]
				),
				ui.row(
					id:       ui.component_id(p.id, 'b_row')
					widths:   w
					children: [ui.spacing(), r_label, ui.spacing(), g_label, ui.spacing(),
						b_label, ui.spacing()]
				),
			]
		)
	} else {
		h := [ui.stretch, ui.compact, 2 * ui.stretch, ui.compact, 2 * ui.stretch, ui.compact, ui.stretch]
		ui.row(
			id:      ui.component_id(p.id, 'layout')
			margin_: 10
			spacing: 5
			// alignments: ui.HorizontalAlignments{
			// 	center: [0, 1, 2, 3]
			// }
			widths:   [40.0, ui.stretch, 40.0]
			children: [
				ui.column(
					id:       ui.component_id(p.id, 'b_row')
					heights:  h
					children: [ui.spacing(), r_label, ui.spacing(), g_label, ui.spacing(),
						b_label, ui.spacing()]
				),
				ui.column(
					id:       ui.component_id(p.id, 'g_row')
					heights:  h
					children: [ui.spacing(), r_slider, ui.spacing(), g_slider, ui.spacing(),
						b_slider, ui.spacing()]
				),
				ui.column(
					id:       ui.component_id(p.id, 'r_row')
					heights:  h
					children: [ui.spacing(), r_textbox, ui.spacing(), g_textbox, ui.spacing(),
						b_textbox, ui.spacing()]
				),
			]
		)
	}

	mut cs := &ColorSlidersComponent{
		id:             p.id
		layout:         layout
		r_slider:       r_slider
		g_slider:       g_slider
		b_slider:       b_slider
		r_textbox:      r_textbox
		g_textbox:      g_textbox
		b_textbox:      b_textbox
		r_textbox_text: p.color.r.str()
		g_textbox_text: p.color.g.str()
		b_textbox_text: p.color.b.str()
		orientation:    p.orientation
		on_changed:     p.on_changed
	}

	cs.r_textbox.text = &cs.r_textbox_text
	cs.g_textbox.text = &cs.g_textbox_text
	cs.b_textbox.text = &cs.b_textbox_text
	ui.component_connect(cs, layout, r_slider, g_slider, b_slider, r_textbox, g_textbox,
		b_textbox)
	// layout.on_init = colorsliders_init
	return layout
}

// component access
pub fn colorsliders_component(w ui.ComponentChild) &ColorSlidersComponent {
	return unsafe { &ColorSlidersComponent(w.component) }
}

// TODO: documentation
pub fn colorsliders_component_from_id(w ui.Window, id string) &ColorSlidersComponent {
	return colorsliders_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

// TODO: documentation
pub fn (cs &ColorSlidersComponent) color() gx.Color {
	return gx.rgb(u8(cs.r_textbox.text.int()), u8(cs.g_textbox.text.int()), u8(cs.b_textbox.text.int()))
}

// TODO: documentation
pub fn (mut cs ColorSlidersComponent) set_color(color gx.Color) {
	cs.r_textbox_text = color.r.str()
	cs.g_textbox_text = color.g.str()
	cs.b_textbox_text = color.b.str()
	cs.r_slider.val = f32(color.r)
	cs.g_slider.val = f32(color.g)
	cs.b_slider.val = f32(color.b)
}

fn on_r_value_changed(slider &ui.Slider) {
	mut cs := colorsliders_component(slider)
	cs.r_textbox_text = int(cs.r_slider.val).str()
	cs.r_textbox.border_accentuated = false
	if cs.on_changed != unsafe { ColorSlidersFn(0) } {
		cs.on_changed(cs)
	}
}

fn on_g_value_changed(slider &ui.Slider) {
	mut cs := colorsliders_component(slider)
	cs.g_textbox_text = int(cs.g_slider.val).str()
	cs.g_textbox.border_accentuated = false
	if cs.on_changed != unsafe { ColorSlidersFn(0) } {
		cs.on_changed(cs)
	}
}

fn on_b_value_changed(slider &ui.Slider) {
	mut cs := colorsliders_component(slider)
	cs.b_textbox_text = int(cs.b_slider.val).str()
	cs.b_textbox.border_accentuated = false
	if cs.on_changed != unsafe { ColorSlidersFn(0) } {
		cs.on_changed(cs)
	}
}

fn on_r_char(textbox &ui.TextBox, keycode u32) {
	mut cs := colorsliders_component(textbox)
	if ui.is_rgb_valid(cs.r_textbox.text.int()) {
		cs.r_slider.val = cs.r_textbox_text.f32()
		cs.r_textbox.border_accentuated = false
	} else {
		cs.r_textbox.border_accentuated = true
	}
	if cs.on_changed != unsafe { ColorSlidersFn(0) } {
		cs.on_changed(cs)
	}
}

fn on_g_char(textbox &ui.TextBox, keycode u32) {
	mut cs := colorsliders_component(textbox)
	if ui.is_rgb_valid(cs.g_textbox.text.int()) {
		cs.g_slider.val = cs.g_textbox_text.f32()
		cs.g_textbox.border_accentuated = false
	} else {
		cs.g_textbox.border_accentuated = true
	}
	if cs.on_changed != unsafe { ColorSlidersFn(0) } {
		cs.on_changed(cs)
	}
}

fn on_b_char(textbox &ui.TextBox, keycode u32) {
	mut cs := colorsliders_component(textbox)
	if ui.is_rgb_valid(cs.b_textbox.text.int()) {
		cs.b_slider.val = cs.b_textbox_text.f32()
		cs.b_textbox.border_accentuated = false
	} else {
		cs.b_textbox.border_accentuated = true
	}
	if cs.on_changed != unsafe { ColorSlidersFn(0) } {
		cs.on_changed(cs)
	}
}
