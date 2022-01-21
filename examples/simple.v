import ui

fn main() {
	lbl := ui.label(text: 'Label')
	window := ui.window(
		width: 300
		height: 200
		children: [ui.row(children: [lbl])]
	)
	ui.run(window)
}
