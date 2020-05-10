import ui

const (
	win_width       = 650
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
	hor_slider   &ui.Slider
	hor_textbox  &ui.TextBox
}

fn main() {
	mut app := &App{
		window: 0
		hor_textbox: ui.textbox(
			width: 40
			height: 20
			max_len: 20
			read_only: false
			is_numeric: true
			text: hor_slider_val.str()
			on_key_up: on_hor_key_up
		)
		vert_textbox: ui.textbox(
			width: 40
			height: 20
			max_len: 20
			read_only: false
			is_numeric: true
			text: vert_slider_val.str()
			on_key_up: on_vert_key_up
		)
		hor_slider: ui.slider(
			width: 200
			height: 10
			orientation: .horizontal
			min: hor_slider_min
			max: hor_slider_max
			val: hor_slider_val
			focus_on_thumb_only: true
			rev_min_max_pos: true
			on_value_changed: on_hor_value_changed
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
			on_value_changed: on_vert_value_changed
		)
	}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Slider & textbox Example'
		user_ptr: app
	}, [
		ui.row({
			alignment: .top
			margin: ui.MarginConfig{50,115,30,30}
			spacing: 100
		}, [
			app.hor_textbox,
			app.vert_textbox
		]),
		ui.row({
			alignment: .top
			margin: ui.MarginConfig{100,30,30,30}
			spacing: 30
		}, [
			app.hor_slider,
			app.vert_slider
		])
	])
	ui.run(app.window)
}

fn on_hor_value_changed(mut app App, slider &ui.Slider) {
	app.hor_textbox.text = int(app.hor_slider.val).str()
	app.hor_textbox.border_accentuated = false
}

fn on_vert_value_changed(mut app App, slider &ui.Slider) {
	app.vert_textbox.text = int(app.vert_slider.val).str()
	app.vert_textbox.border_accentuated = false
}

fn on_hor_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	val := app.hor_textbox.text.int()
	min := app.hor_slider.min
	max := app.hor_slider.max
	if val >= min && val <= max {
		app.hor_slider.val = f32(val)
		app.hor_textbox.border_accentuated = false
	} else {
		app.hor_textbox.border_accentuated = true
	}
}

fn on_vert_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	val := app.vert_textbox.text.int()
	min := app.vert_slider.min
	max := app.vert_slider.max
	if val >= min && val <= max {
		app.vert_slider.val = f32(val)
		app.vert_textbox.border_accentuated = false
	} else {
		app.vert_textbox.border_accentuated = true
	}
}
