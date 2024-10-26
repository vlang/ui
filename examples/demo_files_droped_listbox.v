import ui

fn main() {
	window := ui.window(
		mode:   .resizable
		height: 240
		layout: ui.row(
			widths:   ui.stretch
			children: [
				ui.listbox(
					id:            'lb'
					draw_lines:    true
					files_dropped: true
				),
			]
		)
	)
	ui.run(window)
}
