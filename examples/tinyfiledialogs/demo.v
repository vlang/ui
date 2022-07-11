import ui
import ui.tinyfiledialogs as tfd

fn main() {
	ui.window(
		title: 'Tiny File Dialogs'
		width: 200
		height: 200
		children: [
			ui.column(
				children: [
					ui.button(
						text: 'message'
						on_click: fn (b &ui.Button) {
							println(tfd.message('Hello World'))
						}
					),
					ui.button(
						text: 'input'
						on_click: fn (b &ui.Button) {
							println(tfd.input('title', 'text', 'default_text'))
						}
					),
					ui.button(
						text: 'password'
						on_click: fn (b &ui.Button) {
							println(tfd.password('title', 'text'))
						}
					),
					ui.button(
						text: 'open file'
						on_click: fn (b &ui.Button) {
							println(tfd.openfile('title'))
						}
					),
					ui.button(
						text: 'save file'
						on_click: fn (b &ui.Button) {
							println(tfd.savefile('title'))
						}
					),
					ui.button(
						text: 'select folder'
						on_click: fn (b &ui.Button) {
							println(tfd.selectfolder('title'))
						}
					),
					// ui.button(text: "color chooser", on_click: fn(b &ui.Button) {println(tfd.colorchooser("title", "#FFAABB"))})
					// ui.button(text: "notify popup", on_click: fn(b &ui.Button) {tfd.notifypopup("title", "text", "info")})
					ui.button(
						text: 'beep'
						on_click: fn (b &ui.Button) {
							tfd.beep()
						}
					),
				]
			),
		]
	).run()
}
