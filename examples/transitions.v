module main

import ui
import gg
import gx
import os

const (
	win_width = 700
	win_height = 385
)

struct App {
mut:
	picture_x_transition &ui.TransitionValue
	picture_y_transition &ui.TransitionValue
	toggled	bool
	window  &ui.Window
}

fn main() {
	mut app := &App{
		toggled: false
	}

	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'V UI Demo'
		user_ptr: app
	})

	mut picture := &ui.new_picture({
		x: win_width / 2 - 50
		y: win_height / 2 - 50
		parent: window
		width: 100
		height: 100
		path: os.resource_abs_path( 'logo.png' )
	})

	ui.new_button({
		x: win_width / 2 - 50
		y: win_height - 32
		parent: window
		text: 'Toggle Side'
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
	if app.toggled {
		app.picture_x_transition.target_value = 32
		app.picture_y_transition.target_value = 32
		app.toggled = false
	} else {
		app.picture_x_transition.target_value = win_width - 132
		app.picture_y_transition.target_value = win_height - 132
		app.toggled = true
	}
}