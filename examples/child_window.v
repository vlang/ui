import ui

const win_width = 450
const win_height = 120

@[heap]
struct App {
mut:
	window         &ui.Window = unsafe { nil }
	title_box_text string
	name           string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Child window'
		children: [
			ui.column(
				margin_:  10
				children: [
					ui.button(text: 'Create a window', on_click: app.btn_click, width: 150),
					ui.textbox(placeholder: 'Test textbox'),
				]
			),
		]
	)
	ui.run(app.window)
}

fn (mut app App) btn_click(btn &ui.Button) {
	app.window.child_window(
		children: [
			ui.column(
				margin_:  10
				spacing:  5
				children: [
					ui.textbox(placeholder: 'Name', text: &app.name),
					ui.checkbox(id: 'cb_genre', text: 'Check me if woman'),
					ui.button(text: 'Greet me', on_click: app.btn_greet_click, width: 150),
				]
			),
		]
	)
}

fn (mut app App) btn_greet_click(btn &ui.Button) {
	genre := if btn.ui.window.get_or_panic[ui.CheckBox]('cb_genre').checked {
		'miss'
	} else {
		'mister'
	}
	ui.message_box('Hello, ${genre} ${app.name}!')
}
