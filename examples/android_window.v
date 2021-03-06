import ui

struct App {
mut:
	window &ui.Window
	text   string
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window({
		title: 'V Android Test'
		width: 800
		height: 600
		state: app
		mode: .max_size
	}, [
		ui.column({
			margin_: .2
			widths: ui.stretch
		}, [
			ui.button(
				text: 'Config?'
				onclick: fn (a voidptr, b voidptr) {
					$if android {
						println('orientation: ${ui.android_config(.orientation)}')
						println('touchscreen: ${ui.android_config(.touchscreen)}')
						println('screensize: ${ui.android_config(.screensize)}')
						println('SDK version: ${ui.android_config(.sdkversion)}')
					} $else {
						ui.message_box('Only for Android')
					}
				}
			),
		]),
	])
	app.window = window
	ui.run(window)
}
