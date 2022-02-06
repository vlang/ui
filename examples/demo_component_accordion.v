import ui
import ui.component as uic
import gx

const (
	win_width  = 30 + 256 + 4 * 10 + uic.cb_cv_hsv_w
	win_height = 376
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	rect := ui.rectangle(
		text: 'Here a simple ui rectangle '
		color: gx.red
		text_cfg: gx.TextCfg{
			color: gx.blue
			align: gx.align_left
			size: 30
		}
	)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Accordion'
		state: app
		native_message: false
		children: [
			uic.accordion(
				id: 'toto'
				titles: ['toto', 'tata', 'titi']
				children: [rect,
					ui.rectangle(
					text: 'Here a simple ui rectangle2 '
					color: gx.blue
					text_cfg: gx.TextCfg{
						color: gx.red
						align: gx.align_left
						size: 30
					}
				),
					ui.rectangle(
						text: 'Here a simple ui rectangle3 '
						color: gx.yellow
						text_cfg: gx.TextCfg{
							color: gx.orange
							align: gx.align_left
							size: 30
						}
					)]
			),
		]
	)
	app.window = window
	ui.run(window)
}
