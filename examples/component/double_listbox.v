import ui
import ui.component as uic

const win_width = 600
const win_height = 400

fn main() {
	window := ui.window(
		width:          win_width
		height:         win_height
		title:          'V UI: Composable Widget'
		mode:           .resizable
		native_message: false
		layout:         ui.column(
			margin_:  .05
			spacing:  .05
			heights:  [8 * ui.stretch, ui.stretch, ui.stretch]
			children: [
				ui.row(
					spacing:  .1
					margin_:  5
					widths:   ui.stretch
					children: [
						uic.doublelistbox_stack(
							id:    'dlb1'
							title: 'dlb1'
							items: [
								'totto',
								'titi',
							]
						),
						uic.doublelistbox_stack(
							id:    'dlb2'
							title: 'dlb2'
							items: [
								'tottoooo',
								'titi',
								'tototta',
							]
						),
					]
				),
				ui.button(id: 'btn1', text: 'get values for dlb1', on_click: btn_click),
				ui.button(id: 'btn2', text: 'get values for dlb2', on_click: btn_click),
			]
		)
	)
	ui.run(window)
}

fn btn_click(b &ui.Button) {
	dlb := uic.doublelistbox_component_from_id(b.ui.window, if b.id == 'btn1' {
		'dlb1'
	} else {
		'dlb2'
	})
	res := 'result(s) : ${dlb.values()}'
	println(res)
	b.ui.window.message(res)
}
