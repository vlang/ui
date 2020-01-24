import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Switch'
		user_ptr: app
	}, [
		ui.switcher({
			open: true
		}) as ui.IWidgeter
	])
	app.window = window
	ui.run(window)
}