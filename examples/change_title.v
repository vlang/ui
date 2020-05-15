import ui

const (
	win_width = 450
	win_height = 120
)

struct App {
mut:
	window    &ui.Window
	title_box &ui.TextBox
}

fn main() {
	mut app := &App{
		window: 0
		title_box: ui.textbox(
			max_len: 20
			width: 300
			placeholder: 'Please enter new title name'
		)
	}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Name'
		user_ptr: app
	}, [
		ui.column({
			stretch: true
			spacing: 20
			margin: ui.MarginConfig{30,30,30,30}
		}, [
			ui.row({
				spacing: 10
				alignment: .center
			}, [
				ui.label(
					text: 'Title name: '
				)
				app.title_box
			]),
			ui.button(
				text: 'Change title'
				onclick: btn_change_title
			)
		])]
	)

	app.window = window
	ui.run(window)
}

fn btn_change_title(app mut App, btn &ui.Button) {
	app.window.set_title(app.title_box.text)
}
