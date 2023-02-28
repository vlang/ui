import ui
import ui.component as uic
import gx

const (
	win_width  = 800
	win_height = 600
)

fn main() {
	n := 300
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Grid 2'
		native_message: false
		mode: .resizable
		bg_color: gx.white
		on_init: win_init
		layout: ui.row(
			widths: [ui.stretch, 15 * ui.stretch]
			children: [ui.rectangle(color: gx.red),
				ui.column(
					// scrollview: true
					widths: ui.stretch
					heights: [ui.stretch, 15 * ui.stretch]
					children: [ui.rectangle(color: gx.red),
						uic.datagrid_stack(
							id: 'grid2'
							is_focused: true
							settings_bg_color: gx.hex(0xfcf4e4ff)
							// fixed_height: false
							vars: {
								'v1':     ['toto', 'titi', 'tata'].repeat(n)
								'v2':     ['toti', 'tito', 'tato'].repeat(n)
								'sex':    uic.Factor{
									levels: ['Male', 'Female']
									values: [0, 0, 1].repeat(n)
								}
								'worker': [true, true, false].repeat(n)
								'csp':    uic.Factor{
									levels: ['job1', 'job2', 'other']
									values: [0, 1, 2].repeat(n)
								}
								'v3':     ['toto', 'titi', 'tata'].repeat(n)
								'v4':     ['toti', 'tito', 'tato'].repeat(n)
								'sex2':   uic.Factor{
									levels: ['Male', 'Female']
									values: [0, 0, 1].repeat(n)
								}
								'csp2':   uic.Factor{
									levels: ['job1', 'job2', 'other']
									values: [0, 1, 2].repeat(n)
								}
							}
						)]
				)]
		)
	)
	ui.run(window)
}

fn win_init(w &ui.Window) {
	// mut g := uic.grid_component_from_id(w, "grid")
	// g.init_ranked_grid_data([2, 0], [1, 2])

	gc := uic.GridCell{12, 1208}
	// gc := uic.GridCell{0,1}
	ac := gc.alphacell()
	gc2 := uic.AlphaCell(ac).gridcell()
	println('${gc} -> ${ac} -> ${gc2}')
}
