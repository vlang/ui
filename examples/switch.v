import ui

const win_width = 250
const win_height = 250

@[heap]
struct App {
mut:
	label    &ui.Label
	switcher &ui.Switch = unsafe { nil }
	window   &ui.Window = unsafe { nil }
}

fn main() {
	mut app := &App{
		label: ui.label(text: 'Enabled')
	}
	app.switcher = ui.switcher(open: true, on_click: app.on_switch_click)
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Switch'
		mode:     .resizable
		children: [
			ui.row(
				alignment: .top
				spacing:   5
				margin:    ui.Margin{5, 5, 5, 5}
				widths:    ui.stretch
				children:  [
					app.label,
					app.switcher,
				]
			),
		]
	)
	ui.run(app.window)
}

fn (mut app App) on_switch_click(switcher &ui.Switch) {
	switcher_state := if switcher.open { 'Enabled' } else { 'Disabled' }
	app.label.set_text(switcher_state)
}
