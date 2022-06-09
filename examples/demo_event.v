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
		width: 600
		height: 600
		title: 'V UI: Event'
		mode: .resizable
		on_key_down: fn (w &ui.Window, e ui.KeyEvent) {
			mut tb := w.textbox('info')
			tb.set_text('key_down:\n$e')
		}
		on_char: fn (w &ui.Window, e ui.KeyEvent) {
			mut tb := w.textbox('info')
			s := utf32_to_str(e.codepoint)
			tb.set_text('${*tb.text} \nchar: <$s>\n$e')
		}
		on_mouse_down: fn (w &ui.Window, e ui.MouseEvent) {
			mut tb := w.textbox('info')
			tb.set_text('mouse_down:\n$e')
		}
		on_click: fn (w &ui.Window, e ui.MouseEvent) {
			mut tb := w.textbox('info')
			tb.set_text('${*tb.text} \nmouse_click:\n$e \nnb_click: $tb.ui.nb_click')
		}
		on_mouse_up: fn (w &ui.Window, e ui.MouseEvent) {
			mut tb := w.textbox('info')
			tb.set_text('mouse_up:\n$e')
		}
		on_mouse_move: fn (w &ui.Window, e ui.MouseMoveEvent) {
			mut tb := w.textbox('info')
			tb.set_text('mouse_move:\n$e')
		}
		on_swipe: fn (w &ui.Window, e ui.MouseEvent) {
			mut tb := w.textbox('info')
			tb.set_text('swipe:\n$e')
		}
		on_scroll: fn (w &ui.Window, e ui.ScrollEvent) {
			mut tb := w.textbox('info')
			tb.set_text('mouse_scroll\n$e')
		}
		on_resize: fn (win &ui.Window, w int, h int) {
			mut tb := win.textbox('info')
			tb.set_text('resize:\n ($w, $h)')
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
