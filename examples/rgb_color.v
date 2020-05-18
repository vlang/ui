import ui
import gx

const (
	win_width  = 220
	win_height = 380
	slider_min = 0
	slider_max = 255
	slider_val = (slider_max + slider_min) / 2
)

struct App {
mut:
	window        &ui.Window = 0
	r_slider      &ui.Slider
	r_textbox     &ui.TextBox
	r_label       &ui.Label
	g_slider      &ui.Slider
	g_textbox     &ui.TextBox
	g_label       &ui.Label
	b_slider      &ui.Slider
	b_textbox     &ui.TextBox
	b_label       &ui.Label
	rgb_rectangle &ui.Rectangle
	r_textbox_text string = slider_val.str()
	g_textbox_text string = slider_val.str()
	b_textbox_text string = slider_val.str()
}

fn main() {
	// widget config
	rgb_rectangle_cfg := ui.RectangleConfig{
		width: 200
		height: 100
		border: true
		color: gx.Color{
			r: slider_val
			g: slider_val
			b: slider_val
		}
	}
	r_textbox_cfg := ui.TextBoxConfig{
		width: 40
		height: 20
		max_len: 3
		read_only: false
		is_numeric: true
		on_key_up: on_r_key_up
	}	
	g_textbox_cfg := ui.TextBoxConfig{
		width: 40
		height: 20
		max_len: 3
		read_only: false
		is_numeric: true		
		on_key_up: on_g_key_up
	}	
	b_textbox_cfg := ui.TextBoxConfig{
		width: 40
		height: 20
		max_len: 3
		read_only: false
		is_numeric: true
		on_key_up: on_b_key_up
	}
	r_slider_cfg := ui.SliderConfig{
		width: 16
		height: 200
		orientation: .vertical
		min: slider_min
		max: slider_max
		val: slider_val
		focus_on_thumb_only: true
		rev_min_max_pos: true
		on_value_changed: on_r_value_changed
	}
	g_slider_cfg := ui.SliderConfig{
		width: 16
		height: 200
		orientation: .vertical
		min: slider_min
		max: slider_max
		val: slider_val
		focus_on_thumb_only: true
		rev_min_max_pos: true
		on_value_changed: on_g_value_changed
	}
	b_slider_cfg := ui.SliderConfig{
		width: 16
		height: 200
		orientation: .vertical
		min: slider_min
		max: slider_max
		val: slider_val
		focus_on_thumb_only: true
		rev_min_max_pos: true
		on_value_changed: on_b_value_changed
	}
	// row config
	textbox_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{120, 30, 30, 30}
		spacing: 23
	}
	slider_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{ 150, 40, 30, 30 }
		spacing: 38
	}
	rectangle_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{ 10, 10, 30, 30 }
	}
	label_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{ 354, 43, 30, 30 }
		spacing: 54
	}
	
	// app widgets
	mut app := &App{		
		rgb_rectangle: ui.rectangle(rgb_rectangle_cfg)
		r_textbox: ui.textbox(r_textbox_cfg)
		g_textbox: ui.textbox(g_textbox_cfg)
		b_textbox: ui.textbox(b_textbox_cfg)
		r_slider: ui.slider(r_slider_cfg)
		g_slider: ui.slider(g_slider_cfg)
		b_slider: ui.slider(b_slider_cfg)
		r_label: ui.label({ text: 'R' })
		g_label: ui.label({	text: 'G' })
		b_label: ui.label({ text: 'B' })
	}

	app.r_textbox.text = &app.r_textbox_text
	app.g_textbox.text = &app.g_textbox_text
	app.b_textbox.text = &app.b_textbox_text
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'RGB color displayed in rectangle'
		state: app
	}, [
		ui.row(textbox_row_cfg, [app.r_textbox, app.g_textbox, app.b_textbox]),
		ui.row(slider_row_cfg, [app.r_slider, app.g_slider, app.b_slider]),
		ui.row(rectangle_row_cfg, [app.rgb_rectangle]),
		ui.row(label_row_cfg, [app.r_label, app.g_label, app.b_label])
	])
	ui.run(app.window)
}

// on_.... functions
fn on_r_value_changed(mut app App, slider &ui.Slider) {	
	app.r_textbox_text = int(app.r_slider.val).str()
	app.r_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn on_g_value_changed(mut app App, slider &ui.Slider) {
	app.g_textbox_text = int(app.g_slider.val).str()
	app.g_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn on_b_value_changed(mut app App, slider &ui.Slider) {
	app.b_textbox_text = int(app.b_slider.val).str()
	app.b_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn on_r_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	if is_rgb_valid(app.r_textbox.text.int()) {
		//text_adr :=  app.r_textbox.text
		//text := *text_adr
		app.r_slider.val = app.r_textbox_text.f32()
		app.r_textbox.border_accentuated = false
	} else {
		app.r_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

fn on_g_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	if is_rgb_valid(app.g_textbox.text.int()) {
		//text_adr :=  app.g_textbox.text
		//text := *text_adr
		app.g_slider.val = app.g_textbox_text.f32()
		app.g_textbox.border_accentuated = false
	} else {
		app.g_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

fn on_b_key_up(mut app App, textbox &ui.TextBox, keycode u32) {
	if is_rgb_valid(app.b_textbox.text.int()) {
		//text_adr :=  app.b_textbox.text
		//text := *text_adr
		app.b_slider.val = app.b_textbox_text.f32()
		app.b_textbox.border_accentuated = false
	} else {
		app.b_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

// others functions
fn textbox_color_update(mut app App) {
	r := app.r_textbox.text.int()
	g := app.g_textbox.text.int()
	b := app.b_textbox.text.int()
	if !is_rgb_valid(r) || !is_rgb_valid(g) || !is_rgb_valid(b) {
		app.rgb_rectangle.color = gx.Color{ 255, 255, 255 }
		app.rgb_rectangle.text = 'RGB component(s) ERROR'
	} else {
		app.rgb_rectangle.color = gx.Color{ r, g, b }
		app.rgb_rectangle.text = ''
	}
}

fn is_rgb_valid(c int) bool {
	return if c >= 0 && c < 256 {
		true
	} else {
		false
	}
}
