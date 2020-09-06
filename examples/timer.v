import ui
import time

const (
	win_width  = 287
	win_height = 110
)

struct App {
mut:
	lbl_elapsed_value &ui.Label
	progress_bar      &ui.ProgressBar
	slider            &ui.Slider
	window            &ui.Window
	duration          f64 = 25.0
	elapsed_time      f64 = 0.0
}

fn main() {
	mut app := &App{
		slider: ui.slider({
			width: 180
			height: 20
			orientation: .horizontal
			max: 50
			min: 0
			val: 25.0
			on_value_changed: on_value_changed
		})
		lbl_elapsed_value: ui.label({
			text: '00.0s'
		})
		progress_bar: ui.progressbar({
			height: 20
			val: 0
			max: 100
		})
		window: 0
	}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Timer'
		state: app
	}, [
		ui.column({
			stretch: true
			margin: ui.MarginConfig{5, 5, 5, 5}
			alignment: .left
		}, [
			ui.row({
				alignment: .top
				spacing: 10
			}, [
				ui.column({
					alignment: .left
					spacing: 10
				}, [
					ui.label({
						text: 'Elapsed Time:'
					}),
					ui.label({
						text: 'Duration:'
					}),
					ui.button({
						text: 'Reset'
						onclick: on_reset
					}),
				]),
				ui.column({
					alignment: .left
					spacing: 10
				}, [
					app.lbl_elapsed_value,
					app.slider,
				]),
			]),
			app.progress_bar,
		]),
	])
	app.window = window
	go app.timer()
	ui.run(window)
}

fn on_value_changed(mut app App, slider &ui.Slider) {
	app.duration = app.slider.val
}

fn on_reset(mut app App, button &ui.Button) {
	app.elapsed_time = 0.0
}

fn (mut app App) timer() {
	for {
		if app.elapsed_time == app.duration {
			continue
		}
		if app.elapsed_time > app.duration {
			app.elapsed_time = app.duration
		} else {
			app.elapsed_time += 0.1
		}
		app.lbl_elapsed_value.set_text('$app.elapsed_time s')
		if app.duration == 0 {
			app.progress_bar.val = 100
		} else {
			app.progress_bar.val = int(app.elapsed_time * 100.0 / app.duration)
		}
		time.usleep(100000)
	}
}
