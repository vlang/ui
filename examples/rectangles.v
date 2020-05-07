import ui
import gx

const (
	win_width = 64 * 4 + 25
	win_height = 74
)

struct App {
mut:
	window  &ui.Window
}

fn main() {
	mut app := &App{ window: 0 }
	rect := ui.rectangle(ref: 0, height: 64, width: 64, color: gx.rgb(255, 100, 100))
	window := ui.window({
		width: win_width
		height: win_height
		title: 'V UI: Rectangles'
		user_ptr: app
	}, [
		ui.row({
			alignment: .center
			spacing:   5
			margin:    ui.MarginConfig{5,5,5,5}
		}, [
			rect
			/*
			{ rect | color: gx.rgb(100, 255, 100), border: true, border_color: gx.black }
			{ rect | color: gx.rgb(100, 100, 255), radius: 24 }
			{ rect | color: gx.rgb(255, 100, 255), radius: 24, border: true, border_color: gx.black }
			*/
			ui.rectangle(ref: 0, height: 64, width: 64, color: gx.rgb(100, 255, 100))
			ui.rectangle(ref: 0, height: 64, width: 64, color: gx.rgb(100, 100, 255))
			ui.rectangle(ref: 0, height: 64, width: 64, color: gx.rgb(255, 100, 255))
		])
	])

	app.window = window
	ui.run(window)
}
