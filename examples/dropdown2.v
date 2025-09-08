import ui
import gg

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
				margin_:  5
				widths:   ui.compact
				children: [
					ui.dropdown(
						width:                140
						def_text:             'Select an option'
						text_color:           gg.blue
						text_size:            20
						bg_color:             gg.light_blue
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
					ui.rectangle(
						height: 100
						width:  250
						color:  gg.rgb(100, 255, 100)
					),
				]
			),
		]
	)
	ui.run(window)
}
