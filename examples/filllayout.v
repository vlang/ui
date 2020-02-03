import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	window  &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'FillLayout'
		user_ptr: app
	}, [
		ui.fill_layout({
			width: win_width
			height: win_height
			align: .vertical //vertical //horizontal
		}, [
			ui.button({
				text: 'Button1'
			}) as ui.IWidgeter,
			ui.button({
				text: 'Button2'
			}),
			ui.button({
				text: 'Button3'
			}),
			ui.button({
				text: 'Button4'
			}),
		]) as ui.IWidgeter
	])

	app.window = window
	ui.run(window)
}
