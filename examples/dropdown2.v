import ui
import gx

const (
	win_width  = 250
	win_height = 250
)

struct App {
mut:
	window &ui.Window = 0
}

fn dd_change(mut app App, dd &ui.Dropdown) {
	println(dd.selected().text)
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Dropdown'
		state: app
	}, [
		ui.column({
			margin: 5
			widths: ui.compact
		}, [
			ui.dropdown({
				width: 140
				def_text: 'Select an option'
				on_selection_changed: dd_change
			}, [
				ui.DropdownItem{
					text: 'Delete all users'
				},
				ui.DropdownItem{
					text: 'Export users'
				},
				ui.DropdownItem{
					text: 'Exit'
				},
			]),
			ui.rectangle(
				height: 100
				width: 250
				color: gx.rgb(100, 255, 100)
			),
		]),
	])
	app.window = window
	ui.run(window)
}
