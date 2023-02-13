import ui
import gx

const (
	win_width  = 400
	win_height = 300
)

[heap]
struct App {
mut:
	text   string
	window &ui.Window = unsafe { nil }
}

fn make_tb(mut app App, has_row bool) ui.Widget {
	tb := ui.textbox(
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
	mut app := App{
		text: 'blah blah blah\n'.repeat(10)
	}
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Rectangles inside BoxLayout'
		mode: .resizable
		children: [
			ui.row(
				margin_: 20
				widths: ui.stretch
				heights: ui.stretch
				children: [
					ui.box_layout(
						id: 'bl'
						children: {
							'id1: (0,0) ++ (0.3,0.3)':     ui.rectangle(
								color: gx.rgb(255, 100, 100)
							)
							'id2: (0.3,0.3) ++ (0.4,0.4)': ui.rectangle(
								color: gx.rgb(100, 255, 100)
							)
							'id3: (0.7,0.7) ++ (0.3,0.3)': make_tb(mut app, false)
							'btn: (0.7,0.1) ++ (50,20)':   ui.button(
								text: 'switch'
								on_click: app.btn_click
							)
						}
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn (mut app App) btn_click(_ &ui.Button) {
	mut bl := app.window.get_or_panic[ui.BoxLayout]('bl')
	bl.update_child_bounding('id3', '(0.8,0.8) ++ (0.2,0.2)')
	app.window.update_layout()
}
