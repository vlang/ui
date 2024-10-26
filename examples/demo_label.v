import ui
import gx

fn main() {
	ui.run(ui.window(
		width:  300
		height: 100
		title:  'Name'
		layout: ui.box_layout(
			children: {
				'rect: stretch': ui.rectangle(color: gx.white)
				'lab: stretch':  ui.label(
					text:    'Centered text'
					justify: ui.center
				)
			}
		)
	))
}
