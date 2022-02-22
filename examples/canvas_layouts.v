import ui
import gx
import os

const (
	win_width  = 500
	win_height = 385
)

fn main() {
	mut children := []ui.Widget{}
	for i, tab in ['tab1', 'tab2', 'tab3'] {
		children << ui.canvas_layout(
			id: '$tab'
			bg_color: gx.white
			children: [
				ui.at(0, 0, ui.label(text: tab)),
			]
		)
	}
	tab_bar := ui.row(
		id: 'row_tabbar'
		widths: 50.0
		heights: 30.0
		spacing: 3
		children: children
	)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI Demo'
		mode: .resizable
		children: [tab_bar]
	)

	ui.run(window)
}
