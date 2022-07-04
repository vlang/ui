import ui
import ui.component as uic
import gx

window := ui.window(
	width: 800
	height: 600
	title: 'V UI: SplitPanel'
	mode: .resizable
	children: [
		ui.column(
			heights: [ui.stretch, 2 * ui.stretch]
			children: [ui.rectangle(
				color: gx.rgb(100, 255, 100)
			),
				ui.row(
					margin_: 5
					spacing: 5
					widths: [1.0 / 3 * ui.stretch, 2.0 / 3 * ui.stretch]
					children: [ui.rectangle(
						color: gx.rgb(100, 255, 100)
					),
						uic.splitpanel_stack(
							// direction: .column
							child1: ui.rectangle(
								color: gx.rgb(100, 100, 255)
							)
							child2: ui.rectangle(
								color: gx.rgb(255, 100, 255)
							)
						)]
				)]
		),
	]
)
ui.run(window)
