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
		on_init: win_init
		children: [
			ui.row(
				widths: [ui.stretch, 3 * ui.stretch]
				children: [ui.rectangle(color: gx.red),
					ui.column(
					// scrollview: true
					widths: ui.stretch
					heights: [ui.stretch, 3 * ui.stretch]
					children: [ui.rectangle(color: gx.red),
						uic.datagrid_stack(
						id: 'grid2'
						scrollview: true
						is_focused: true
						// fixed_height: false
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
					)]
				)]
			),
		]
	)
	app.window = window
	ui.run(window)
}

fn win_init(w &ui.Window) {
	// l := w.canvas_layout('grid_layout')
	// mut g := uic.component_grid(l)
	// g.init_ranked_grid_data([2, 0], [1, 2])
}
