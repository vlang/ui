module main

import ui
import time

struct App {
mut:
	window &ui.Window = 0
	task   int
	log    string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		state: app
		mode: .resizable
		height: 220
		children: [
			ui.column(
				widths: ui.stretch
				children: [
					ui.textbox(
						id: 'tb'
						is_multiline: true
						text: &app.log
						height: 200
						is_sync: true
						// is_wordwrap: true
						// scrollview: true
						read_only: true
						// text_size: 20
					),
					ui.button(text: 'start scan', onclick: btn_connect),
				]
			),
		]
	)
	ui.run(app.window)
}

fn wait_complete(mut app App, mut tb ui.TextBox) {
	for task in 0 .. 10000 {
		app.log += 'processing ... task $task complete\n'
		time.sleep(500 * time.millisecond)
		tb.tv.do_logview()
	}
}

fn btn_connect(mut app App, btn &ui.Button) {
	mut tb := app.window.textbox('tb')
	go wait_complete(mut app, mut tb)
}
