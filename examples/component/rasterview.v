import ui
import ui.component as uic
import os

const win_width = 500
const win_height = 500

fn main() {
	window := ui.window(
		width:   win_width
		height:  win_height
		title:   'Grid'
		mode:    .resizable
		on_init: win_init
		layout:  ui.row(
			children: [
				uic.rasterview_canvaslayout(
					id: 'rv'
				),
			]
		)
	)
	ui.run(window)
}

fn win_init(mut w ui.Window) {
	mut rv := uic.rasterview_component_from_id(w, 'rv')
	rv.load_image(os.resource_abs_path(os.join_path('../../assets/img', 'logo.png')))
	// rv.load_image('../assets/img/icons8-cursor-67.png')
}
