import ui
import gx

fn main() {
	window := ui.window(
		width: 200
		height: 110
		title: 'Flight booker'
		mode: .resizable
		children: [
			ui.column(
				spacing: 5
				margin_: 5
				// widths: ui.stretch
				// heights: ui.stretch
				children: [
					ui.dropdown(
						id: 'dd'
						z_index: 10
						selected_index: 0
						on_selection_changed: dd_change
						items: [
							ui.DropdownItem{
								text: 'one-way flight'
							},
							ui.DropdownItem{
								text: 'return flight'
							},
						]
					),
					ui.textbox(id: 'tb_oneway', on_changed: on_changed_oneway),
					ui.textbox(id: 'tb_return', read_only: true, on_changed: on_changed_return),
					ui.button(
						id: 'btn_book'
						text: 'Book'
						radius: 5
						bg_color: gx.light_gray
						onclick: btn_book_click
					),
				]
			),
		]
	)
	ui.run(window)
}

fn dd_change(a voidptr, dd &ui.Dropdown) {
	mut tb_return := dd.ui.window.textbox('tb_return')
	match dd.selected().text {
		'one-way flight' {
			tb_return.read_only = true
		}
		else {
			tb_return.read_only = false
		}
	}
}

fn on_changed_oneway(mut tb ui.TextBox, a voidptr) {
}

fn on_changed_return(mut tb ui.TextBox, a voidptr) {
}

fn btn_book_click(a voidptr, btn &ui.Button) {
}
