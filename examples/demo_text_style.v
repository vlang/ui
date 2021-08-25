module main

import ui
import gx

struct App {
mut:
	window &ui.Window = 0
	log    string
	font   string = 'il était une fois ....'
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		state: app
		mode: .resizable
		height: 240
		on_init: window_init
		children: [
			ui.column(
				widths: ui.stretch
				children: [
					ui.dropdown(
						id: 'dd'
						width: 140
						def_text: 'Select a font'
						on_selection_changed: dd_change
					),
					ui.textbox(
						id: 'font'
						text: &app.font
					),
					ui.canvas_plus(
						id: 'c'
						height: 200
						on_draw: on_draw
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn window_init(mut w ui.Window) {
	// app := &App(w.state)
	w.ui.add_font('arial', '/System/Library/Fonts/Supplemental/Arial.ttf')
	w.ui.add_font('arial-bold', '/System/Library/Fonts/Supplemental/Arial Bold.ttf')
	// w.ui.add_font("hira", "/Users/rcqls/Downloads/HIRAGANA.ttf")
	w.ui.add_font('brush', '/System/Library/Fonts/Supplemental/Brush Script.ttf')
	// w.ui.add_font("emoji", "/Users/rcqls/Downloads/EmojiOneColor-SVGinOT-OSX-1.4/EmojiOneColor-SVGinOT-OSX.ttf")
	c := w.canvas_layout('c')
	mut dd := w.dropdown('dd')
	mut dtw := ui.DrawTextWidget(c)
	dtw.add_style(
		id: 'brush'
		font_name: 'brush'
		size: 24
	)
	dd.add_item('brush')
	dtw.add_style(
		id: 'arial'
		font_name: 'arial'
		size: 30
		color: gx.blue
	)
	dd.add_item('arial')
	dtw.add_style(
		id: 'arial-bold'
		font_name: 'arial-bold'
		size: 30
		color: gx.red
	)
	dd.add_item('arial-bold')
	dtw.set_style('arial')
}

fn on_draw(c &ui.CanvasLayout, app &App) {
	mut dtw := ui.DrawTextWidget(c)
	dtw.load_current_style()
	c.draw_text(10, 10, app.font)
	w, h := dtw.text_size(app.font)
	c.draw_empty_rect(10, 11, w + 2, h + 2)
	c.draw_styled_text(10 + w + 10, 10, 'size: ($w, $h)', 'default')
}

fn dd_change(mut app App, dd &ui.Dropdown) {
	w := dd.ui.window
	c := w.canvas_layout('c')
	mut dtw := ui.DrawTextWidget(c)
	style := dd.selected().text
	println('style selected: $style')
	dtw.set_style(style)
}
