import ui

fn main() {
	ui.run(ui.window(
		width: 300
		height: 100
		title: 'Name'
		layout: ui.column(
			// margin_: 20
			widths: ui.stretch
			heights: ui.compact
			children: [
				ui.label(
					text: 'Centered text'
					justify: [0.5, 0.75]
					// text_align: .center
				),
			]
		)
	))
}
