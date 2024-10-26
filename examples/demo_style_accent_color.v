import ui
import ui.component as uic
import gx

fn main() {
	win := ui.window(
		title:   'Accent color'
		mode:    .resizable
		on_init: win_init
		height:  600
		layout:  ui.column(
			heights:  [100.0, ui.stretch]
			children: [
				ui.row(
					widths:   [6 * ui.stretch, 4 * ui.stretch]
					children: [
						uic.colorsliders_stack(
							id:          'cs'
							orientation: .horizontal
							color:       gx.white
							on_changed:  on_accent_color_changed
						),
						ui.row(
							margin_:  10
							spacing:  5
							bg_color: gx.white
							widths:   ui.stretch
							children: [
								ui.rectangle(id: 'rect0', text: '0', border: true),
								ui.rectangle(id: 'rect1', text: '1', border: true),
								ui.rectangle(id: 'rect2', text: '2', border: true),
								ui.rectangle(id: 'rect3', text: '3', border: true),
							]
						),
					]
				),
				uic.demo_stack(),
			]
		)
	)
	ui.run(win)
}

fn on_accent_color_changed(mut cs uic.ColorSlidersComponent) {
	color := cs.color()
	mut gui := cs.layout.ui
	// load accnt color for the window
	gui.window.load_accent_color_style([int(color.r), color.g, color.b])
	// get current accent colors
	colors := gui.style_colors
	// show the 4 accent colors
	for i in 0 .. 4 {
		mut rect := gui.window.get_or_panic[ui.Rectangle]('rect${i}')
		rect.update_style_params(color: colors[i])
	}
}

fn win_init(w &ui.Window) {
	mut cs := uic.colorsliders_component_from_id(w, 'cs')
	ac := [100, 40, 150]
	cs.set_color(gx.rgb(u8(ac[0]), u8(ac[1]), u8(ac[2])))
	on_accent_color_changed(mut cs)
}
