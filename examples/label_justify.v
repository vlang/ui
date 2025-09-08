import ui
import gg

fn main() {
	layout := ui.box_layout(
		children: {
			'rect: (0.2, 0.4) -> (0.5,0.5)':  ui.rectangle(
				color: ui.alpha_colored(gg.yellow, 30)
			)
			'rect2: (0.5, 0.5) -> (1,1)':     ui.rectangle(
				color: ui.alpha_colored(gg.blue, 30)
			)
			'rect3: (0.1, 0.1) -> (0.3,0.2)': ui.rectangle(
				color: ui.alpha_colored(gg.orange, 30)
			)
			'lab: (0.2, 0.4) -> (0.5,0.5)':   ui.label(
				text:    'Centered text'
				justify: ui.center // [0.5, 0.5]
			)
			'lab2: (0.5, 0.5) -> (1,1)':      ui.label(
				text:    'Centered text\n2nd line\n3rd line'
				justify: ui.top_center // [0.0, 0.5]
			)
			'lab3: (0.1, 0.1) -> (0.3,0.2)':  ui.label(
				text:     'long texttttttttttttttttttttttttttttttttt'
				clipping: true
			)
		}
	)
	ui.run(ui.window(
		title:  'Label jusify'
		mode:   .resizable
		layout: layout
	))
}
