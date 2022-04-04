import ui
import gx
import os

struct App {
mut:
	window    &ui.Window = 0
	log       string
	text      string = 'il était une fois V ....'
	prev_font string
}

fn main() {
	mut app := &App{}
	app.window = ui.window(
		state: app
		mode: .resizable
		height: 240
		on_init: window_init
		children: [
			ui.row(
				widths: ui.stretch
				children: [
					ui.listbox(
						id: 'lb'
						draw_lines: true
						// scrollview: false
						on_change: lb_change
					),
					ui.column(
						children: [
							ui.textbox(
								id: 'font'
								text: &app.text
							),
							ui.canvas_plus(
								id: 'c'
								height: 200
								on_draw: on_draw
							),
						]
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn window_init(mut w ui.Window) {
	// app := &App(w.state)
	// w.ui.add_font('arial', '/System/Library/Fonts/Supplemental/Arial.ttf')
	// w.ui.add_font('arial-bold', '/System/Library/Fonts/Supplemental/Arial Bold.ttf')
	// // w.ui.add_font("hira", "/Users/rcqls/Downloads/HIRAGANA.ttf")
	// w.ui.add_font('brush', '/System/Library/Fonts/Supplemental/Brush Script.ttf')
	// w.ui.add_font("emoji", "/Users/rcqls/Downloads/EmojiOneColor-SVGinOT-OSX-1.4/EmojiOneColor-SVGinOT-OSX.ttf")
	mut font_root_path := ''
	$if windows {
		font_root_path = 'C:/windows/fonts'
	}
	$if macos {
		font_root_path = '/System/Library/Fonts/*'
	}
	$if linux {
		font_root_path = '/usr/share/fonts/truetype/*'
	}
	font_paths := os.glob('$font_root_path/*.ttf') or { panic(err) }

	// c := w.canvas_layout('c')
	mut lb := w.listbox('lb')
	// dtw := ui.DrawTextWidget(c)
	for fp in font_paths {
		lb.add_item(fp, os.file_name(fp))
	}
	w.update_layout()
	// w.ui.add_style(
	// 	id: 'brush'
	// 	font_name: 'brush'
	// 	size: 24
	// )
	// dd.add_item('brush')
	// w.ui.add_style(
	// 	id: 'arial'
	// 	font_name: 'arial'
	// 	size: 30
	// 	color: gx.blue
	// )
	// dd.add_item('arial')
	// w.ui.add_style(
	// 	id: 'arial-bold'
	// 	font_name: 'arial-bold'
	// 	size: 30
	// 	color: gx.red
	// )
	// dd.add_item('arial-bold')
	// dtw.set_style('arial')
}

fn on_draw(c &ui.CanvasLayout, app &App) {
	mut dtw := ui.DrawTextWidget(c)
	dtw.load_style()
	c.draw_device_text(c.ui.gg, 10, 10, app.text)
	w, h := dtw.text_size(app.text)
	c.draw_rect_empty(10, 11, w + 2, h + 2, gx.black)
	c.draw_styled_text(10 + w + 10, 10, 'size: ($w, $h)')
}

fn lb_change(mut app App, lb &ui.ListBox) {
	mut w := lb.ui.window
	c := w.canvas_layout('c')
	mut dtw := ui.DrawTextWidget(c)
	fp, id := lb.selected() or { 'classic', '' }
	// println("$id, $fp")
	$if windows {
		w.ui.add_font(id, 'C:/windows/fonts/$fp')
	} $else {
		w.ui.add_font(id, fp)
	}

	app.prev_font = id
	dtw.update_style(font_name: id, size: 30)
}
