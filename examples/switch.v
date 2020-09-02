import ui

const (
	win_width  = 250
	win_height = 250
)

struct App {
mut:
	label    &ui.Label
	switcher &ui.Switch
	window   &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
		label: ui.label({
			text: 'Enabled'
		})
		switcher: ui.switcher({
			open: true
			onclick: on_switch_click
		})
	}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Switch'
		state: app
	}, [
		ui.row({
			alignment: .top
			spacing: 5
			stretch: true
			margin: ui.MarginConfig{5, 5, 5, 5}
		}, [
			app.label,
			app.switcher,
		]),
	])
	ui.run(app.window)
}

fn on_switch_click(mut app App, switcher &ui.Switch) {
	switcher_state := if switcher.open { 'Enabled' } else { 'Disabled' }
	app.label.set_text(switcher_state)
}
