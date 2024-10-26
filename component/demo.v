module component

import ui

// demo component to test all the widgets

@[heap]
pub struct DemoComponent {
pub mut:
	layout   &ui.Stack = unsafe { nil } // required
	tb_text  string    = 'textbox text'
	tbm_text string    = 'textbox multilines text\nsecond line\n' + ('blah blah'.repeat(10) +
	'blah\n').repeat(20)
}

@[params]
pub struct DemoParams {
pub:
	id string = 'demo'
}

// TODO: documentation
pub fn demo_stack(p DemoParams) &ui.Stack {
	mut dc := &DemoComponent{}
	menu_items := [
		ui.menuitem(
			text:    'Delete'
			submenu: ui.menu(
				items: [
					ui.menuitem(
						text:   'all developers'
						action: menu_click
					),
					ui.menuitem(
						text:    'users'
						submenu: ui.menu(
							items: [
								ui.menuitem(
									text:   'all1'
									action: menu_click
								),
								ui.menuitem(
									text:    'devel1'
									submenu: ui.menu(
										items: [
											ui.menuitem(
												text:   'all2'
												action: menu_click
											),
											ui.menuitem(
												text:    'devel2'
												submenu: ui.menu(
													items: [
														ui.menuitem(
															text:   'all3'
															action: menu_click
														),
														ui.menuitem(
															text:   'devel3'
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
			text:   'Export users'
			action: menu_click
		),
		ui.menuitem(text: 'Exit', action: menu_click),
		ui.menuitem(
			text:    'Devel'
			submenu: ui.menu(
				items: [
					ui.menuitem(
						text:   'all4'
						action: menu_click
					),
					ui.menuitem(
						text:    'devel4'
						submenu: ui.menu(
							items: [
								ui.menuitem(
									text:   'all5'
									action: menu_click
								),
								ui.menuitem(
									text:   'devel5'
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
		id:       ui.component_id(p.id, 'layout')
		margin_:  10
		spacing:  10
		widths:   ui.stretch
		children: [
			ui.menubar(
				id:    'mb'
				items: menu_items
			),
			ui.row(
				widths:   ui.stretch
				spacing:  10
				children: [
					ui.column(
						margin_:  10
						spacing:  10
						children: [
							ui.button(id: 'btn', text: 'Ok', hoverable: true),
							ui.label(id: 'lbl', text: 'Label'),
							ui.checkbox(id: 'cb_true', checked: true, text: 'checkbox checked'),
							ui.checkbox(id: 'cb', text: 'checkbox unchecked'),
							ui.radio(
								width:  200
								values: ['United States', 'Canada', 'United Kingdom', 'Australia']
								title:  'Country'
							),
							ui.progressbar(
								id:  'pb'
								max: 10
								val: 2
							),
							ui.slider(id: 'sl', orientation: .horizontal, min: 0, max: 10, val: 2),
							ui.dropdown(
								id:       'dd'
								width:    140
								def_text: 'Select an option'
								// on_selection_changed: dd_change
								items: [ui.DropdownItem{
									text: 'Delete all users'
								}, ui.DropdownItem{
									text: 'Export users'
								}, ui.DropdownItem{
									text: 'Exit'
								}]
							),
						]
					),
					ui.column(
						margin_:  10
						spacing:  10
						children: [
							ui.textbox(id: 'tb', text: &dc.tb_text, width: 100),
							ui.textbox(
								mode:      .multiline
								id:        'tbm'
								text:      &dc.tbm_text
								height:    200
								width:     400
								text_size: 18
							),
							ui.listbox(
								id:      'lb'
								width:   100
								height:  100
								z_index: 10
								// on_change: lb_change_multi
								scrollview: false
								// selectable: false
								ordered:    true
								multi:      true
								draw_lines: true
								items:      {
									'classic': 'Classic'
									'blue':    'Blue'
									'red':     'Red'
								}
							),
						]
					),
				]
			),
		]
	)
	dc.layout = layout
	return layout
}

fn menu_click(item &ui.MenuItem) {
	println('${item.text} selected (id: ${item.id})')
}
