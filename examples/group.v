import ui

const (
	win_width = 300
	win_height = 300
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
			title: 'Group Demo'
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
				}),
				ui.checkbox({
					checked: true
					text: 'Online registration1'
				}),
				ui.checkbox({
					checked: true
					text: 'Online registration2'
				}),
				ui.checkbox({
					checked: true
					text: 'Online registration3'
				}),
				ui.button({
					text: 'Add user'
				}) as ui.IWidgeter,
			]
		}) as ui.IWidgeter
	])
	app.window = window
	ui.run(window)
}