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
	dtw.update_text_style(size: 30)
	mut window := ui.window(
		state: app
		mode: .resizable
		width: 800
		height: 600
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
						uic.button_font(
							text: 'font'
							dtw: tb
						),
						uic.button_color(
							bg_color: &tb.text_styles.current.color
						),
						uic.button_color(
							bg_color: &tb.bg_color
						),
					]
				),
					tb]
			),
		]
	)
	app.window = window
	uic.fontchooser_subwindow_add(mut window)
	uic.colorbox_subwindow_add(mut window)
	ui.run(app.window)
}
