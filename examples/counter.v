import ui
import os

const (
	win_width  = 208
	win_height = 46
)

struct App {
mut:
	counter string     = '0'
	window  &ui.Window = 0
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Counter'
		state: app
		children: [
			ui.row(
				spacing: 5
				margin: ui.Margin{5, 5, 5, 5}
				children: [
					ui.textbox(
						max_len: 20
						read_only: true
						is_numeric: true
						text: &app.counter
					),
					ui.button(
						width: 24
						height: 24
						icon_path: os.resource_abs_path('plus.png')
						text: 'Alt'
						onclick: btn_count_click
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn btn_count_click(mut app App, btn &ui.Button) {
	app.counter = (app.counter.int() + 1).str()
}
