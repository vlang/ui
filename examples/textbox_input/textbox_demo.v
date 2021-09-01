import ui

struct App {
mut:
	tb                     string
	soft_input_visible     bool
	soft_input_buffer      string
	soft_input_parsed_char string
}

fn main() {
	mut app := &App{
		tb: 'Textbox example'
	}

	c := ui.column(
		widths: ui.stretch
		heights: [ui.compact, ui.stretch]
		margin_: 5
		spacing: 10
		children: [
			ui.row(
				spacing: 5
				children: [
					ui.label(
						text: 'Text input' //&app.tb
					),
				]
			),
			ui.textbox(
				id: 'tb1'
				mode: .multiline | .word_wrap
				text: &app.tb
				// fitted_height: true
			),
		]
	)
	w := ui.window(
		state: app
		width: 500
		height: 300
		mode: .resizable
		on_init: init
		children: [c]
	)
	ui.run(w)
}
