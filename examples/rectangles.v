import ui
import gx

const win_width = 64 * 4 + 25
const win_height = 74

fn main() {
	rect := ui.rectangle(
		height: 64
		width:  64
		color:  gx.rgb(255, 100, 100)
	)
	window := ui.window(
		width:  win_width
		height: win_height
		title:  'V UI: Rectangles'
		// on_key_down: fn(e ui.KeyEvent, wnd &ui.Window) {
		// println('key down')
		//}
		children: [
			ui.row(
				alignment: .center
				spacing:   5
				margin:    ui.Margin{5, 5, 5, 5}
				children:  [
					rect,
					/*
					{ rect | color: gx.rgb(100, 255, 100), border: true, border_color: gx.black }
					{ rect | color: gx.rgb(100, 100, 255), radius: 24 }
					{ rect | color: gx.rgb(255, 100, 255), radius: 24, border: true, border_color: gx.black }
					*/
					ui.rectangle(
						height: 64
						width:  64
						color:  gx.rgb(100, 255, 100)
					),
					ui.rectangle(
						height: 64
						width:  64
						color:  gx.rgb(100, 100, 255)
					),
					ui.rectangle(
						height: 64
						width:  64
						color:  gx.rgb(255, 100, 255)
					),
				]
			),
		]
	)
	ui.run(window)
}
