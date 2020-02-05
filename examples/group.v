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
		title: 'Group Demo'
		user_ptr: app
	}, [
		ui.group({
		    x:20
		    y:20
			title: 'Demo'
			width: 100
			height: 100
			children: [
				ui.textbox({
					max_len: 20
					width: 200
					placeholder: 'First name'
				}) as ui.IWidgeter,
				ui.textbox({
					max_len: 50
					width: 200
					placeholder: 'Last name'
				})
			]
		}) as ui.IWidgeter
	])
	app.window = window
	ui.run(window)
}