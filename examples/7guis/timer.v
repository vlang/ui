import ui
import time
import math
import gx

const (
	win_width  = 287
	win_height = 155
	duration   = 1 // ms
	left       = 60.0
)

[heap]
struct App {
mut:
	lbl_elapsed_value &ui.Label
	progress_bar      &ui.ProgressBar
	slider            &ui.Slider = unsafe { nil }
	window            &ui.Window
	duration          f64 = 15.0
	elapsed_time      f64 = 0.0
}

fn main() {
	mut app := &App{
		lbl_elapsed_value: ui.label(text: '00.0s', text_size: 1.0 / 10)
		progress_bar: ui.progressbar(
			height: 20
			val: 0
			max: 100
			color: gx.green
			border_color: gx.dark_green
		)
		window: 0
	}
	app.slider = ui.slider(
		width: 180
		height: 20
		orientation: .horizontal
		max: 30
		min: 0
		val: 15.0
		on_value_changed: app.on_value_changed
	)
	window := ui.window(
		width: win_width
		height: win_height
		title: 'Timer'
		mode: .resizable
		layout: ui.column(
			margin_: .05
			spacing: .05
			children: [
				ui.row(
					spacing: .1
					widths: [left, ui.stretch]
					children: [ui.label(text: 'Elapsed Time:', text_size: 1.0 / 10), app.progress_bar]
				),
				ui.row(
					spacing: .1
					widths: [left, ui.stretch]
					children: [ui.spacing(), app.lbl_elapsed_value]
				),
				ui.row(
					spacing: .1
					widths: [left, ui.stretch]
					children: [ui.label(text: 'Duration:', text_size: 1.0 / 10), app.slider]
				),
				ui.button(text: 'Reset', on_click: app.on_reset),
			]
		)
	)
	app.window = window

	// go app.timer()
	ui.run(window)
}

fn (mut app App) on_value_changed(slider &ui.Slider) {
	app.duration = app.slider.val
}

fn (mut app App) on_reset(button &ui.Button) {
	app.elapsed_time = 0.0
	spawn app.timer()
}

fn (mut app App) timer() {
	for {
		if app.elapsed_time == app.duration {
			break
		}
		if app.elapsed_time > app.duration {
			app.elapsed_time = app.duration
		} else {
			app.elapsed_time += 0.1 * duration
		}
		app.lbl_elapsed_value.set_text('${math.ceil(app.elapsed_time * 100) / 100}s')
		if app.duration == 0 {
			app.progress_bar.val = 100
		} else {
			app.progress_bar.val = int(app.elapsed_time * 100.0 / app.duration)
		}
		time.sleep(100000 * duration * time.microsecond)
		app.window.refresh()
	}
}
