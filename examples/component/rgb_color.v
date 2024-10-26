import ui
import ui.component as uic
import gx

const win_width = 200
const win_height = 400

fn main() {
	mut orientation := ui.Orientation.vertical
	$if horiz ? {
		orientation = .horizontal
	}
	color := gx.rgb(128, 128, 128)
	rect := ui.rectangle(
		id:     'rgb_rect'
		border: true
		color:  color
	)
	window := ui.window(
		width:  win_width
		height: win_height
		title:  'RGB color displayed in rectangle'
		mode:   .resizable
		layout: ui.column(
			margin_:  10
			spacing:  5
			heights:  [ui.stretch, 2 * ui.stretch, 7 * ui.stretch]
			children: [
				ui.button(
					id:       'rgb_btn'
					text:     'Show rgb color'
					on_click: btn_click
				),
				rect,
				uic.colorsliders_stack(
					id:          'colorsliders'
					color:       color
					orientation: orientation
					on_changed:  on_rgb_changed
				),
			]
		)
	)
	ui.run(window)
}

fn btn_click(b &ui.Button) {
	cs := uic.colorsliders_component_from_id(b.ui.window, 'colorsliders')
	txt := 'gx.rgb(${cs.r_textbox_text},${cs.g_textbox_text},${cs.b_textbox_text})'
	ui.message_box(txt)
}

fn on_rgb_changed(cs &uic.ColorSlidersComponent) {
	mut rect := cs.layout.ui.window.get_or_panic[ui.Rectangle]('rgb_rect')
	rect.style.color = cs.color()
}
