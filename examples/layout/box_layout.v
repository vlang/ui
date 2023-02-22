import ui
import gx

const (
	win_width  = 400
	win_height = 300
)

fn main() {
	ui.run(ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Rectangles inside BoxLayout'
		mode: .resizable
		layout: ui.box_layout(
			id: 'bl'
			children: {
				'id1: (0,0) ++ (30,30)':          ui.rectangle(
					color: gx.rgb(255, 100, 100)
				)
				'id2: (30,30) -> (-30.5,-30.5)':  ui.rectangle(
					color: gx.rgb(100, 255, 100)
				)
				'id3: (0.5,0.5) ->  (1,1)':       ui.rectangle(
					color: gx.rgb(100, 100, 255)
				)
				'id4: (-30.5, -30.5) ++ (30,30)': ui.rectangle(
					color: gx.white
				)
			}
		)
	))
}
