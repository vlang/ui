import ui

const (
	win_width  = 500
	win_height = 500
)

struct App {
mut:
	grid   &ui.Grid   = unsafe { nil }
	window &ui.Window = unsafe { nil }
}

fn main() {
	h := ['One', 'Two', 'Three']
	b := [['body one', 'body two', 'body three'], ['V', 'UI is', 'Beautiful']]
	mut app := &App{
		window: 0
		grid: ui.grid(header: h, body: b, width: win_width - 10, height: win_height)
	}
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Grid'
		mode: .resizable
		children: [
			ui.row(
				margin: ui.Margin{5, 5, 5, 5}
				children: [
					app.grid,
				]
			),
		]
	)
	ui.run(app.window)
}
