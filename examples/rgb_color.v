// Color struct in \vlib\gx.v needs to be mutable


import (
	ui
	gx
)

const (
	win_width = 220
	win_height = 380
)

struct App {
mut:
	window        &ui.Window
	r_slider      ui.Slider
	r_textbox     ui.TextBox
	r_label       ui.Label
	g_slider      ui.Slider
	g_textbox     ui.TextBox
	g_label       ui.Label
	b_slider      ui.Slider
	b_textbox     ui.TextBox
	b_label       ui.Label
	rgb_rectangle ui.Rectangle
}

fn main() {
	mut app := &App{
		window: 0
	}
	// window cfg
	win_cfg := ui.WindowConfig{
		width: win_width
		height: win_height
		title: 'RGB color displayed in rectangle'
		user_ptr: app
	}
	slider_val := 127
	// row cfg
	rectangle_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{
			10,10,30,30}
	}
	slider_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{
			150,40,30,30}
		spacing: 38
	}
	textbox_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{
			120,30,30,30}
		spacing: 23
	}
	label_row_cfg := ui.RowConfig{
		alignment: .top
		margin: ui.MarginConfig{
			354,43,30,30}
		spacing: 54
	}
	// rectangle cfg
	rgb_rectangle_cfg := ui.RectangleConfig{
		width: 200
		height: 100
		border: true
		color: gx.Color {
			r: slider_val
			g: slider_val
			b: slider_val
		}
		ref: &app.rgb_rectangle
	}
	// textboxes cfg
	r_textbox_cfg := ui.TextBoxConfig{
		width: 40
		height: 20
		max_len: 3
		read_only: false
		is_numeric: true
		text: slider_val.str()
		ref: &app.r_textbox
		on_key_up: on_r_key_up
	}
	g_textbox_cfg := ui.TextBoxConfig{
		width: 40
		height: 20
		max_len: 3
		read_only: false
		is_numeric: true
		text: slider_val.str()
		ref: &app.g_textbox
		on_key_up: on_g_key_up
	}
	b_textbox_cfg := ui.TextBoxConfig{
		width: 40
		height: 20
		max_len: 3
		read_only: false
		is_numeric: true
		text: slider_val.str()
		ref: &app.b_textbox
		on_key_up: on_b_key_up
	}
	// sliders cfg
	slider_min := 0
	slider_max := 255
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
		ref: &app.r_slider
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
		ref: &app.g_slider
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
		ref: &app.b_slider
	}
	// labels cfg
	r_label_cfg := ui.LabelConfig{
		text: 'R'
		ref: 0
	}
	g_label_cfg := ui.LabelConfig{
		text: 'G'
		ref: 0
	}
	b_label_cfg := ui.LabelConfig{
		text: 'B'
		ref: 0
	}
	// UI window
	window := ui.window(win_cfg, [ui.iwidget(ui.row(textbox_row_cfg, [ui.iwidget(ui.textbox(r_textbox_cfg)),
	ui.iwidget(ui.textbox(g_textbox_cfg)),
	ui.iwidget(ui.textbox(b_textbox_cfg))])),
	ui.iwidget(ui.row(slider_row_cfg, [ui.iwidget(ui.slider(r_slider_cfg)),
	ui.iwidget(ui.slider(g_slider_cfg)),
	ui.iwidget(ui.slider(b_slider_cfg))])),
	ui.iwidget(ui.row(rectangle_row_cfg, [ui.iwidget(ui.rectangle(rgb_rectangle_cfg))])),
	ui.iwidget(ui.row(label_row_cfg, [ui.iwidget(ui.label(r_label_cfg)),
	ui.iwidget(ui.label(g_label_cfg)),
	ui.iwidget(ui.label(b_label_cfg))])),
	])
	app.window = window
	ui.run(window)
}

// on_.... functions
fn on_r_value_changed(app mut App) {
	app.r_textbox.text = int(app.r_slider.val).str()
	app.r_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn on_g_value_changed(app mut App) {
	app.g_textbox.text = int(app.g_slider.val).str()
	app.g_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn on_b_value_changed(app mut App) {
	app.b_textbox.text = int(app.b_slider.val).str()
	app.b_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn on_r_key_up(app mut App) {
	if is_rgb_valid(app.r_textbox.text.int()) {
		app.r_slider.val = app.r_textbox.text.f32()
		app.r_textbox.border_accentuated = false
	}
	else {
		app.r_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

fn on_g_key_up(app mut App) {
	if is_rgb_valid(app.g_textbox.text.int()) {
		app.g_slider.val = app.g_textbox.text.f32()
		app.g_textbox.border_accentuated = false
	}
	else {
		app.g_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

fn on_b_key_up(app mut App) {
	if is_rgb_valid(app.b_textbox.text.int()) {
		app.b_slider.val = app.b_textbox.text.f32()
		app.b_textbox.border_accentuated = false
	}
	else {
		app.b_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

// others functions
fn textbox_color_update(app mut App) {
	r := app.r_textbox.text.int()
	g := app.g_textbox.text.int()
	b := app.b_textbox.text.int()
	if !is_rgb_valid(r) || !is_rgb_valid(g) || !is_rgb_valid(b) {
		app.rgb_rectangle.color = gx.Color {
			255,255,255}
		app.rgb_rectangle.text = 'RGB component(s) ERROR'
	}
	else {
		app.rgb_rectangle.color = gx.Color {
			r,g,b}
		app.rgb_rectangle.text = ''
	}
}

fn is_rgb_valid(c int) bool {
	return if c >= 0 && c < 256 { true } else { false }
}
