module main

import ui
import gg
import gx
import os

const (
	win_width = 400
	win_height = 400
	picture_width_and_height = 158
)

struct App {
mut:
	picture_x_transition &ui.TransitionValue
	picture_y_transition &ui.TransitionValue
	state   int
	window  &ui.Window
}

fn main() {
	mut app := &App{
		state: 0
	}
	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'V UI Demo'
		user_ptr: app
	})
	mut picture := &ui.new_picture({
		x: win_width / 2 - (picture_width_and_height/2)
		y: win_height / 2 - (picture_width_and_height/2)
		parent: window
		width: picture_width_and_height
		height: picture_width_and_height
		path: os.resource_abs_path('logo.png')
	})
	ui.new_button({
		x: win_width / 2 - 28
		y: win_height - 32
		parent: window
		text: 'Slide'
		onclick: btn_toggle_click
	})
	app.picture_x_transition = ui.new_transition_value({
		duration: 750
		animated_value: &picture.x
		easing: ui.easing(.ease_in_out_cubic)
		parent: window
	})
	app.picture_y_transition = ui.new_transition_value({
		duration: 750
		animated_value: &picture.y
		easing: ui.easing(.ease_in_out_quart)
		parent: window
	})
	app.window = window
	ui.run(window)
}

fn btn_toggle_click(app mut App) {
	match (app.state) {
		0 {
			app.picture_x_transition.target_value = 32
			app.picture_y_transition.target_value = 32
			app.state = 1
		}
		1 {
			app.picture_x_transition.target_value = win_width - (picture_width_and_height + 32)
			app.picture_y_transition.target_value = win_height - (picture_width_and_height + 32)
			app.state = 2
		}
		2 {
			app.picture_x_transition.target_value = win_width - (picture_width_and_height + 32)
			app.picture_y_transition.target_value = 32
			app.state = 3
		}
		3 {
			app.picture_x_transition.target_value = 32
			app.picture_y_transition.target_value = win_height - (picture_width_and_height + 32)
			app.state = 4
		}
		4 {
			app.picture_x_transition.target_value = win_width / 2 - (picture_width_and_height / 2)
			app.picture_y_transition.target_value = win_height / 2 - (picture_width_and_height / 2)
			app.state = 0
		}
		else { app.state = 0 }
	}
}