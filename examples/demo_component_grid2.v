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
		title: 'V UI: Grid 2'
		state: app
		native_message: false
		mode: .resizable
		bg_color: gx.white
		children: [
			ui.column(
				// scrollview: true
				widths: ui.stretch
				heights: ui.stretch
				children: [
					uic.grid(
						id: 'grid'
						scrollview: true
						is_focused: true
						vars: {
							'v1':  ['toto', 'titi', 'tata'].repeat(300)
							'v2':  ['toti', 'tito', 'tato'].repeat(300)
							'sex': uic.Factor{
								levels: ['Male', 'Female']
								values: [0, 0, 1].repeat(300)
							}
							'csp': uic.Factor{
								levels: ['job1', 'job2', 'other']
								values: [0, 1, 2].repeat(300)
							}
						}
					),
				]
			),
		]
	)
	app.window = window
	ui.run(window)
}
