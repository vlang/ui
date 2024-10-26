import ui
import gx

fn main() {
	mut sc_cv := false
	$if sc_cv ? {
		sc_cv = true
	}
	mut cv := ui.chunkview(
		id:         'cv'
		scrollview: sc_cv
		bg_color:   gx.white
		chunks:     [
			ui.rowchunk(
				y:       20
				spacing: 20
				margin:  20
				chunks:  [
					ui.rowchunk(
						spacing: 5
						chunks:  [
							ui.parachunk(
								margin:  5
								content: ['|h2|TextChunk']
							),
							ui.textchunk(text: 'toto titi', style: 'red'),
							ui.textchunk(text: 'toto titi', style: 'blue'),
							ui.textchunk(
								text:  '😻🥰 😬🧿 🫥😴  ✔️💾'
								style: 'emoji'
							),
						]
					),
					// ui.parachunk(
					// 	y: 240
					// 	indent: 20
					// 	content: ['|red|toto titi tata toto titi tata ', '||tutu tete ',
					// 		'|blue|toto titi tata toto titi tata toto titi tata ',
					// 		'|emoji|😻🥰😬 🧿🫥😴  ✔️💾', 'br', 'br',
					// 		'|red|toto2 titi tata toto titi tata ', '||tutu2 tete ',
					// 		'|blue|toto2 titi tata toto titi tata toto titi tata ',
					// 		'|emoji|😻🥰😬 🧿🫥😴  ✔️💾']
					// ),
					ui.rowchunk(
						// x: 0 // 30
						// y: 100
						margin:  10
						spacing: 20
						chunks:  [
							ui.parachunk(
								margin:  5
								content: ['|h2|RowChunk with ParaChunk']
							),
							ui.rowchunk(
								spacing:   10
								margin:    20
								bg_color:  gx.yellow
								bg_radius: 10
								chunks:    [
									ui.valignchunk(
										// indent: 20
										align:   0.5
										content: [
											'|red|toto titi tata toto titi tata ',
											'||tutu tete ',
											'|blue|toto titi tata toto titi tata toto titi tata ',
											'|emoji|😻🥰😬 🧿🫥😴  ✔️💾',
											'br',
											'br',
											'|red|toto2 titi tata toto titi tata ',
											'br',
											'||tutu2 tete ',
											'br',
											'|blue|toto2 titi tata toto titi tata toto titi tata ',
											'br',
											'||tutu2 tete ',
											'|emoji|😻🥰😬 🧿🫥😴  ✔️💾',
										]
									),
									ui.textchunk(text: 'toto titi', style: 'red'),
								]
							),
							ui.rowchunk(
								spacing:   10
								margin:    20
								bg_color:  gx.dark_gray
								bg_radius: 10
								chunks:    [
									ui.parachunk(
										indent:  20
										content: [
											'|red|toto titi tata toto titi tata ',
											'||tutu tete ',
											'|blue|toto titi tata toto titi tata toto titi tata ',
											'|emoji|😻🥰😬 🧿🫥😴  ✔️💾',
											'br',
											'br',
											'|red|toto2 titi tata toto titi tata ',
											'||tutu2 tete ',
											'|blue|toto2 titi tata toto titi tata toto titi tata ',
											'|emoji|😻🥰😬 🧿🫥😴  ✔️💾',
										]
									),
									ui.textchunk(text: 'toto titi', style: 'red'),
								]
							),
						]
					),
				]
			),
		]
	)
	mut window := ui.window(
		width:  1200
		height: 800
		title:  'V UI: ChunkView'
		layout: ui.column(
			heights:  [ui.compact, ui.compact, ui.stretch]
			children: [
				ui.row(
					margin_:  5
					bg_color: gx.white
					children: [
						ui.slider(
							width:            200
							height:           20
							orientation:      .horizontal
							min:              0
							max:              100
							val:              50
							on_value_changed: fn (slider &ui.Slider) {
								mut cv := ui.Widget(slider).get[ui.ChunkView]('cv')
								mut res := cv.chunk(0, 1, 1, 0)
								if mut res is ui.VerticalAlignChunk {
									res.align = f32(slider.val) / 100.0
								}
								cv.update()
							}
						),
						ui.label(text: '  First RowChunk '),
						ui.switcher(open: true, id: 'sw1', on_click: on_switch),
						ui.label(text: '  Second RowChunk '),
						ui.switcher(open: true, id: 'sw2', on_click: on_switch),
					]
				),
				ui.rectangle(
					height: 30
					color:  gx.rgb(255, 100, 100)
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
					color:  gx.rgb(255, 100, 100)
				),
			]
		)
	)
	// add DrawTextWidget specific style
	mut dtw := ui.DrawTextWidget(cv)
	dtw.add_style(
		id:        'red'
		size:      20
		font_name: 'fixed_bold'
		color:     gx.red
	)
	// Add global style
	window.add_style(
		id:        'blue'
		size:      30
		font_name: 'system'
		color:     gx.blue
	)
	// Add global style
	window.add_style(
		id:        'h2'
		size:      40
		font_name: 'fixed_bold_italic'
	)
	// emoji
	window.add_style(
		id:        'emoji'
		size:      20
		font_name: 'noto_emoji'
		mono:      false
	)
	ui.run(window)
}

fn on_switch(switcher &ui.Switch) {
	i := match switcher.id {
		'sw1' { 1 }
		else { 2 }
	}
	color := match switcher.id {
		'sw2' { gx.dark_gray }
		else { gx.yellow }
	}
	mut cv := ui.Widget(switcher).get[ui.ChunkView]('cv')
	mut res := cv.chunk(0, 1, i)
	if mut res is ui.RowChunk {
		// res.align = f32(slider.val) / 100.0
		if res.bg_color == color {
			res.bg_color = ui.no_color
		} else {
			res.bg_color = color
		}
	}
	cv.update()
}
