import ui
import ui.component as uic
import gx

fn main() {
	n := 100
	tbm := 'toto bbub jhuui jkhuhui hubhuib\ntiti tutu toto\ntata tata'.repeat(1000)
	window := ui.window(
		width: 800
		height: 600
		title: 'V UI: SplitPanel'
		mode: .resizable
		layout: uic.splitpanel_stack(
			id: 'column'
			weight: 33
			direction: .column
			child1: ui.rectangle(
				color: gx.rgb(100, 255, 100)
			)
			child2: uic.splitpanel_stack(
				weight: 25.0
				child1: ui.rectangle(
					color: gx.rgb(100, 255, 100)
				)
				child2: uic.splitpanel_stack(
					id: 'row'
					// direction: .column
					weight: 33
					child2: uic.datagrid_stack(
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
					child1: ui.textbox(
						mode: .multiline
						id: 'tbm'
						text: &tbm
						height: 200
						text_size: 24
						bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
					)
				)
			)
		)
	)
	ui.run(window)
}
