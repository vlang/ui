module component

import ui

[heap]
pub struct DemoComponent {
pub mut:
	layout   &ui.Stack = unsafe { nil } // required
	tb_text  string    = 'textbox text'
	tbm_text string    = 'textbox multilines text\nsecond line'
}

[params]
pub struct DemoParams {
	id string = 'demo'
}

pub fn demo_stack(p DemoParams) &ui.Stack {
	mut dc := &DemoComponent{}
	menu_items := [
		ui.menuitem(
			text: 'Delete'
			submenu: ui.menu(
				items: [
					ui.menuitem(
						text: 'all developers'
						action: menu_click
					),
					ui.menuitem(
						text: 'users'
						submenu: ui.menu(
							items: [
								ui.menuitem(
									text: 'all1'
									action: menu_click
								),
								ui.menuitem(
									text: 'devel1'
									submenu: ui.menu(
										items: [
											ui.menuitem(
												text: 'all2'
												action: menu_click
											),
											ui.menuitem(
												text: 'devel2'
												submenu: ui.menu(
													items: [
														ui.menuitem(
															text: 'all3'
															action: menu_click
														),
														ui.menuitem(
															text: 'devel3'
															action: menu_click
														),
													]
												)
											),
										]
									)
								),
							]
						)
					),
				]
			)
		),
		ui.menuitem(
			text: 'Export users'
			action: menu_click
		),
		ui.menuitem(text: 'Exit', action: menu_click),
		ui.menuitem(
			text: 'devel'
			submenu: ui.menu(
				items: [
					ui.menuitem(
						text: 'all4'
						action: menu_click
					),
					ui.menuitem(
						text: 'devel4'
						submenu: ui.menu(
							items: [
								ui.menuitem(
									text: 'all5'
									action: menu_click
								),
								ui.menuitem(
									text: 'devel5'
									action: menu_click
								),
							]
						)
					),
				]
			)
		),
	]
	layout := ui.column(
		scrollview: true
		id: ui.component_id(p.id, 'layout')
		margin_: 10
		spacing: 10
		widths: ui.compact
		children: [
			ui.menubar(
				id: 'menubar'
				items: menu_items
			),
			ui.button(id: 'btn', text: 'Ok', hoverable: true),
			ui.label(id: 'lbl', text: 'Label'),
			ui.textbox(id: 'tb', text: &dc.tb_text, width: 100),
			ui.checkbox(id: 'cb_true', checked: true, text: 'checkbox checked'),
			ui.checkbox(id: 'cb', text: 'checkbox unchecked'),
			ui.radio(
				width: 200
				values: ['United States', 'Canada', 'United Kingdom', 'Australia']
				title: 'Country'
			),
			ui.textbox(
				mode: .multiline
				id: 'tbm'
				text: &dc.tbm_text
				height: 200
				width: 400
				text_size: 18
			),
		]
	)
	dc.layout = layout
	return layout
}

fn menu_click(item &ui.MenuItem) {
	println('$item.text selected (id: $item.id)')
}
