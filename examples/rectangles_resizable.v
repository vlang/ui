import ui
import gx

const (
	win_width  = 64 * 4 + 25
	win_height = 74
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	rect := ui.rectangle(
		height: 64
		width: 64
		color: gx.rgb(255, 100, 100)
		radius: 10
		text: 'Red'
	)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Rectangles'
		state: app
		mode: .max_size
		// on_key_down: fn(e ui.KeyEvent, wnd &ui.Window) {
		// println('key down')
		//}
		children: [
			ui.row(
				alignment: .center
				spacing: 5
				margin: ui.Margin{5, 5, 5, 5}
				widths: ui.stretch
				children: [
					rect,
					ui.rectangle(color: gx.rgb(100, 255, 100), radius: 10, text: 'Green'),
					ui.rectangle(color: gx.rgb(100, 100, 255), radius: 10, text: 'Blue'),
					ui.rectangle(color: gx.rgb(255, 100, 255), radius: 10, text: 'Pink'),
				]
			),
		]
	)
	app.window = window
	ui.run(window)
}
