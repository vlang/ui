module main

import ui
import time

const (
	win_width = 287
	win_height = 155
)

struct App {
mut:
	lbl_elapsed_time &ui.Label
	lbl_elapsed_value &ui.Label
	lbl_duration &ui.Label
	progress_bar &ui.ProgressBar
	slider &ui.Slider
	reset_btn &ui.Button
	window     &ui.Window
	duration f32 = 25.0
	elapsed_time f32 = 0.0
}

fn main() {
	mut app := &App{}
	window := ui.new_window({
		width: win_width
		height: win_height
		title: 'Timer'
		user_ptr: app
	})
	
	app.lbl_elapsed_time = ui.new_label({
		x: 12
		y: 22
		text: 'Elapsed Time:'
		parent: window
	})

	app.progress_bar = ui.new_progress_bar({
		width: 170
		height: 23
		x: 100
		y: 18
		val: 0
		max: 100
		parent: window
	})

	app.lbl_elapsed_value = ui.new_label({
		x: 12
		y: 51
		text: '00.0s'
		parent: window
	})
	app.lbl_duration = ui.new_label({
		x: 12
		y: 80
		text: 'Duration:'
		parent: window
	})

	app.slider = ui.new_slider({
		x: 92
		y: 84
		width: 180
		height: 20
		orientation: .horizontal
		max: 50
		min: 0
		val: app.duration
		on_value_changed: on_value_changed
		parent: window
	})

	app.reset_btn = ui.new_button({
		x: 15
		y: 121
		width: 257
		height: 23
		text: 'Reset'
		onclick: on_reset
		parent: window
	})
	app.window = window
	go app.timer()
	ui.run(window)
}

fn on_value_changed(app mut App) {
	app.duration = app.slider.val
}

fn on_reset(app mut App) {
	app.elapsed_time = 0.0
}

fn (app mut App) timer() {
	for {
		if app.elapsed_time == app.duration {
			continue
		}
		if app.elapsed_time > app.duration {
			app.elapsed_time = app.duration
		} else {
			app.elapsed_time += 0.1
		}
		app.lbl_elapsed_value.set_text(app.elapsed_time.str() + "s")
		if app.duration == 0 {
			app.progress_bar.val = 100
		} else {
			app.progress_bar.val = int(app.elapsed_time * 100.0 / app.duration)
		}
		time.usleep(100000)
	}
}