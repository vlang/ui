import ui
import webview

struct App {
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: 100
		height: 70
		state: app
		title: 'V ui.webview demo'
	}, [
		ui.row({
			// stretch: true
			margin: ui.Margin{10, 10, 10, 10}
		}, [
			ui.button(
				text: 'Open'
				width: 70
				onclick: fn (a voidptr, b voidptr) {
					webview.new_window(url: 'https://vlang.io', title: 'The V programming language')
				}
			),
		]),
	])
	ui.run(window)
}
