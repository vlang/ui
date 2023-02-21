module component

import ui

type MessageBoxFn = fn (&MessageBoxComponent)

[heap]
pub struct MessageBoxComponent {
	id       string
	layout   &ui.Stack
	tb       &ui.TextBox
	btn      &ui.Button
	text     string
	on_click MessageBoxFn
}

[params]
pub struct MessageBoxParams {
	id       string
	text     string
	on_click MessageBoxFn
	width    int
	height   int
}

// TODO: documentation
pub fn messagebox_stack(p MessageBoxParams) &ui.Stack {
	mut tb := ui.textbox(
		id: ui.component_id(p.id, 'textbox')
		mode: .multiline | .read_only
		text_size: 24
		bg_color: ui.color_solaris_transparent
	)
	ok_btn := ui.button(
		id: ui.component_id(p.id, 'ok_btn')
		text: 'Ok'
		on_click: messagebox_ok_click
	)
	layout := ui.column(
		id: ui.component_id(p.id, 'layout')
		width: p.width
		height: p.height
		heights: [ui.stretch, 30]
		children: [tb, ok_btn]
	)
	hc := &MessageBoxComponent{
		id: p.id
		layout: layout
		text: p.text
		tb: tb
		btn: ok_btn
		on_click: p.on_click
	}
	unsafe {
		tb.text = &hc.text
	}
	ui.component_connect(hc, layout, tb, ok_btn)
	return layout
}

// component access
pub fn messagebox_component(w ui.ComponentChild) &MessageBoxComponent {
	return unsafe { &MessageBoxComponent(w.component) }
}

// TODO: documentation
pub fn messagebox_component_from_id(w ui.Window, id string) &MessageBoxComponent {
	return messagebox_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

fn messagebox_ok_click(b &ui.Button) {
	hc := messagebox_component(b)
	if hc.on_click != MessageBoxFn(0) {
		hc.on_click(hc)
	}
}
