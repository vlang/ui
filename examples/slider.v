module main

import ui

const (
	win_width = 260
	win_height = 230
)

struct App {
mut:
	hor_slider  &ui.Slider
	vert_slider &ui.Slider
	window      &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'Slider Example'
		user_ptr: app
	})
	app.vert_slider = ui.new_slider({
		parent: window
		x: 12
		y: 12
		width: 20
		height: 200
		orientation: .vertical
		max: 100
		val: 0
		on_value_changed: on_vert_value_changed
	})
	app.hor_slider = ui.new_slider({
		parent: window
		x: 50
		y: 12
		width: 200
		height: 20
		orientation: .horizontal
		max: 100
		val: 0
		on_value_changed: on_hor_value_changed
	})
	app.window = window
	ui.run(window)
}

fn on_hor_value_changed(app mut App) {
	app.vert_slider.val = app.hor_slider.val
}

fn on_vert_value_changed(app mut App) {
	app.hor_slider.val = app.vert_slider.val
}
