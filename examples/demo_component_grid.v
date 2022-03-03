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
		bg_color: gx.white
		children: [
			uic.grid(
				id: 'grid'
				vars: {
					'v1': ['toto', 'titi', 'tata']
					'v2': ['toti', 'tito', 'tato']
					'v3': uic.Factor{
						levels: ['Male', 'Female']
						values: [0, 0, 1]
					}
				}
			),
		]
	)
	app.window = window
	ui.run(window)
}