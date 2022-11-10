import ui
import gx

const (
	win_width  = 400
	win_height = 300
)

fn main() {
	rect := ui.rectangle(
		height: 64
		width: 64
		color: gx.rgb(255, 100, 100)
	)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Rectangles'
		mode: .resizable
		// on_key_down: fn(e ui.KeyEvent, wnd &ui.Window) {
		// println('key down')
		//}
		children: [
			ui.row(
				margin: ui.Margin{5, 5, 5, 5}
				widths: ui.stretch
				heights: ui.stretch
				children: [
					ui.grid_layout(
						children: {
							'id1@0x0x30x30':   ui.Widget(rect)
							'id2@30x30x40x40': ui.Widget(ui.rectangle(
								height: 64
								width: 64
								color: gx.rgb(100, 255, 100)
							))
							'id3@70x70x30x30': ui.Widget(ui.rectangle(
								height: 64
								width: 64
								color: gx.rgb(100, 100, 255)
							))
						}
					),
				]
			),
		]
	)
	ui.run(window)
}
