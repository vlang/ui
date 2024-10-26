import ui
import gx

const win_width = 200
const win_height = 40

@[heap]
struct App {
mut:
	counter string = '0'
}

fn main() {
	mut app := &App{}
	window := ui.window(
		width:  win_width
		height: win_height
		title:  'Counter'
		mode:   .resizable
		layout: ui.row(
			spacing:  5
			margin_:  10
			widths:   ui.stretch
			heights:  ui.stretch
			children: [
				ui.textbox(
					max_len: 20
					// height: 30
					read_only:  true
					is_numeric: true
					text:       &app.counter
				),
				ui.button(
					text:         'Count'
					bg_color:     gx.light_gray
					radius:       5
					border_color: gx.gray
					on_click:     fn [mut app] (btn &ui.Button) {
						cpt := app.counter.int() + 1
						app.counter = cpt.str()
					}
				),
			]
		)
	)
	ui.run(window)
}
