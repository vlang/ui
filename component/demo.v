module component

import ui

[heap]
pub struct DemoComponent {
pub mut:
	layout &ui.Stack // required
}

[params]
pub struct DemoParams {
	id string = 'demo'
}

pub fn demo_stack(p DemoParams) &ui.Stack {
	layout := ui.column(
		id: ui.component_id(p.id, 'layout')
		margin_: 10
		spacing: 10
		widths: ui.compact
		children: [
			ui.button(text: 'Ok', hoverable: true),
			ui.label(text: 'Label'),
		]
	)
	return layout
}
