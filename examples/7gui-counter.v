import ui
import gx

const (
	win_width  = 200
	win_height = 40
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
		mode: .resizable
		state: app
		children: [
			ui.row(
				spacing: 5
				margin_: 10
				widths: ui.stretch
				heights: ui.stretch
				children: [
					ui.textbox(
						max_len: 20
						// height: 30
						read_only: true
						is_numeric: true
						text: &app.counter
					),
					ui.button(
						text: 'Count'
						bg_color: gx.light_gray
						radius: 5
						border_color: gx.gray
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
