import ui
import gx

const (
	win_width  = 400
	win_height = 300
)

fn main() {
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Rectangles inside BoxLayout'
		mode: .resizable
		children: [
			ui.box_layout(
				id: 'bl'
				children: {
					'id1@0x0x30x30':       ui.rectangle(
						color: gx.rgb(255, 100, 100)
					)
					'id2@30,30,0.5,0.5':   ui.rectangle(
						color: gx.rgb(100, 255, 100)
					)
					'id3@0.5x0.5x0.5x0.5': ui.rectangle(
						color: gx.rgb(100, 100, 255)
					)
				}
			),
		]
	)
	ui.run(window)
}
