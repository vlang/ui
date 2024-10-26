import ui
import gx

const win_width = 400
const win_height = 300

@[heap]
struct App {
mut:
	text   string
	texts  map[string]string
	window &ui.Window = unsafe { nil }
}

fn make_tb(mut app App, mut text []string, has_row bool) ui.Widget {
	app.texts['toto'] = 'blah3 blah blah\n'.repeat(10)
	tb := ui.textbox(
		mode:     .multiline
		bg_color: gx.yellow
		text:     &(app.texts['toto'])
	)
	return if has_row {
		ui.Widget(ui.row(
			widths:   ui.stretch
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

	mut text := ['blah2 blah blah\n'.repeat(10)]
	app.window = ui.window(
		width:  win_width
		height: win_height
		title:  'V UI: Rectangles inside BoxLayout'
		mode:   .resizable
		layout: ui.row(
			margin_:  20
			widths:   ui.stretch
			heights:  ui.stretch
			children: [
				ui.box_layout(
					id:       'bl'
					children: {
						'id1: (0,0) ++ (30%,30%)':     ui.rectangle(
							color: gx.rgb(255, 100, 100)
						)
						'id2: (0.3,0.3) ++ (40%,40%)': ui.rectangle(
							color: gx.rgb(100, 255, 100)
						)
						'id3: (70%,70%) ++ (30%,30%)': make_tb(mut app, mut text, false)
						'btn: (70%,10%) ++ (50,20)':   ui.button(
							text:     'switch'
							on_click: app.btn_click
						)
					}
				),
			]
		)
	)
	ui.run(app.window)
}

fn (mut app App) btn_click(_ &ui.Button) {
	mut bl := app.window.get_or_panic[ui.BoxLayout]('bl')
	bl.update_boundings('id3: (80%,80%) ++ (20%,20%)')
}
