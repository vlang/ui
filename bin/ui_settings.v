import ui
import gx
import gg
import ui.component as uic
import os.font

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window(
		width: 800
		height: 600
		title: 'V UI Settings'
		state: app
		mode: .resizable
		// on_key_down: fn(e ui.KeyEvent, wnd &ui.Window) {
		// println('key down')
		//}
		children: [
			ui.row(
				alignment: .center
				spacing: 5
				margin_: 5
				widths: ui.stretch
				children: [
					uic.rectangle(color: gx.rgb(100, 255, 100), radius: 10, text: 'Green'),
					ui.rectangle(color: gx.rgb(100, 100, 255), radius: 10, text: 'Blue'),
					ui.rectangle(color: gx.rgb(255, 100, 255), radius: 10, text: 'Pink'),
				]
			),
		]
	)
	app.window = window
	println(font.system_path())
	ui.run(window)
}
