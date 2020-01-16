module main

import ui

const (
	win_width = 208
	win_height = 46
)

struct App {
mut:
	counter &ui.TextBox
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'Counter'
		user_ptr: app
	})
	app.counter = ui.new_textbox({
		max_len: 20
		width: 100
		x: 12
		y: 14
		read_only: true
		is_numeric: true
		text: '0'
		parent: window
	})

	ui.new_button({
		x: 121
		y: 14
		parent: window
		text: 'Count'
		onclick: btn_count_click
	})
	app.window = window
	ui.run(window)
}

fn btn_count_click(app mut App) {
	mut old_count := app.counter.text.int()
	old_count++
	app.counter.set_text(old_count.str())
}