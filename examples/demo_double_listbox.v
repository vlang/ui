import ui

const (
	win_width  = 600
	win_height = 400
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'V UI: Composable Widget'
		state: app
		mode: .resizable
	}, [
		ui.row({
			alignment: .center
			spacing: 5
			margin: ui.Margin{5, 5, 5, 5}
			widths: ui.stretch
		}, [
			ui.doublelistbox(id: 'dbllb', items: ['otto', 'titi']),
			ui.doublelistbox(id: 'dbllb2', items: ['ottoooo', 'titi', 'tototta']),
		]),
	])
	app.window = window
	ui.run(window)
}
