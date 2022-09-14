// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
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
	go run_message_dialog(mut message_app, s)
	message_app.waitgroup.wait()
}

// ///////////////////////////////////////////////////////////
struct MessageApp {
mut:
	window    &Window = unsafe { nil }
	waitgroup &sync.WaitGroup
}

fn run_message_dialog(mut message_app MessageApp, s string) {
	// run_message_dialog is run in a separate thread
	// and will block until the dialog window is closed
	text_lines := word_wrap_to_lines(s, 70)
	mut height := 40
	mut widgets := []Widget{}
	widgets = [
		// TODO: add hspace and vspace separators
		label(text: ''),
	]
	for tline in text_lines {
		widgets << label(text: tline)
		height += 14
	}
	widgets << label(text: ' ')
	widgets << button(text: 'OK')
	message_app.window = window(
		width: 400
		height: height
		title: 'Message box'
		bg_color: default_window_color
		children: [
			column(
				stretch: true
				alignment: .center
				margin: Margin{5, 5, 5, 5}
				children: widgets
			),
		]
	)
	mut subscriber := message_app.window.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, msgbox_on_key_down, message_app)
	run(message_app.window)
	message_app.waitgroup.done()
}

fn msgbox_on_key_down(mut app MessageApp, e &KeyEvent, window &Window) {
	match e.key {
		.enter, .escape, .space {
			// app.window.glfw_obj.set_should_close(true)
		}
		else {}
	}
}

fn msgbox_btn_ok_click(mut app MessageApp) {
	// app.window.glfw_obj.set_should_close(true)
}
