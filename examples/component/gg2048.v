import ui.component as uic
import ui
import gx
import ui.apps.v2048

fn main() {
	mut app := v2048.new_ui_app()
	mut app2 := v2048.new_ui_app()
	mut win := ui.window(
		title: '2048 inside VUI'
		width: 800
		height: 800
		mode: .resizable
		layout: ui.box_layout(
			children: {
				'tb: (0.1, 0.1) -> (0.4,0.4)':   ui.textbox(
					mode: .multiline
					id: 'edit'
					z_index: 20
					height: 200
					line_height_factor: 1.0 // double the line_height
					text_size: 24
					text_font_name: 'fixed'
					bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
				)
				'gg: (0.41, 0.41) -> (0.9,0.9)': uic.gg_canvaslayout(
					id: 'gg2048'
					app: app
				)
				'gg2: (0.1, 0.5) -> (0.45,0.9)': uic.gg_canvaslayout(
					id: 'gg2048bis'
					app: app2
				)
			}
		)
	)
	ui.run(win)
}
