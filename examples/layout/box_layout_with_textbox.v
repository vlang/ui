import ui
import gx

const (
	win_width  = 400
	win_height = 300
)

struct App {
mut:
	text string
}

fn make_tb(mut app App, has_row bool) ui.Widget {
	tb := ui.textbox(
		width: 200
		mode: .multiline
		bg_color: gx.yellow
		text: &app.text
	)
	return if has_row {
		ui.Widget(ui.row(
			widths: ui.stretch
			children: [
				tb,
			]
		))
	} else {
		ui.Widget(tb)
	}
}

fn main() {
	mut with_row := false
	$if with_row ? {
		with_row = true
	}
	mut app := App{
		text: 'blah blah blah\n'.repeat(100)
	}
	ui.run(ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Rectangles inside BoxLayout'
		mode: .resizable
		children: [
			ui.box_layout(
				id: 'bl'
				children: {
					'id1: (0,0) ++ (30,30)':          ui.rectangle(
						color: gx.rgb(255, 100, 100)
					)
					'id2: (30,30) -> (-30.5,-30.5)':  ui.rectangle(
						color: gx.rgb(100, 255, 100)
					)
					'id3: (0.5,0.5) ->  (1,1)':       make_tb(mut app, with_row)
					'id4: (-30.5, -30.5) ++ (30,30)': ui.rectangle(
						color: gx.white
					)
				}
			),
		]
	))
}
