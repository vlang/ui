import ui
import webview

struct App {
	webview &webview.WebView
}

fn main() {
	
	mut app := &App{
		webview: voidptr(0)
	}
	window := ui.window({
		width: 800
		height: 100
		state: voidptr(0)
		title: 'V ui.webview demo'
	}, [
		ui.row({
			// stretch: true
			margin: ui.Margin{10, 10, 10, 10}
			height: 100
		}, [
			ui.button(
				text: 'Open'
				width: 70
				height: 100
				onclick: fn (a voidptr, b voidptr) {
					// println("onclick open")
					webview.new_window(
						url: "https://github.com/revosw/ui/tree/master",
						title: "hello"
					)
				}
			),
			ui.button(
				text: 'Navigate to google'
				onclick: fn (a voidptr, b voidptr) {
					// println("onclick google")
					// app.webview.navigate("https://google.com")
				}
			),
			ui.button(
				text: 'Navigate to steam'
				onclick: fn (a voidptr, b voidptr) {
					// println("onclick steam")
					// app.webview.navigate("https://steampowered.com")
				}
			),
			ui.button(
				text: 'Rig on_navigate'
				onclick: fn (a voidptr, b voidptr) {
					// println("onclick rig")
					// app.webview.on_navigate(fn (url string) {
					// 	exit(0)
					// })
				}
			),
			ui.button(
				text: 'Run javascript'
				onclick: fn (a voidptr, b voidptr) {
					// println("onclick javascript")
					// app.webview.exec("alert('Ran some javascript')")
				}
			),
		]
	)
	ui.run(window)
}
