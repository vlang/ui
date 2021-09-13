import ui
import gx

struct App {
mut:
	window &ui.Window = 0
	text   string
	info   string
}

fn main() {
	mut app := &App{}
	mut s := ''
	for i in 0 .. 100 {
		s += 'line ($i)'.repeat(40)
		s += '\n'
	}
	app.text = s
	app.window = ui.window(
		state: app
		width: 800
		height: 600
		title: 'V UI: Scrollview'
		mode: .resizable
		children: [
			ui.row(
				widths: ui.stretch
				heights: ui.stretch
				children: [
					ui.textbox(
						id: 'text'
						mode: .multiline | .read_only
						bg_color: gx.hex(0xfcf4e4ff)
						text: &app.text
						text_size: 24
						on_scroll_change: on_scroll_change
					),
					ui.textbox(
						id: 'info'
						mode: .multiline | .read_only
						text: &app.info
						text_size: 24
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn on_scroll_change(sw ui.ScrollableWidget) {
	mut tb := sw.ui.window.textbox('info')
	mut s := ''
	sv := sw.scrollview
	s += 'textbox $sw.id has scrollview? $sw.has_scrollview'
	s += '\nat ($sw.x, $sw.y)'
	s += '\nwith scrollview offset: ($sv.offset_x, $sv.offset_y)'
	s += '\nwith btn: ($sv.btn_x, $sv.btn_y)'
	tb.set_text(s)
}
