// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import sync

pub fn message_box(s string) {
	eprintln('message_box start')
	mut message_app := &MessageApp{
		window: 0
		waitgroup: sync.new_waitgroup()
	}
	message_app.waitgroup.add(1)
	go run_message_dialog( message_app, s)
	eprintln('message_box waiting for thread end')
	message_app.waitgroup.wait()
	eprintln('message_box finish')
}

/////////////////////////////////////////////////////////////

struct MessageApp{
mut:
	window  &ui.Window
	waitgroup &sync.WaitGroup
}

fn run_message_dialog(message_app mut MessageApp, s string){
	// run_message_dialog is run in a separate thread
	// and will block until the dialog window is closed
	message_app.window = window({
		width: 340
		height: 65
		title: 'Message box'
		bg_color: default_window_color
		user_ptr: message_app
		}, [
			IWidgeter(column({
				stretch: true
				alignment: .center
				margin: ui.MarginConfig{10,10,10,10}
				},[
					ui.IWidgeter( ui.label({
						text: s
					})),
					ui.IWidgeter( ui.label({
						text: ' '
					})),
					ui.button({
						text: 'OK'
						onclick: btn_message_ok_click
					}),
					])
			)
		])
	ui.run(message_app.window)
	message_app.waitgroup.done()
}

fn btn_message_ok_click(app mut MessageApp) {
	app.window.glfw_obj.set_should_close(true)
}
