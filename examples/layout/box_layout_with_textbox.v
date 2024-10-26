import ui
import gx

const win_width = 400
const win_height = 300

struct App {
mut:
	text   string
	btn_cb map[string]fn (&ui.Button)
}

fn make_tb(mut app App, has_row bool) ui.Widget {
	tb := ui.textbox(
		mode:     .multiline
		bg_color: gx.yellow
		text:     &app.text
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

fn (mut app App) make_btn() ui.Widget {
	app.btn_cb['btn_click'] = fn (_ &ui.Button) {
		ui.message_box('coucou toto!')
	}
	return ui.button(
		text:     'toto'
		on_click: app.btn_cb['btn_click']
	)
}

fn main() {
	mut with_row := false
	$if with_row ? {
		with_row = true
	}
	mut app := App{
		text: 'blah blah blah\n'.repeat(10)
	}
	ui.run(ui.window(
		width:  win_width
		height: win_height
		title:  'V UI: Rectangles inside BoxLayout'
		mode:   .resizable
		layout: ui.box_layout(
			id:       'bl'
			children: {
				'id1: (0,0) ++ (30,30)':          ui.rectangle(
					color: gx.rgb(255, 100, 100)
				)
				'id2: (30,30) -> (-30.5,-30.5)':  ui.rectangle(
					color: gx.rgb(100, 255, 100)
				)
				'id3: (50%,50%) ->  (100%,100%)': make_tb(mut app, with_row)
				'id4: (-30.5, -30.5) ++ (30,30)': ui.rectangle(
					color: gx.white
				)
				'id5: (70%,20%) ++ (50,20)':      app.make_btn()
			}
		)
	))
}
