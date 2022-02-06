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
	c := ui.column(
		widths: ui.stretch
		margin_: 5
		spacing: 10
		children: [
			ui.row(
				spacing: 5
				children: [
					ui.label(text: 'Compact'),
					ui.switcher(open: true, onclick: on_switch_click),
				]
			),
			ui.radio(
				id: 'rh1'
				horizontal: true
				compact: true
				values: [
					'United States',
					'Canada',
					'United Kingdom',
					'Australia',
				]
				title: 'Country'
			),
			ui.radio(
				values: [
					'United States',
					'Canada',
					'United Kingdom',
					'Australia',
				]
				title: 'Country'
			),
			ui.row(
				widths: [
					ui.compact,
					ui.stretch,
				]
				children: [
					ui.label(text: 'Country:'),
					ui.radio(
						id: 'rh2'
						horizontal: true
						compact: true
						values: ['United States', 'Canada', 'United Kingdom', 'Australia']
					),
				]
			),
		]
	)
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
				children: [c,
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

fn on_switch_click(mut app voidptr, switcher &ui.Switch) {
	// switcher_state := if switcher.open { 'Enabled' } else { 'Disabled' }
	// app.label.set_text(switcher_state)
	mut rh1 := switcher.ui.window.radio('rh1')
	rh1.compact = !rh1.compact
	mut rh2 := switcher.ui.window.radio('rh2')
	rh2.compact = !rh2.compact
	switcher.ui.window.update_layout()
}
