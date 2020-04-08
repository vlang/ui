import ui

const (
	win_width = 250
	win_height = 250
)

struct App {
mut:
	hor_slider  ui.Slider
	vert_slider ui.Slider
	window      &ui.Window
}

fn main() {
	mut app := &App{}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'Slider Example'
		user_ptr: app
	}, [ui.iwidget(ui.row({
		stretch: true
		alignment: .center
		margin: ui.MarginConfig{
			5,5,5,5}
		spacing: 10
	}, [ui.iwidget(ui.slider({
		width: 20
		height: 200
		orientation: .vertical
		max: 100
		val: 0
		on_value_changed: on_vert_value_changed
		ref: &app.vert_slider
	})),
	ui.slider({
		width: 200
		height: 20
		orientation: .horizontal
		max: 100
		val: 0
		on_value_changed: on_hor_value_changed
		ref: &app.hor_slider
	})]))])
	app.window = window
	ui.run(window)
}

fn on_hor_value_changed(app mut App) {
	app.vert_slider.val = app.hor_slider.val
}

fn on_vert_value_changed(app mut App) {
	app.hor_slider.val = app.vert_slider.val
}
