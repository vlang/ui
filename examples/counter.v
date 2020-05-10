import ui

const (
	win_width = 208
	win_height = 46
)

struct App {
mut:
	counter &ui.TextBox
	window  &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
		counter: ui.textbox(
			max_len: 20
			read_only: true
			is_numeric: true
			text: '0'
		)
	}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Counter'
		user_ptr: app
	}, [
		ui.row({
			alignment: .top
			spacing: 5
			stretch : true
			margin: ui.MarginConfig{5,5,5,5}
		}, [
			app.counter
			ui.button(
				text: 'Count'
				onclick: btn_count_click
			)
		])
	])
	ui.run(app.window)
}

fn btn_count_click(app mut App, btn &ui.Button) {
	mut old_count := app.counter.text.int()
	old_count++
	app.counter.set_text(old_count.str())
}
