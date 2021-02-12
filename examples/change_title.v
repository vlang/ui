import ui

const (
	win_width  = 450
	win_height = 120
)

struct App {
mut:
	window         &ui.Window = 0
	title_box_text string
}

fn main() {
	mut app := &App{}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Name'
		state: app
	}, [
		ui.column({
			stretch: true
			spacing: 20
			margin: 30
		}, [
			ui.row({
				spacing: 10
				alignment: .center
			}, [
				ui.label(text: 'Title name: '),
				ui.textbox(
					max_len: 20
					width: 300
					placeholder: 'Please enter new title name'
					text: &app.title_box_text
					is_focused: true
				),
			]),
			ui.button(text: 'Change title', onclick: btn_change_title),
		]),
	])
	ui.run(app.window)
}

fn btn_change_title(mut app App, btn &ui.Button) {
	app.window.set_title(app.title_box_text)
}
