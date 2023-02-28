import ui
import ui.component as uic
import gx

const (
	win_width  = 600
	win_height = 600
)

fn main() {
	n := 1000000
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Grid'
		native_message: false
		mode: .resizable
		bg_color: gx.white
		on_init: win_init
		layout: uic.datagrid_stack(
			id: 'grid'
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
		)
	)
	ui.run(window)
}

fn win_init(w &ui.Window) {
	// mut g := uic.grid_component_from_id(w, "grid")
	// g.init_ranked_grid_data([2, 0], [1, -1])

	// mut gs := uic.gridsettings_component_from_id(w, "gs")
	// println("gs id: <$gs.id> ${typeof(gs).name} $gsl.id")
	// gs.update_sorted_vars()
}
