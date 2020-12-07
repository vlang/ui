import ui
import os

const (
	win_width                = 400
	win_height               = 400
	picture_width_and_height = 100
)

struct App {
mut:
	window       &ui.Window
	x_transition &ui.Transition
	y_transition &ui.Transition
	picture      &ui.Picture
	button       &ui.Button
	state        int
}

fn main() {
	mut app := &App{
		state: 0
		window: 0
		x_transition: ui.transition(duration: 750, easing: ui.easing(.ease_in_out_cubic))
		y_transition: ui.transition(duration: 750, easing: ui.easing(.ease_in_out_quart))
		picture: ui.picture(
			width: picture_width_and_height
			height: picture_width_and_height
			path: os.resource_abs_path('logo.png')
			on_click: example_pic_click
		)
		button: ui.button(text: 'Slide', onclick: btn_toggle_click)
	}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'V UI Demo'
		state: app
	}, [ui.column({
		stretch: true
		margin: ui.MarginConfig{5, 5, 5, 5}
	}, [app.button, app.picture, app.x_transition, app.y_transition])])
	ui.run(app.window)
}

fn example_pic_click(mut app App, pic &ui.Picture) {
	println('Clicked pic')
}

fn btn_toggle_click(mut app App, button &ui.Button) {
	if app.x_transition.animated_value == 0 || app.y_transition.animated_value == 0 {
		app.x_transition.set_value(&app.picture.offset_x)
		app.y_transition.set_value(&app.picture.offset_y)
	}
	match (app.state) {
		0 {
			app.x_transition.target_value = 32
			app.y_transition.target_value = 32
			app.state = 1
		}
		1 {
			app.x_transition.target_value = win_width - (picture_width_and_height + 32)
			app.y_transition.target_value = win_height - (picture_width_and_height + 32)
			app.state = 2
		}
		2 {
			app.x_transition.target_value = win_width - (picture_width_and_height + 32)
			app.y_transition.target_value = 32
			app.state = 3
		}
		3 {
			app.x_transition.target_value = 32
			app.y_transition.target_value = win_height - (picture_width_and_height + 32)
			app.state = 4
		}
		4 {
			app.x_transition.target_value = win_width / 2 - (picture_width_and_height / 2)
			app.y_transition.target_value = win_height / 2 - (picture_width_and_height / 2)
			app.state = 0
		}
		else {
			app.state = 0
		}
	}
}
