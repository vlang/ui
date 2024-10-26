import ui
import os

const win_width = 500
const win_height = 500
const picture_width_and_height = 100

@[heap]
struct App {
mut:
	window       &ui.Window = unsafe { nil }
	x_transition &ui.Transition
	y_transition &ui.Transition
	picture      &ui.Picture
	button       &ui.Button = unsafe { nil }
	state        int
}

fn main() {
	mut logo := os.resource_abs_path(os.join_path('../assets/img', 'logo.png'))
	$if android {
		logo = 'img/logo.png'
	}
	mut app := &App{
		x_transition: ui.transition(duration: 750, easing: ui.easing(.ease_in_out_cubic))
		y_transition: ui.transition(duration: 750, easing: ui.easing(.ease_in_out_quart))
		picture:      ui.picture(
			width:    picture_width_and_height
			height:   picture_width_and_height
			path:     logo
			movable:  true
			on_click: example_pic_click
		)
	}
	app.button = ui.button(text: 'Slide', on_click: app.btn_toggle_click, movable: true)
	app.window = ui.window(
		width:    win_width
		height:   win_height
		title:    'V UI Demo'
		mode:     .resizable
		children: [
			ui.column(
				widths:   ui.compact // or ui.compact
				margin:   ui.Margin{25, 25, 25, 25}
				children: [app.button, app.picture]
			),
			app.x_transition,
			app.y_transition,
		]
	)
	ui.run(app.window)
}

fn example_pic_click(pic &ui.Picture) {
	println('Clicked pic')
}

fn (mut app App) btn_toggle_click(button &ui.Button) {
	if app.x_transition.animated_value == 0 || app.y_transition.animated_value == 0 {
		app.x_transition.set_value(&app.picture.offset_x)
		app.y_transition.set_value(&app.picture.offset_y)
	}
	w, h := app.window.size()
	match app.state {
		0 {
			app.x_transition.target_value = 32
			app.y_transition.target_value = 32
			app.state = 1
		}
		1 {
			app.x_transition.target_value = w - (picture_width_and_height + 32)
			app.y_transition.target_value = h - (picture_width_and_height + 32)
			app.state = 2
		}
		2 {
			app.x_transition.target_value = w - (picture_width_and_height + 32)
			app.y_transition.target_value = 32
			app.state = 3
		}
		3 {
			app.x_transition.target_value = 32
			app.y_transition.target_value = h - (picture_width_and_height + 32)
			app.state = 4
		}
		4 {
			app.x_transition.target_value = w / 2 - (picture_width_and_height / 2)
			app.y_transition.target_value = h / 2 - (picture_width_and_height / 2)
			app.state = 0
		}
		else {
			app.state = 0
		}
	}
}
