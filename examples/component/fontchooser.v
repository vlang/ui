import ui
import ui.component as uic
import gx

struct App {
mut:
	window &ui.Window = 0
	log    string
	text   string = 'il était une fois V ....\nLa vie est belle...'
}

fn main() {
	mut app := &App{}
	mut tb := ui.textbox(
		id: 'tb'
		text: &app.text
		mode: .multiline
		bg_color: gx.yellow
	)
	mut dtw := ui.DrawTextWidget(tb)
	dtw.update_style(size: 30, color: gx.red)
	mut window := ui.window(
		mode: .resizable
		width: 800
		height: 600
		on_init: fn (win &ui.Window) {
			mut btn := win.button('txt_color')
			tb := win.textbox('tb')
			(*btn.bg_color) = tb.text_styles.current.color
		}
		children: [
			ui.column(
				margin_: 10
				heights: [20.0, ui.stretch]
				spacing: 10
				children: [
					ui.row(
						widths: ui.compact
						spacing: 10
						children: [
							uic.fontbutton(
								text: 'font'
								dtw: tb
							),
							uic.colorbutton(
								id: 'txt_color'
								// bg_color: &tb.text_styles.current.color
								// DO NOT REMOVE: more general alternative with callback
								on_changed: fn (cbc &uic.ColorButtonComponent) {
									mut tv := cbc.widget.ui.window.textbox('tb').tv
									tv.update_style(color: cbc.bg_color)
								}
							),
							uic.colorbutton(
								id: 'bg_color'
								bg_color: &tb.style.bg_color
							),
						]
					),
					tb,
				]
			),
		]
	)
	app.window = window
	uic.fontchooser_subwindow_add(mut window)
	uic.colorbox_subwindow_add(mut window)
	ui.run(app.window)
}
