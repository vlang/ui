import ui
import ui.component as uic
import gx

fn main() {
	mut win := ui.window(
		title:   'Four colors'
		mode:    .resizable
		on_init: win_init
		height:  600
		layout:  ui.column(
			heights:  [100.0, ui.stretch]
			children: [
				ui.row(
					widths:   ui.stretch
					children: [
						uic.colorbutton(
							id:         'color0'
							on_changed: on_changed
						),
						uic.colorbutton(
							id:         'color1'
							on_changed: on_changed
						),
						uic.colorbutton(
							id:         'color2'
							on_changed: on_changed
						),
						uic.colorbutton(
							id:         'color3'
							on_changed: on_changed
						),
					]
				),
				uic.demo_stack(),
			]
		)
	)
	uic.colorbox_subwindow_add(mut win)
	ui.run(win)
}

fn on_changed(mut cbc uic.ColorButtonComponent) {
	mut gui := cbc.widget.ui
	i := cbc.widget.id[5..].int()
	// println("$cbc.widget.id changed -> $i")
	// println(gui.style_colors)
	gui.style_colors[i] = cbc.bg_color
	gui.window.load_4colors_style(gui.style_colors)
}

fn win_init(w &ui.Window) {
	mut gui := w.ui
	gui.window.load_4colors_style([gx.white, gx.light_gray, gx.light_blue, gx.black])
	for i in 0 .. 4 {
		mut cbc := uic.colorbutton_component_from_id(w, 'color${i}')
		cbc.bg_color = gui.style_colors[i]
	}
}
