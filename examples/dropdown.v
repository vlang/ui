import ui

const win_width = 250
const win_height = 250

fn dd_change(dd &ui.Dropdown) {
	println(dd.selected().text)
}

fn main() {
	window := ui.window(
		width:    win_width
		height:   win_height
		title:    'Dropdown'
		children: [
			ui.column(
				margin:   ui.Margin{5, 5, 5, 5}
				children: [
					ui.dropdown(
						width:                140
						def_text:             'Select an option'
						on_selection_changed: dd_change
						items:                [
							ui.DropdownItem{
								text: 'Delete all users'
							},
							ui.DropdownItem{
								text: 'Export users'
							},
							ui.DropdownItem{
								text: 'Exit'
							},
						]
					),
				]
			),
		]
	)
	ui.run(window)
}
