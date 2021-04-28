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
			spacing: .1
			margin_: 5
			widths: ui.stretch
		}, [
			ui.doublelistbox(id: 'dlb1', title: 'dlb1', items: ['totto', 'titi']),
			ui.doublelistbox(id: 'dlb2', title: 'dlb2', items: ['tottoooo', 'titi', 'tototta']),
		]),
	])
	app.window = window
	ui.run(window)
}

fn test_click(a voidptr, b &ui.Button) {
	s := b.ui.window.stack('dlb')
	println('$s.component_type()')
}
