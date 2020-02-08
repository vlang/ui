import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	dropdown   &ui.Dropdown
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Dropdown'
		user_ptr: app
	}, [
		ui.IWidgeter(ui.column({
			stretch: true
			alignment: .left
			margin: ui.MarginConfig{5,5,5,5}
		},
		[
			ui.IWidgeter(ui.dropdown({
				width: 140
				def_text: "Select an option"
				items: [
					ui.DropdownItem{text:'Delete all users'},
					ui.DropdownItem{text:'Export users'},
					ui.DropdownItem{text:'Exit'},
				]
			}))
		]))
	])
	app.window = window
	ui.run(window)
}