import ui

const (
	win_width  = 380
	win_height = 41
)

struct App {
mut:
	txt_box_celsius    &ui.TextBox
	txt_box_fahrenheit &ui.TextBox
	window             &ui.Window
}

fn main() {
	mut app := &App{
		txt_box_celsius: ui.textbox({
			width: 70
			on_key_up: on_cel_key_up
			is_numeric: true
		})
		txt_box_fahrenheit: ui.textbox({
			width: 70
			on_key_up: on_fah_key_up
			is_numeric: true
		})
		window: 0
	}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Temperature Converter'
		state: app
	}, [
		ui.row({
			stretch: true
			alignment: .center
			margin: ui.MarginConfig{5,5,5,5}
			spacing: 10
		}, [
			ui.label({
				text: 'Celsius'
			}),
			app.txt_box_celsius,
			ui.label({
				text: 'Fahrenheit'
			}),
			app.txt_box_fahrenheit
		])
	])
	app.window = window
	ui.run(window)
}

fn on_cel_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	if app.txt_box_celsius.text.len <= 0 {
		app.txt_box_fahrenheit.set_text('0')
		return
	}
	celsius := app.txt_box_celsius.text.f64()
	fah := celsius * (9.0 / 5.0) + 32.0
	app.txt_box_fahrenheit.set_text(int(fah).str())
}

fn on_fah_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	if app.txt_box_fahrenheit.text.len <= 0 {
		app.txt_box_celsius.set_text('0')
		return
	}
	fah := app.txt_box_fahrenheit.text.f64()
	cel := (fah - 32.0) * (5.0 / 9.0)
	app.txt_box_celsius.set_text(int(cel).str())
}
