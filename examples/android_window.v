import ui
import sokol.sapp

struct App {
mut:
	window &ui.Window
	text string
}

fn main() {
	mut app := &App{
		window: 0
		text: "size= ${sapp.dpi_scale()} ${sapp.width()} ${sapp.height()}"
	}
	window := ui.window({
		title: 'V Android Test'
		width: 800
		height: 600
		state: app
		mode: .max_size
	}, [
		ui.column({
			widths: ui.stretch
		}, [
			ui.textbox(
			text: &app.text
			placeholder: '0'
			// width: 135
			read_only: true
		),
		]),
	])
	app.window = window
	app.text = "size= (${window.width},${window.height}) ${sapp.dpi_scale()} ${sapp.width()} ${sapp.height()}"
	ui.run(window)
}