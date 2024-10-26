import ui
// import gx
// import gg
import ui.component as uic
import os.font

fn main() {
	mut window := ui.window(
		width:  800
		height: 600
		title:  'V UI Settings'
		mode:   .resizable
		// on_key_down: fn(e ui.KeyEvent, wnd &ui.Window) {
		// println('key down')
		//}
		layout: ui.column(
			// alignment: .center
			spacing:  5
			margin_:  5
			widths:   ui.stretch
			heights:  25.0
			children: [
				uic.setting_font(id: 'color', text: 'toto'),
				uic.setting_font(id: 'color2', text: 'toto2'),
			]
		)
	)
	uic.fontchooser_subwindow_add(mut window)
	println(font.default())
	ui.run(window)
}
