import ui
import time

const (
	win_width = 287
	win_height = 110
)

struct App {
mut:
	lbl_elapsed_value ui.Label
	progress_bar ui.ProgressBar
	slider ui.Slider
	window     &ui.Window
	duration f32 = 25.0
	elapsed_time f32 = 0.0
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Timer'
		user_ptr: app
	}, [
		ui.IWidgeter(ui.column({
			stretch: true
			margin: ui.MarginConfig{5,5,5,5}
			alignment: .left
		}, [
		ui.IWidgeter(ui.row({
			alignment: .top
			spacing: 10
		}, [
			ui.IWidgeter(ui.column({
				alignment: .left
				spacing: 10
			}, [
				ui.IWidgeter(ui.label({
					text: 'Elapsed Time:'
				})),
				ui.label({
					text: 'Duration:'
				}),
				ui.button({
					text: 'Reset'
					onclick: on_reset
				})
			])),
			ui.column({
				alignment: .left
				spacing: 10
			}, [
				ui.IWidgeter(ui.label({
					text: '00.0s'
					ref:  &app.lbl_elapsed_value
				})),
				ui.slider({
					width: 180
					height: 20
					orientation: .horizontal
					max: 50
					min: 0
					val: app.duration
					on_value_changed: on_value_changed
					ref: &app.slider
				})
			])
		])),
			ui.progressbar({
				height: 20
				val: 0
				max: 100
				ref: &app.progress_bar
			})
		]))
	])
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