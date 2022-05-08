import ui
import gx

fn main() {
	window := ui.window(
		width: 500
		height: 400
		title: 'Circle drawer'
		mode: .resizable
		children: [
			ui.column(
				spacing: 10
				margin_: 20
				widths: ui.stretch
				heights: [ui.compact, ui.stretch]
				children: [
					ui.row(
						spacing: 20
						widths: [ui.stretch, 40, 40, ui.stretch]
						children: [ui.spacing(), ui.button(text: 'Undo', radius: 5),
							ui.button(text: 'Redo', radius: 5),
							ui.spacing()]
					),
					ui.canvas_plus(bg_color: gx.white, bg_radius: .025),
				]
			),
		]
	)
	ui.run(window)
}
