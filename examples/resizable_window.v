import ui
import gx

const (
	win_width  = 250
	win_height = 250
)

struct App {
mut:
	window &ui.Window = 0
}

fn main() {
	mut app := &App{}
	window := ui.window(
		width: win_width
		height: win_height
		title: 'Resizable Window'
		resizable: true
		state: app
		children: [
			ui.row(
				margin_: .3
				widths: .4
				heights: .4
				bg_color: gx.rgba(255, 0, 0, 20)
				children: [
					ui.button(text: 'Add user'),
				]
			),
		]
	)
	app.window = window
	ui.run(window)
}
