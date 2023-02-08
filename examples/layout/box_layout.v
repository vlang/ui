import ui
import gx

const (
	win_width  = 400
	win_height = 300
)

window := ui.window(
	width: win_width
	height: win_height
	title: 'V UI: Rectangles inside BoxLayout'
	mode: .resizable
	children: [
		ui.box_layout(
			id: 'bl'
			children: {
				'id1: 0,0,30,30':         ui.rectangle(
					color: gx.rgb(255, 100, 100)
				)
				'id2: 30,30 x 0.5,0.5':   ui.rectangle(
					color: gx.rgb(100, 255, 100)
				)
				'id3: 0.5,0.5 x 1.0,1.0': ui.rectangle(
					color: gx.rgb(100, 100, 255)
				)
			}
		),
	]
)
ui.run(window)
