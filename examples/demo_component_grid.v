import ui
import ui.component as uic
import gx

const (
	win_width  = 600
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
	n := 1000000
	gl := uic.grid(
		id: 'grid'
		scrollview: true
		is_focused: true
		vars: {
			'v1':   ['toto', 'titi', 'tata'].repeat(n)
			'v2':   ['toti', 'tito', 'tato'].repeat(n)
			'sex':  uic.Factor{
				levels: ['Male', 'Female']
				values: [0, 0, 1].repeat(n)
			}
			'csp':  uic.Factor{
				levels: ['job1', 'job2', 'other']
				values: [0, 1, 2].repeat(n)
			}
			'v3':   ['toto', 'titi', 'tata'].repeat(n)
			'v4':   ['toti', 'tito', 'tato'].repeat(n)
			'sex2': uic.Factor{
				levels: ['Male', 'Female']
				values: [0, 0, 1].repeat(n)
			}
			'csp2': uic.Factor{
				levels: ['job1', 'job2', 'other']
				values: [0, 1, 2].repeat(n)
			}
		}
		keymaps: {
			15: uic.GridKey{
				key: false
				mods: .ctrl
				cb: fn (g &uic.Grid) {
					l := g.layout.ui.window.stack('hgs_layout')
					mut h := uic.component_hideable(l)
					h.toggle()
				}
			}
		}
	)
	g := uic.component_grid(gl)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Grid'
		state: app
		native_message: false
		mode: .resizable
		bg_color: gx.white
		on_init: win_init
		children: [
			ui.row(
				widths: [ui.stretch * 3, ui.stretch]
				children: [gl,
					uic.hideable(
					id: 'hgs'
					layout: uic.gridsettings(
						id: 'gs'
						grid: g
					)
				)]
			),
		]
	)
	app.window = window
	ui.run(window)
}

fn win_init(w &ui.Window) {
	// lg := w.canvas_layout('grid_layout')
	// mut g := uic.component_grid(lg)
	// g.init_ranked_grid_data([2, 0], [1, -1])

	// gsl := w.stack('gs_layout')
	// mut gs := uic.component_gridsettings(gsl)
	// println("gs id: <$gs.id> ${typeof(gs).name} $gsl.id")
	// gs.update_sorted_vars()
}
