import ui
import gx

fn main() {
	mut cv := ui.chunkview(
		id: 'cv'
		chunks: [ui.textchunk(0, 0, 'toto titi', 'red'),
			ui.textchunk(0, 30, 'toto titi tutu tatataaa', 'blue')]
	)
	mut window := ui.window(
		width: 800
		height: 600
		title: 'V UI: ChunkView'
		layout: ui.column(
			children: [
				ui.rectangle(
					height: 64
					width: 64
					color: gx.rgb(255, 100, 100)
				),
				cv,
			]
		)
	)
	// add DrawTextWidget specific style
	mut dtw := ui.DrawTextWidget(cv)
	dtw.add_style(
		id: 'red'
		size: 30
		font_name: 'fixed_bold_italic'
		color: gx.red
	)
	// Add global style
	window.add_style(
		id: 'blue'
		size: 20
		color: gx.blue
	)
	ui.run(window)
}
