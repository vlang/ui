import ui
import ui.component as uic
import gx
import os

const (
	win_width  = 800
	win_height = 600
)

struct App {
mut:
	window &ui.Window
	text   string
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: TreeView'
		state: app
		native_message: false
		mode: .resizable
		children: [
			ui.row(
				widths: [ui.stretch, ui.stretch * 2]
				children: [
					ui.column(
					scrollview: true
					heights: ui.compact
					children: [
						uic.treeview(
							id: 'demo'
							trees: [
								uic.treedir('.'),
							]
							icons: {
								'folder': 'tata'
								'file':   'toto'
							}
							text_color: gx.gray
							bg_color: gx.hex(0xfcf4e4ff)
							on_click: treeview_onclick
						),
					]
				),
					ui.textbox(
						mode: .multiline | .word_wrap
						id: 'edit'
						height: 200
						text: &app.text
						text_size: 24
						bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
					)]
			),
		]
	)
	app.window = window
	ui.run(window)
}

fn treeview_onclick(c &ui.CanvasLayout, mut tv uic.TreeView) {
	selected := c.id
	println('$selected selected with title: ${tv.titles[selected]}!')
	mut app := &App(c.ui.window.state)
	file := tv.full_title(selected)
	app.text = os.read_file(file) or { '' }
}
