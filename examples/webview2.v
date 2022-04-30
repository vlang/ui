import ui
import ui.webview

struct App {
	webview &webview.WebView
}

fn main() {
	mut app := &App{
		webview: voidptr(0)
	}
	window := ui.window(
		width: 800
		height: 100
		state: voidptr(0)
		title: 'V ui.webview demo'
		children: [
			ui.column(
				// stretch: true
				margin: ui.Margin{10, 10, 10, 10}
				height: 800
				children: [
					ui.button(
						text: 'Open'
						width: 70
						height: 100
						onclick: fn (a voidptr, b voidptr) {
							// println("onclick open")
						}
					),
					webview.new_window(
						url: 'https://github.com/revosw/ui/tree/master'
						title: 'hello'
					),
				]
			),
		]
	)
	ui.run(window)
}
