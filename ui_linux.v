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
	text_lines := word_wrap_to_lines(s, 70)
	mut height := 40
	mut widgets := [
		// TODO: add hspace and vspace separators
		ui.IWidgeter( ui.label({
			text: ''
		}))
	]
	for tline in text_lines {
		widgets << 	ui.IWidgeter( ui.label({
			text: tline
		}))
		height += 14
	}
	widgets << ui.IWidgeter( ui.label({
		text: ' '
	}))
	widgets << ui.button({
		text: 'OK'
		onclick: msgbox_btn_ok_click
	})
	message_app.window = window({
		width: 400
		height: height
		title: 'Message box'
		bg_color: default_window_color
		user_ptr: message_app
		}, [
			IWidgeter(column({
				stretch: true
				alignment: .center
				margin: ui.MarginConfig{5,5,5,5}
				}, widgets)
			)
		])

	mut subscriber := message_app.window.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, msgbox_on_key_down, message_app)

	ui.run(message_app.window)
	message_app.waitgroup.done()
}

fn msgbox_on_key_down(app mut MessageApp, e &KeyEvent, window &ui.Window ) {
	match e.key {
		.enter, .escape, .space {
			app.window.glfw_obj.set_should_close(true)
		}
		else {}
	}
}

fn msgbox_btn_ok_click(app mut MessageApp) {
	app.window.glfw_obj.set_should_close(true)
}

fn word_wrap_to_lines(s string, max_line_length int) []string {
	words := s.split(' ')
	mut line := []string
	mut line_len := 0
	mut text_lines := []string
	for word in words {
		if line_len + word.len < max_line_length {
			line << word
			line_len += word.len + 1
			continue
		} else {
			text_lines << line.join(' ')
			line = []
			line_len = 0
		}
	}
	if line_len>0{
		text_lines << line.join(' ')
	}
	return text_lines
}
