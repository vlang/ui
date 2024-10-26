import ui
import gx

const win_width = 200
const win_height = 400
const slider_min = 0
const slider_max = 255
const slider_val = (slider_max + slider_min) / 2

@[heap]
struct App {
mut:
	window         &ui.Window    = unsafe { nil }
	r_slider       &ui.Slider    = unsafe { nil }
	r_textbox      &ui.TextBox   = unsafe { nil }
	r_label        &ui.Label     = unsafe { nil }
	g_slider       &ui.Slider    = unsafe { nil }
	g_textbox      &ui.TextBox   = unsafe { nil }
	g_label        &ui.Label     = unsafe { nil }
	b_slider       &ui.Slider    = unsafe { nil }
	b_textbox      &ui.TextBox   = unsafe { nil }
	b_label        &ui.Label     = unsafe { nil }
	rgb_rectangle  &ui.Rectangle = unsafe { nil }
	r_textbox_text string        = slider_val.str()
	g_textbox_text string        = slider_val.str()
	b_textbox_text string        = slider_val.str()
}

fn main() {
	mut entering := false
	$if sync ? {
		entering = true
	}
	mut app := &App{}
	app.rgb_rectangle = ui.rectangle(
		id:     'rgb_rect'
		border: true
		color:  gx.Color{
			r: slider_val
			g: slider_val
			b: slider_val
		}
	)
	app.r_textbox = ui.textbox(
		max_len:    3
		read_only:  false
		is_numeric: true
		on_char:    app.on_r_char
	)
	app.g_textbox = ui.textbox(
		max_len:    3
		read_only:  false
		is_numeric: true
		on_char:    app.on_g_char
	)
	app.b_textbox = ui.textbox(
		max_len:    3
		read_only:  false
		is_numeric: true
		on_char:    app.on_b_char
	)
	app.r_slider = ui.slider(
		orientation:         .vertical
		min:                 slider_min
		max:                 slider_max
		val:                 slider_val
		focus_on_thumb_only: true
		rev_min_max_pos:     true
		on_value_changed:    app.on_r_value_changed
		entering:            entering
		thumb_color:         gx.light_red
	)
	app.g_slider = ui.slider(
		orientation:         .vertical
		min:                 slider_min
		max:                 slider_max
		val:                 slider_val
		focus_on_thumb_only: true
		rev_min_max_pos:     true
		on_value_changed:    app.on_g_value_changed
		entering:            entering
		thumb_color:         gx.light_green
	)
	app.b_slider = ui.slider(
		orientation:         .vertical
		min:                 slider_min
		max:                 slider_max
		val:                 slider_val
		focus_on_thumb_only: true
		rev_min_max_pos:     true
		on_value_changed:    app.on_b_value_changed
		entering:            entering
		thumb_color:         gx.light_blue
	)
	app.r_label = ui.label(text: 'R', justify: ui.top_center, width: 40)
	app.g_label = ui.label(text: 'G', justify: ui.top_center, width: 40)
	app.b_label = ui.label(text: 'B', justify: ui.top_center, width: 40)
	app.r_textbox.text = &app.r_textbox_text
	app.g_textbox.text = &app.g_textbox_text
	app.b_textbox.text = &app.b_textbox_text
	w := [ui.stretch, 40.0, 2 * ui.stretch, 40, 2 * ui.stretch, 40, ui.stretch]
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'RGB color displayed in rectangle'
		mode:     .resizable
		children: [
			ui.column(
				margin_:    10
				spacing:    5
				alignments: ui.HorizontalAlignments{
					center: [0, 1, 2, 3]
				}
				heights:    [ui.stretch, 2 * ui.stretch, ui.stretch, 5 * ui.stretch, ui.stretch]
				children:   [
					ui.button(
						id:       'rgb_btn'
						text:     'Show rgb color'
						on_click: app.btn_click
					),
					app.rgb_rectangle,
					ui.row(
						id:       'row_tb'
						widths:   w
						children: [ui.spacing(), app.r_textbox, ui.spacing(), app.g_textbox,
							ui.spacing(), app.b_textbox, ui.spacing()]
					),
					ui.row(
						widths:   w
						children: [ui.spacing(), app.r_slider, ui.spacing(), app.g_slider,
							ui.spacing(), app.b_slider, ui.spacing()]
					),
					ui.row(
						widths:   w
						children: [ui.spacing(), app.r_label, ui.spacing(), app.g_label,
							ui.spacing(), app.b_label, ui.spacing()]
					),
				]
			),
		]
	)
	ui.run(app.window)
}

fn (app &App) btn_click(b &ui.Button) {
	txt := 'gx.rgb(${app.r_textbox_text},${app.g_textbox_text},${app.b_textbox_text})'
	ui.message_box(txt)
}

fn (mut app App) on_r_value_changed(slider &ui.Slider) {
	app.r_textbox_text = int(app.r_slider.val).str()
	app.r_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn (mut app App) on_g_value_changed(slider &ui.Slider) {
	app.g_textbox_text = int(app.g_slider.val).str()
	app.g_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn (mut app App) on_b_value_changed(slider &ui.Slider) {
	app.b_textbox_text = int(app.b_slider.val).str()
	app.b_textbox.border_accentuated = false
	textbox_color_update(mut app)
}

fn (mut app App) on_r_char(textbox &ui.TextBox, keycode u32) {
	if ui.is_rgb_valid(app.r_textbox.text.int()) {
		app.r_slider.val = app.r_textbox_text.f32()
		app.r_textbox.border_accentuated = false
	} else {
		app.r_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

fn (mut app App) on_g_char(textbox &ui.TextBox, keycode u32) {
	if ui.is_rgb_valid(app.g_textbox.text.int()) {
		app.g_slider.val = app.g_textbox_text.f32()
		app.g_textbox.border_accentuated = false
	} else {
		app.g_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

fn (mut app App) on_b_char(textbox &ui.TextBox, keycode u32) {
	if ui.is_rgb_valid(app.b_textbox.text.int()) {
		app.b_slider.val = app.b_textbox_text.f32()
		app.b_textbox.border_accentuated = false
	} else {
		app.b_textbox.border_accentuated = true
	}
	textbox_color_update(mut app)
}

// others functions
fn textbox_color_update(mut app App) {
	r := u8(app.r_textbox.text.int())
	g := u8(app.g_textbox.text.int())
	b := u8(app.b_textbox.text.int())
	if !ui.is_rgb_valid(r) || !ui.is_rgb_valid(g) || !ui.is_rgb_valid(b) {
		app.rgb_rectangle.style.color = gx.rgb(255, 255, 255)
		app.rgb_rectangle.text = 'RGB component(s) ERROR'
	} else {
		app.rgb_rectangle.style.color = gx.rgb(r, g, b)
		app.rgb_rectangle.text = ''
	}
}
