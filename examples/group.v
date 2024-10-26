import ui

const win_width = 300
const win_height = 300

struct App {
mut:
	window     &ui.Window = unsafe { nil }
	first_name string
	last_name  string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Group Demo'
		children: [
			ui.group(
				x:        20
				y:        20
				title:    'Group Demo'
				children: [
					ui.textbox(
						max_len:     20
						width:       200
						placeholder: 'First name'
						text:        &app.first_name
					),
					ui.textbox(
						max_len:     50
						width:       200
						placeholder: 'Last name'
						text:        &app.last_name
					),
					ui.checkbox(checked: true, text: 'Online registration1'),
					ui.checkbox(checked: true, text: 'Online registration2'),
					ui.checkbox(checked: true, text: 'Online registration3'),
					ui.button(text: 'Add user'),
				]
			),
		]
	)
	ui.run(app.window)
}
