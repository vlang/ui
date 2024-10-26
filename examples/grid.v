import ui

const win_width = 500
const win_height = 500

struct App {
mut:
	grid   &ui.Grid
	window &ui.Window
}

fn main() {
	h := ['One', 'Two', 'Three']
	b := [['body one', 'body two', 'body three'], ['V', 'UI is', 'Beautiful']]
	mut app := &App{
		window: unsafe { nil }
		grid:   ui.grid(header: h, body: b, width: win_width - 10, height: win_height)
	}
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Grid'
		mode:     .resizable
		children: [
			ui.row(
				margin:   ui.Margin{5, 5, 5, 5}
				children: [
					app.grid,
				]
			),
		]
	)
	ui.run(app.window)
}
