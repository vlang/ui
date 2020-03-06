import ui

const (
	win_width = 208
	win_height = 46
)

struct App {
mut:
	counter ui.TextBox
	window  &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Counter'
		user_ptr: app
	}, [
		ui.iwidget(ui.row({
			alignment: .top
			spacing: 5
			stretch : true
			margin: ui.MarginConfig{5,5,5,5}
		}, [
			ui.iwidget(ui.textbox({
				max_len: 20
				read_only: true
				is_numeric: true
				text: '0'
				ref: &app.counter
			})),
			ui.iwidget(ui.button({
				text: 'Count'
				onclick: btn_count_click
			}))
		]))
	])

	app.window = window
	ui.run(window)
}

fn btn_count_click(app mut App) {
	mut old_count := app.counter.text.int()
	old_count++
	app.counter.set_text(old_count.str())
}
