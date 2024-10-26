module main

import ui
import time

@[heap]
struct App {
mut:
	window &ui.Window = unsafe { nil }
	task   int
	log    string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		mode:   .resizable
		height: 220
		layout: ui.column(
			widths:   ui.stretch
			children: [
				ui.textbox(
					id:           'tb'
					is_multiline: true
					text:         &app.log
					height:       200
					is_sync:      true
					// is_wordwrap: true
					// scrollview: true
					read_only: true
					// text_size: 20
				),
				ui.button(text: 'start scan', on_click: app.btn_connect),
			]
		)
	)
	ui.run(app.window)
}

fn (mut app App) wait_complete(mut tb ui.TextBox) {
	for task in 0 .. 1001 {
		app.log += 'processing ... task ${task} complete\n'
		time.sleep(500 * time.millisecond)
		tb.tv.do_logview()
	}
}

fn (mut app App) btn_connect(btn &ui.Button) {
	mut tb := app.window.get_or_panic[ui.TextBox]('tb')
	spawn app.wait_complete(mut tb)
}
