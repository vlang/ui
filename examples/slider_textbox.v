import ui

const win_width = 450
const win_height = 450
const vert_slider_min = -100
const vert_slider_max = -20
const vert_slider_val = (vert_slider_max + vert_slider_min) / 2
const hor_slider_min = -20
const hor_slider_max = 100
const hor_slider_val = (hor_slider_max + hor_slider_min) / 2

@[heap]
struct App {
mut:
	window       &ui.Window  = unsafe { nil }
	vert_slider  &ui.Slider  = unsafe { nil }
	vert_textbox &ui.TextBox = unsafe { nil }
	vert_text    string      = ((vert_slider_max + vert_slider_min) / 2).str()
	hor_slider   &ui.Slider  = unsafe { nil }
	hor_text     string      = ((hor_slider_max + hor_slider_min) / 2).str()
	hor_textbox  &ui.TextBox = unsafe { nil }
}

fn main() {
	mut app := &App{}
	app.hor_slider = ui.slider(
		width:               200
		height:              10
		orientation:         .horizontal
		min:                 hor_slider_min
		max:                 hor_slider_max
		val:                 hor_slider_val
		focus_on_thumb_only: true
		rev_min_max_pos:     true
		on_value_changed:    app.on_value_changed_hor
	)
	app.vert_slider = ui.slider(
		width:               10
		height:              200
		orientation:         .vertical
		min:                 vert_slider_min
		max:                 vert_slider_max
		val:                 vert_slider_val
		focus_on_thumb_only: true
		rev_min_max_pos:     true
		on_value_changed:    app.on_value_changed_vert
	)
	app.hor_textbox = ui.textbox(
		width:      40
		height:     20
		max_len:    20
		read_only:  false
		is_numeric: true
		on_char:    app.on_char_hor
	)
	app.vert_textbox = ui.textbox(
		width:      40
		height:     20
		max_len:    20
		read_only:  false
		is_numeric: true
		on_char:    app.on_char_vert
	)

	app.hor_textbox.text = &app.hor_text
	app.vert_textbox.text = &app.vert_text
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'Slider & textbox Example'
		children: [
			ui.column(
				heights:  [.1, .9]
				children: [
					ui.row(
						margin:   ui.Margin{50, 115, 30, 30}
						spacing:  100
						heights:  20.0
						children: [app.hor_textbox, app.vert_textbox]
					),
					ui.row(
						heights:  [ui.compact, ui.stretch]
						margin:   ui.Margin{100, 30, 30, 30}
						spacing:  30
						children: [app.hor_slider, app.vert_slider]
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn (mut app App) on_value_changed_hor(slider &ui.Slider) {
	app.hor_text = int(app.hor_slider.val).str()
	app.hor_textbox.border_accentuated = false
}

fn (mut app App) on_value_changed_vert(slider &ui.Slider) {
	app.vert_text = int(app.vert_slider.val).str()
	app.vert_textbox.border_accentuated = false
}

fn (mut app App) on_char_hor(textbox &ui.TextBox, keycode u32) {
	val := app.hor_text.int()
	min := app.hor_slider.min
	max := app.hor_slider.max
	if val >= min && val <= max {
		app.hor_slider.val = f32(val)
		app.hor_textbox.border_accentuated = false
	} else {
		app.hor_textbox.border_accentuated = true
	}
}

fn (mut app App) on_char_vert(textbox &ui.TextBox, keycode u32) {
	val := app.vert_text.int()
	min := app.vert_slider.min
	max := app.vert_slider.max
	if val >= min && val <= max {
		app.vert_slider.val = f32(val)
		app.vert_textbox.border_accentuated = false
	} else {
		app.vert_textbox.border_accentuated = true
	}
}
