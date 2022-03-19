import ui
import ui.component as uic
import gg

const (
	win_width  = 500
	win_height = 500
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Grid'
		state: app
		mode: .resizable
		on_init: win_init
		children: [
			ui.row(
				children: [
					uic.rasterview_canvaslayout(
						id: 'rv'
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn win_init(mut w ui.Window) {
	mut rv := uic.rasterview_component_from_id(w, 'rv')
	// rv.load('/Users/rcqls/Github/ui/assets/img/icons8-cursor-67.png')
	rv.load('/Users/rcqls/Github/ui/assets/img/cursor.png')
}
