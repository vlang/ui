import ui
import ui.component as uic
import gx

const (
	win_width  = 800
	win_height = 600
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Accordion'
		state: app
		native_message: false
		mode: .resizable
		children: [
			uic.grid(),
		]
	)
	app.window = window
	ui.run(window)
}
