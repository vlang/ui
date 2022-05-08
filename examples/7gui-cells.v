import ui

fn main() {
	window := ui.window(
		width: 800
		height: 600
		title: 'Cells'
		mode: .resizable
		children: [
			ui.row(
				spacing: 5
				margin_: 10
				widths: ui.stretch
				heights: ui.stretch
				children: []
			),
		]
	)
	ui.run(window)
}
