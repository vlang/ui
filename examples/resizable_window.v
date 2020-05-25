import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	window     &ui.Window = 0
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Resizable Window'
		resizable: true
		state: app
	}, [
		ui.row({
			stretch: true,
			margin: ui.MarginConfig{10,10,10,10}
		}, [
			ui.button({
				text: 'Add user'
			})
		])]
	)

	app.window = window
	ui.run(window)
}
