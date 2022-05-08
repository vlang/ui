import ui
import gx

fn main() {
	window := ui.window(
		width: 200
		height: 110
		title: 'Flight booker'
		mode: .resizable
		children: [
			ui.column(
				spacing: 5
				margin_: 5
				// widths: ui.stretch
				// heights: ui.stretch
				children: [
					ui.dropdown(
						id: 'dd'
						z_index: 10
						selected_index: 0
						items: [
							ui.DropdownItem{
								text: 'one-way flight'
							},
							ui.DropdownItem{
								text: 'return flight'
							},
						]
					),
					ui.textbox(id: 'tb1'),
					ui.textbox(id: 'tb2'),
					ui.button(id: 'btn', text: 'Book', radius: 5, bg_color: gx.light_gray),
				]
			),
		]
	)
	ui.run(window)
}
