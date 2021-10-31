import ui

const (
	win_width  = 450
	win_height = 120
)

struct App {
mut:
	window         &ui.Window = 0
	title_box_text string
	name           string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Child window'
		state: app
		children: [
			ui.column(
				children: [
					ui.button(text: 'Create a window', onclick: btn_click, width: 150),
					ui.textbox(placeholder: 'Test textbox'),
				]
			),
		]
	)
	ui.run(app.window)
}

fn btn_click(mut app App, btn &ui.Button) {
	app.window.child_window(
		state: app
		children: [
			ui.column(
				children: [
					ui.textbox(placeholder: 'Name', text:&app.name),
					ui.checkbox(text: 'Check me'),
					ui.button(text: 'Greet me', onclick: btn_greet_click, width: 150),
				]
			),
		]
	)
}

fn btn_greet_click(mut app App, btn &ui.Button) {
	ui.message_box('Hello, $app.name!')
}
