import ui
import os
import gx
import gg
import sokol
import sokol.sapp

const (
	win_width                = 400
	win_height               = 400
	picture_width_and_height = 100
)

struct App {
mut:
	window       &ui.Window
	picture      &ui.Picture
	button       &ui.Button
	state        int
}

fn main() {	
		mut app := &App{
		state: 0
		window: 0
		picture: ui.picture(
			width: picture_width_and_height
			height: picture_width_and_height
			path: os.resource_abs_path('logo.png')
			on_click: example_pic_click
		)
		button: ui.button(
			text: 'Button', 
			onclick: btn_toggle_click, 
			onhover: btn_hoverer,
			height:50,
			width:20,
			color:gx.red)
			
	}	
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'V UI Demo'
		state: app
	}, [ui.column({
		stretch: true
		margin: ui.MarginConfig{5, 5, 5, 5}
	}, [app.button,app.button,
		app.picture,
		])
	])
	ui.run(app.window)	
}

fn example_pic_click(mut app App, pic &ui.Picture) {
	println('Clicked pic')	
	ui.set_cursor(int(ui.Cursor.hand))
	app.button.color=gx.green
}
fn btn_hoverer(mut app App, mut button &ui.Button) {
	app.button.color=gx.yellow
	app.button.cursor=.hand
}
fn btn_toggle_click(mut app App, mut button &ui.Button) {
	app.button.color=gx.green	
}
