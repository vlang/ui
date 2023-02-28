import ui
import ui.component as uic
import gx

const (
	win_width  = 30 + 256 + 4 * 10 + uic.cb_cv_hsv_w
	win_height = 376
)

fn main() {
	cb_layout := uic.colorbox_stack(id: 'cbox', light: false, hsl: false)
	rect := ui.rectangle(text: 'Here a simple ui rectangle')
	mut dtw := ui.DrawTextWidget(rect)
	dtw.update_style(color: gx.blue, size: 30)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: Toolbar'
		native_message: false
		layout: ui.column(
			heights: [ui.compact, ui.compact]
			children: [cb_layout, rect]
		)
	)
	mut cb := uic.colorbox_component(cb_layout)
	cb.connect(&rect.style.color)
	ui.run(window)
}
