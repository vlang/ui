import ui

fn main() {
	window := ui.window(
		width: 400
		height: 300
		title: 'CRUD'
		mode: .resizable
		children: [
			ui.column(
				spacing: 5
				margin_: 10
				widths: ui.stretch
				heights: [ui.compact, ui.stretch, ui.compact]
				children: [
					ui.row(
						widths: ui.stretch
						children: [
							ui.row(
								widths: [70.0, ui.stretch]
								children: [ui.label(text: 'Filter prefix:', justify: ui.center_left),
									ui.textbox()]
							),
							ui.spacing(),
						]
					),
					ui.row(
						widths: ui.stretch
						children: [
							ui.listbox(),
							ui.column(
								margin_: 5
								spacing: 5
								heights: ui.compact
								children: [
									ui.row(
										widths: [60.0, ui.stretch]
										children: [ui.label(text: 'Name:', justify: ui.center_left),
											ui.textbox()]
									),
									ui.row(
										widths: [60.0, ui.stretch]
										children: [ui.label(
											text: 'Surname:'
											justify: ui.center_left
										),
											ui.textbox()]
									),
								]
							),
						]
					),
					ui.row(
						margin_: 5
						spacing: 10
						widths: ui.compact
						heights: 30.0
						children: [
							ui.button(text: 'Create', radius: 5),
							ui.button(text: 'Update', radius: 5),
							ui.button(text: 'Delete', radius: 5),
						]
					),
				]
			),
		]
	)
	ui.run(window)
}
