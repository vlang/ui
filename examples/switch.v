module main

import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	switcher &ui.Switch
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'Switch'
		user_ptr: app
	})
	app.switcher = ui.new_switch({
		parent: window
		x: 12
		y: 12
		open: true
	})
	app.window = window
	ui.run(window)
}