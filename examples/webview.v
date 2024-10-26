import ui.webview
import ui

@[heap]
struct App {
mut:
	webview &webview.WebView
}

fn main() {
	mut app := &App{
		webview: webview.new_window(
			url:   'https://github.com/revosw/ui/tree/master'
			title: 'hello'
		)
	}
	window := ui.window(
		width:    800
		height:   100
		title:    'V ui.webview demo'
		children: [
			ui.row(
				// stretch: true
				margin_:  10
				height:   100
				children: [
					ui.button(
						text:     'Open'
						width:    70
						height:   100
						on_click: app.btn_open_click
					),
					ui.button(
						text:     'Navigate to google'
						on_click: fn (b &ui.Button) {
							// println("on_click google")
							// app.webview.navigate("https://google.com")
						}
					),
					ui.button(
						text:     'Navigate to steam'
						on_click: fn (b &ui.Button) {
							// println("on_click steam")
							// app.webview.navigate("https://steampowered.com")
						}
					),
					ui.button(
						text:     'Rig on_navigate'
						on_click: fn (b &ui.Button) {
							// println("on_click rig")
							// app.webview.on_navigate(fn (url string) {
							// 	exit(0)
							// })
						}
					),
					ui.button(
						text:     'Run javascript'
						on_click: fn (b &ui.Button) {
							// println("on_click javascript")
							// app.webview.exec("alert('Ran some javascript')")
						}
					),
				]
			),
		]
	)
	ui.run(window)
}

fn (mut app App) btn_open_click(b &ui.Button) {
	// println("on_click open")
	app.webview.navigate('https://github.com/revosw/ui/tree/master')
}
