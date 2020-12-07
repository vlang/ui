import ui

const (
	win_width  = 250
	win_height = 250
)

struct App {
mut:
	hor_slider  &ui.Slider
	vert_slider &ui.Slider
	window      &ui.Window
}

fn main() {
	mut app := &App{
		hor_slider: ui.slider(
			width: 200
			height: 20
			orientation: .horizontal
			max: 100
			val: 0
			on_value_changed: on_hor_value_changed
		)
		vert_slider: ui.slider(
			width: 20
			height: 200
			orientation: .vertical
			max: 100
			val: 0
			on_value_changed: on_vert_value_changed
		)
		window: 0
	}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Slider Example'
		state: app
	}, [
		ui.row({
			stretch: true
			alignment: .center
			margin: ui.MarginConfig{5, 5, 5, 5}
			spacing: 10
		}, [
			app.vert_slider,
			app.hor_slider,
		]),
	])
	ui.run(app.window)
}

fn on_hor_value_changed(mut app App, slider &ui.Slider) {
	app.hor_slider.val = app.hor_slider.val
}

fn on_vert_value_changed(mut app App, slider &ui.Slider) {
	app.vert_slider.val = app.vert_slider.val
}
