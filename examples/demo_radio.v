import ui

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
	w := ui.window(
		width: 500
		height: 300
		mode: .resizable
		children: [c]
	)
	ui.run(w)
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
