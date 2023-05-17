import ui
import gx

fn main() {
	mut cv := ui.chunkview(
		id: 'cv'
		chunks: [ui.textchunk(0, 0, 'toto titi', 'red'), ui.textchunk(0, 30, 'toto titi',
			'blue'),
			ui.textchunk(0, 60, '😻🥰 😬🧿 🫥😴  ✔️💾', 'emoji'),
			ui.parachunk(
				y: 100
				content: ['<red>', 'toto titi tata toto titi tata', '<blue>',
					'toto titi tata toto titi tata toto titi tata', '<emoji>',
					'😻🥰 😬🧿 🫥😴  ✔️💾']
			)]
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
		size: 20
		font_name: 'fixed_bold_italic'
		color: gx.red
	)
	// Add global style
	window.add_style(
		id: 'blue'
		size: 30
		font_name: 'system'
		color: gx.blue
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
