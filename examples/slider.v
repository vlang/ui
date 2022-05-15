import ui

const (
	win_width  = 300
	win_height = 250
)

[heap]
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
			on_value_changed: app.on_hor_value_changed
		)
		vert_slider: ui.slider(
			width: 20
			height: 200
			orientation: .vertical
			max: 100
			val: 0
			on_value_changed: app.on_vert_value_changed
		)
		window: 0
	}
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Slider Example'
		state: app
		children: [
			ui.row(
				alignment: .center
				widths: [.1, .9]
				heights: [.9, .1]
				margin: ui.Margin{25, 25, 25, 25}
				spacing: 10
				children: [app.vert_slider, app.hor_slider]
			),
		]
	)
	ui.run(app.window)
}

fn (mut app App) on_hor_value_changed(slider &ui.Slider) {
	app.hor_slider.val = app.hor_slider.val
}

fn (mut app App) on_vert_value_changed(slider &ui.Slider) {
	app.vert_slider.val = app.vert_slider.val
}
