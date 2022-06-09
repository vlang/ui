import ui

struct App {
mut:
	window &ui.Window = 0
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		mode: .resizable
		height: 240
		children: [
			ui.row(
				widths: ui.stretch
				children: [
					ui.listbox(
						id: 'lb'
						draw_lines: true
						files_droped: true
					),
				]
			),
		]
	)
	ui.run(app.window)
}
