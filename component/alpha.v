module component

import ui

type AlphaFn = fn (ac &AlphaComponent)

@[heap]
pub struct AlphaComponent {
pub mut:
	id         string
	alpha      int
	layout     &ui.Stack   = unsafe { nil }
	slider     &ui.Slider  = unsafe { nil }
	textbox    &ui.TextBox = unsafe { nil }
	on_changed AlphaFn     = unsafe { AlphaFn(0) }
}

@[params]
pub struct AlphaParams {
pub:
	id         string
	alpha      int
	direction  ui.Direction = .column
	on_changed AlphaFn      = unsafe { AlphaFn(0) }
}

// TODO: documentation
pub fn alpha_stack(p AlphaParams) &ui.Stack {
	tb := ui.textbox(
		id:         ui.component_id(p.id, 'textbox')
		is_numeric: true
		max_len:    3
		on_char:    alpha_on_char
	)
	sl := ui.slider(
		id:               ui.component_id(p.id, 'slider')
		orientation:      if p.direction == .row {
			ui.Orientation.horizontal
		} else {
			ui.Orientation.vertical
		}
		min:              0
		max:              255
		val:              p.alpha
		on_value_changed: alpha_on_value_changed
	)
	mut layout := match p.direction {
		.row {
			ui.row(
				id:       ui.component_id(p.id, 'layout')
				widths:   [20.0, 40]
				margin_:  5
				spacing:  10
				children: [tb, sl]
			)
		}
		.column {
			ui.column(
				id:       ui.component_id(p.id, 'layout')
				heights:  [20.0, 40]
				margin_:  5
				spacing:  10
				children: [tb, sl]
			)
		}
	}
	mut ac := &AlphaComponent{
		id:         p.id
		layout:     layout
		alpha:      p.alpha
		textbox:    tb
		slider:     sl
		on_changed: p.on_changed
	}
	ac.set_alpha(p.alpha)
	ui.component_connect(ac, layout, tb, sl)
	return layout
}

// component access
pub fn alpha_component(w ui.ComponentChild) &AlphaComponent {
	return unsafe { &AlphaComponent(w.component) }
}

// TODO: documentation
pub fn alpha_component_from_id(w ui.Window, id string) &AlphaComponent {
	return alpha_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

// TODO: documentation
pub fn (mut ac AlphaComponent) set_alpha(alpha int) {
	if ui.is_rgb_valid(alpha) {
		ac.alpha = alpha
		ac.textbox.set_text(alpha.str())
		ac.slider.val = f32(alpha)
	}
}

fn alpha_on_value_changed(slider &ui.Slider) {
	mut ac := alpha_component(slider)
	ac.alpha = int(slider.val)
	ac.textbox.set_text(ac.alpha.str())
	ac.textbox.border_accentuated = false
	if ac.on_changed != unsafe { AlphaFn(0) } {
		ac.on_changed(ac)
	}
}

fn alpha_on_char(textbox &ui.TextBox, keycode u32) {
	mut ac := alpha_component(textbox)
	if ui.is_rgb_valid(textbox.text.int()) {
		ac.alpha = textbox.text.int()
		ac.slider.val = textbox.text.f32()
		ac.textbox.border_accentuated = false
		if ac.on_changed != unsafe { AlphaFn(0) } {
			ac.on_changed(ac)
		}
	} else {
		ac.textbox.border_accentuated = true
	}
}
