import ui

const win_width = 450
const win_height = 120

@[heap]
struct App {
mut:
	window         &ui.Window = unsafe { nil }
	title_box_text string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Name'
		children: [
			ui.column(
				spacing: 20
				margin:  ui.Margin{30, 30, 30, 30}
				// uncomment if you don't set the width of the button
				// widths: [ui.stretch,150]
				children: [
					ui.row(
						spacing:   10
						alignment: .center
						children:  [
							ui.label(text: 'Title name: '),
							ui.textbox(
								max_len:     20
								width:       300
								placeholder: 'Please enter new title name'
								text:        &app.title_box_text
								is_focused:  true
							),
						]
					),
					ui.button(text: 'Change title', on_click: app.btn_change_title, width: 150),
				]
			),
		]
	)
	ui.run(app.window)
}

fn (mut app App) btn_change_title(btn &ui.Button) {
	app.window.set_title(app.title_box_text)
}
