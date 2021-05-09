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
		title: 'V UI: Toolbar'
		state: app
		mode: .resizable
		native_message: false
	}, [
		ui.column({
			margin_: .05
			spacing: .05
			heights: [8 * ui.stretch, ui.stretch, ui.stretch]
		}, [
			ui.toolbar(
			widths: [100., 100., ui.stretch, 100.]
			heights: 20.
			spacing: 10.
			items: [ui.button(id: 'left1', text: 'toto'), ui.button(id: 'left2', text: 'toto2'),
				ui.spacing({}), ui.button(id: 'btn2', text: 'tata')]
		),
		]),
	])
	app.window = window
	ui.run(window)
}
