import ui
import gx

const win_width = 600
const win_height = 300

struct App {
mut:
	window       &ui.Window = unsafe { nil }
	first_ipsum  string
	second_ipsum string
	full_name    string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Group 2 Demo'
		mode:     .resizable
		children: [
			ui.column(
				margin_:  10
				bg_color: gx.rgb(100, 100, 100)
				children: [
					ui.row(
						spacing:  20
						children: [
							ui.group(
								title:    'First group'
								clipping: true
								children: [
									ui.textbox(
										max_len:     20
										width:       200
										placeholder: 'Lorem ipsum'
										text:        &app.first_ipsum
									),
									ui.textbox(
										max_len:     20
										width:       200
										placeholder: 'dolor sit amet'
										text:        &app.second_ipsum
									),
									ui.button(
										text:     'More ipsum!'
										on_click: fn (b &ui.Button) {
											ui.open_url('https://lipsum.com/feed/html')
										}
									),
								]
							),
							ui.group(
								title:    'Second group'
								clipping: true
								children: [
									ui.textbox(
										max_len:     20
										width:       200
										placeholder: 'Full name'
										text:        &app.full_name
									),
									ui.checkbox(checked: true, text: 'Do you like V?'),
									ui.button(text: 'Submit'),
								]
							),
						]
					),
				]
			),
		]
	)
	ui.run(app.window)
}
