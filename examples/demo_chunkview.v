import ui
import gx

fn main() {
	mut cv := ui.chunkview(
		id: 'cv'
		chunks: [
			ui.parachunk(
				y: 20
				margin: 5
				content: ['|h2|TextChunk']
			),
			ui.textchunk(0, 60, 'toto titi', 'red'),
			ui.textchunk(0, 80, 'toto titi', 'blue'),
			ui.textchunk(0, 100, '😻🥰 😬🧿 🫥😴  ✔️💾', 'emoji'),
			ui.parachunk(
				y: 200
				margin: 5
				content: ['|h2|ParaChunk']
			),
			ui.parachunk(
				y: 240
				indent: 20
				content: ['|red|toto titi tata toto titi tata ',
					'|blue|toto titi tata toto titi tata toto titi tata ',
					'|emoji|😻🥰😬 🧿🫥😴  ✔️💾']
			),
		]
	)
	mut window := ui.window(
		width: 800
		height: 600
		title: 'V UI: ChunkView'
		layout: ui.column(
			heights: [ui.compact, ui.stretch]
			children: [
				ui.rectangle(
					height: 30
					color: gx.rgb(255, 100, 100)
				),
				ui.row(
					children: [
						ui.rectangle(
							width: 30
							color: gx.rgb(255, 100, 100)
						),
						cv,
						ui.rectangle(
							width: 30
							color: gx.rgb(255, 100, 100)
						),
					]
				),
				ui.rectangle(
					height: 30
					color: gx.rgb(255, 100, 100)
				),
			]
		)
	)
	// add DrawTextWidget specific style
	mut dtw := ui.DrawTextWidget(cv)
	dtw.add_style(
		id: 'red'
		size: 20
		font_name: 'fixed_bold'
		color: gx.red
	)
	// Add global style
	window.add_style(
		id: 'blue'
		size: 30
		font_name: 'system'
		color: gx.blue
	)
	// Add global style
	window.add_style(
		id: 'h2'
		size: 40
		font_name: 'fixed_bold_italic'
	)
	// emoji
	window.add_style(
		id: 'emoji'
		size: 20
		font_name: 'noto_emoji'
		mono: false
	)
	ui.run(window)
}
