import ui

const (
	win_width  = 400
	win_height = 40
)

struct App {
mut:
	txt_box_celsius         &ui.TextBox
	txt_box_fahrenheit      &ui.TextBox
	txt_box_celsius_text    string
	txt_box_fahrenheit_text string
	window                  &ui.Window
}

fn main() {
	mut app := &App{
		txt_box_celsius: ui.textbox(
			width: 70
			on_char: on_char_celsius
			is_numeric: true
		)
		txt_box_fahrenheit: ui.textbox(
			width: 70
			on_char: on_char_fahrenheit
			is_numeric: true
		)
		window: 0
	}
	app.txt_box_celsius.text = &app.txt_box_celsius_text
	app.txt_box_fahrenheit.text = &app.txt_box_fahrenheit_text
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Temperature Converter'
		state: app
		children: [
			ui.row(
				margin: ui.Margin{10, 10, 10, 10}
				spacing: 10
				widths: [.2, .3, .2, .3]
				heights: 20.0
				children: [ui.label(text: 'Celsius'), app.txt_box_celsius,
					ui.label(
						text: 'Fahrenheit'
					), app.txt_box_fahrenheit]
			),
		]
	)
	ui.run(app.window)
}

fn on_char_celsius(mut app App, textbox &ui.TextBox, keycode u32) {
	if app.txt_box_celsius.text.len <= 0 {
		app.txt_box_fahrenheit_text = '0'
		return
	}
	celsius := app.txt_box_celsius.text.f64()
	fah := celsius * (9.0 / 5.0) + 32.0
	app.txt_box_fahrenheit_text = int(fah).str()
}

fn on_char_fahrenheit(mut app App, textbox &ui.TextBox, keycode u32) {
	if app.txt_box_fahrenheit.text.len <= 0 {
		app.txt_box_celsius_text = '0'
		return
	}
	fah := app.txt_box_fahrenheit.text.f64()
	cel := (fah - 32.0) * (5.0 / 9.0)
	app.txt_box_celsius_text = int(cel).str()
}
