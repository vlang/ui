import ui

const (
	win_width       = 450
	win_height      = 450
	vert_slider_min = -100
	vert_slider_max = -20
	vert_slider_val = (vert_slider_max + vert_slider_min) / 2
	hor_slider_min  = -20
	hor_slider_max  = 100
	hor_slider_val  = (hor_slider_max + hor_slider_min) / 2
)

struct App {
mut:
	window       &ui.Window
	vert_slider  &ui.Slider
	vert_textbox &ui.TextBox
	vert_text    string = ((vert_slider_max + vert_slider_min) / 2).str()
	hor_slider   &ui.Slider
	hor_text     string = ((hor_slider_max + hor_slider_min) / 2).str()
	hor_textbox  &ui.TextBox
}

fn main() {
	mut app := &App{
		window: 0
		hor_slider: ui.slider(
			width: 200
			height: 10
			orientation: .horizontal
			min: hor_slider_min
			max: hor_slider_max
			val: hor_slider_val
			focus_on_thumb_only: true
			rev_min_max_pos: true
			on_value_changed: on_value_changed_hor
		)
		vert_slider: ui.slider(
			width: 10
			height: 200
			orientation: .vertical
			min: vert_slider_min
			max: vert_slider_max
			val: vert_slider_val
			focus_on_thumb_only: true
			rev_min_max_pos: true
			on_value_changed: on_value_changed_vert
		)
		hor_textbox: ui.textbox(
			width: 40
			height: 20
			max_len: 20
			read_only: false
			is_numeric: true
			text: -1
			on_char: on_char_hor
		)
		vert_textbox: ui.textbox(
			width: 40
			height: 20
			max_len: 20
			read_only: false
			is_numeric: true
			text: -1
			on_char: on_char_vert
		)
	}
	app.hor_textbox.text = &app.hor_text
	app.vert_textbox.text = &app.vert_text
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Slider & textbox Example'
		state: app
	}, [
		ui.column({
			heights: [.1, .9]
		}, [ui.row({
			margin: ui.Margin{50, 115, 30, 30}
			spacing: 100
			heights: 20.
		}, [app.hor_textbox, app.vert_textbox]), ui.row({
			margin: ui.Margin{100, 30, 30, 30}
			spacing: 30
		}, [app.hor_slider, app.vert_slider])]),
	])
	ui.run(app.window)
}

fn on_value_changed_hor(mut app App, slider &ui.Slider) {
	app.hor_text = int(app.hor_slider.val).str()
	app.hor_textbox.border_accentuated = false
}

fn on_value_changed_vert(mut app App, slider &ui.Slider) {
	app.vert_text = int(app.vert_slider.val).str()
	app.vert_textbox.border_accentuated = false
}

fn on_char_hor(mut app App, textbox &ui.TextBox, keycode u32) {
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

fn on_char_vert(mut app App, textbox &ui.TextBox, keycode u32) {
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
