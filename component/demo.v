module component

import ui

[heap]
pub struct DemoComponent {
pub mut:
	layout  &ui.Stack = unsafe { nil } // required
	tb_text string    = 'textbox text'
}

[params]
pub struct DemoParams {
	id string = 'demo'
}

pub fn demo_stack(p DemoParams) &ui.Stack {
	mut dc := &DemoComponent{}
	layout := ui.column(
		id: ui.component_id(p.id, 'layout')
		margin_: 10
		spacing: 10
		widths: ui.compact
		children: [
			ui.button(id: 'btn', text: 'Ok', hoverable: true),
			ui.label(id: 'lbl', text: 'Label'),
			ui.textbox(id: 'tb', text: &dc.tb_text, width: 100),
			ui.checkbox(id: 'cb_true', checked: true, text: 'checkbox checked'),
			ui.checkbox(id: 'cb', text: 'checkbox unchecked'),
		]
	)
	dc.layout = layout
	return layout
}
