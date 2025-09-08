import ui
import gg

fn main() {
	ui.run(ui.window(
		width:  300
		height: 100
		title:  'Name'
		layout: ui.box_layout(
			children: {
				'rect: stretch': ui.rectangle(color: gg.white)
				'lab: stretch':  ui.label(
					text:    'Centered text'
					justify: ui.center
				)
			}
		)
	))
}
