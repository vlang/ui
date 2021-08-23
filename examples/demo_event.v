import ui
import gx

struct App {
mut:
	window &ui.Window = 0
	info   string     = '....'
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		state: app
		width: 600
		height: 600
		title: 'V UI: Event'
		mode: .resizable
		on_key_down: fn (e ui.KeyEvent, w &ui.Window) {
			mut tb := w.textbox('info')
			tb.set_text('key_down:\n$e')
		}
		on_char: fn (e ui.KeyEvent, w &ui.Window) {
			mut tb := w.textbox('info')
			s := utf32_to_str(e.codepoint)
			tb.set_text('${*tb.text} \nchar: <$s>\n$e')
		}
		children: [
			ui.row(
				widths: ui.stretch
				heights: ui.stretch
				children: [
					ui.textbox(
						id: 'info'
						mode: .multiline | .read_only
						bg_color: gx.hex(0xfcf4e4ff)
						text: &app.info
						text_size: 24
					),
				]
			),
		]
	)
	ui.run(app.window)
}
