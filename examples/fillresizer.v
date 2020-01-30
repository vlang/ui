import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'FillResizer'
		user_ptr: app
		resizer: ui.resizer({
			layout: .fill
			align: .horizontal //vertical
		})
	}, [
		ui.button({
			text: 'Add user1'
		}) as ui.IWidgeter,
		ui.button({
			text: 'Add user2'
		}) as ui.IWidgeter,
		ui.button({
			text: 'Add user3'
		}) as ui.IWidgeter
	])
	app.window = window
	ui.run(window)
}