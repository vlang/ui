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
			ui.row(
				margin_: 20
				widths: ui.stretch
				heights: ui.stretch
				children: [
					ui.box_layout(
						id: 'bl'
						children: {
							'id1: (0,0) ++ (0.3,0.3)':     ui.rectangle(
								color: gx.rgb(255, 100, 100)
							)
							'id2: (0.3,0.3) ++ (0.4,0.4)': ui.rectangle(
								color: gx.rgb(100, 255, 100)
							)
							'id3: (0.7,0.7) ++ (0.3,0.3)': ui.rectangle(
								color: gx.rgb(100, 100, 255)
							)
						}
					),
				]
			),
		]
	)
	ui.run(window)
}
