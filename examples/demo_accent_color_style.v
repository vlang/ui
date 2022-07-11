import ui
import ui.component as uic
import gx

fn main() {
	win := ui.window(
		title: 'Accent color'
		mode: .resizable
		on_init: win_init
		children: [
			ui.column(
				heights: [100.0, ui.stretch]
				children: [
					uic.colorsliders_stack(
						id: 'cs'
						orientation: .horizontal
						color: gx.white
						on_changed: on_accent_color_changed
					),
					uic.demo_stack(),
				]
			),
		]
	)
	ui.run(win)
}

fn on_accent_color_changed(mut cs uic.ColorSlidersComponent) {
	color := cs.color()
	cs.layout.ui.update_style_from_accent_color([int(color.r), color.g, color.b])
	mut l := ui.Layout(cs.layout.ui.window)
	l.update_theme_style('accent_color')
}

fn win_init(w &ui.Window) {
	mut cs := uic.colorsliders_component_from_id(w, 'cs')
	ac := cs.layout.ui.accent_color
	cs.set_color(gx.rgb(u8(ac[0]), u8(ac[1]), u8(ac[2])))
	on_accent_color_changed(mut cs)
}
