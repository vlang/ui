import ui

fn main() {
	r := ui.column(
		widths: ui.stretch
		margin_: 5
		spacing: 10
		children: [
			ui.radio(
				horizontal: true
				values: ['United States', 'Canada', 'United Kingdom', 'Australia']
				title: 'Country'
			),
			ui.radio(
				values: ['United States', 'Canada', 'United Kingdom', 'Australia']
				title: 'Country'
			),
			ui.row(
				widths: [ui.compact, ui.stretch]
				children: [ui.label(text: 'Country:'),
					ui.radio(
					horizontal: true
					values: ['United States', 'Canada', 'United Kingdom', 'Australia']
				),
				]
			),
		]
	)
	w := ui.window(
		width: 500
		height: 200
		mode: .resizable
		children: [r]
	)
	ui.run(w)
}
