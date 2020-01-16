module main

import ui

const (
	win_width = 380
	win_height = 41
)

struct App {
mut:
	txt_box_celsius &ui.TextBox
	txt_box_fahrenheit &ui.TextBox
	lbl_fahrenheit &ui.Label
	lbl_celsius &ui.Label
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'Temperature Conv.'
		user_ptr: app
	})
	app.txt_box_celsius = ui.new_textbox({
		x: 12
		y: 12
		width: 70
		on_key_up: on_cel_key_up
		is_numeric: true
		parent: window
	})
	app.txt_box_fahrenheit = ui.new_textbox({
		x: 150
		y: 12
		width: 70
		on_key_up: on_fah_key_up
		is_numeric: true
		parent: window
	})
	app.lbl_celsius = ui.new_label({
		x: 86
		y: 15
		text: 'Celsius = '
		parent: window
	})
	app.lbl_fahrenheit = ui.new_label({
		x: 240
		y: 15
		text: 'Fahrenheit'
		parent: window
	})
	app.window = window
	ui.run(window)
}

fn on_cel_key_up(app mut App){
	celsius := app.txt_box_celsius.text.f64()
	fah := celsius * (9.0/5.0) + 32.0
	app.txt_box_fahrenheit.set_text(int(fah).str())
}

fn on_fah_key_up(app mut App){
	fah := app.txt_box_fahrenheit.text.f64()
	cel := (fah - 32.0)*(5.0/9.0)
	app.txt_box_celsius.set_text(int(cel).str())
}