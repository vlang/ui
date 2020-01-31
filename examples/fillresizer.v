import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	window     &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'FillResizer'
		user_ptr: app
		resizer: ui.resizer({
			layout: .row
			align: .horizontal //horizontal //vertical
			wrap: true
		})
	}, [
		ui.button({
			text: 'Add user1'
		}) as ui.IWidgeter,
		ui.button({
			text: 'Add user2'
		}) as ui.IWidgeter,
		ui.button({
			text: 'Add user3'
		}) as ui.IWidgeter,
		ui.dropdown({
			width: 140
			def_text: "Select an option"
			items: [
				ui.DropdownItem{text:'Delete all users'},
				ui.DropdownItem{text:'Export users'},
				ui.DropdownItem{text:'Exit'},
			]
		}) as ui.IWidgeter,
	])
	app.window = window
	ui.run(window)
}