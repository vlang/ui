// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import sync

pub fn message_box(s string) {
	// Running the message box dialog window
	// in a new thread ensures that glfw's context 
	// of the main window will not be messed up.
	//
	// We use a waitgroup to wait for the end of the thread,
	// to ensure that message_box shows a modal dialog, i.e. that
	// its behaviour is as close to the behaviour of the native 
	// message box dialogs on other platforms.
	//
	mut message_app := &MessageApp{
		window: 0
		waitgroup: sync.new_waitgroup()
	}
	message_app.waitgroup.add(1)
	go run_message_dialog( message_app, s)
	message_app.waitgroup.wait()
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
					// TODO: add hspace and vspace separators
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
