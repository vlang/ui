import ui
import gx
import math

struct Circle {
	x      f32
	y      f32
	radius f32
}

struct Circles {
mut:
	last    int
	hover   int
	circles []Circle
}

fn (mut c Circles) add(x f64, y f64, radius f64) {
	c.circles << Circle{f32(x), f32(y), f32(radius)}
}

struct App {
mut:
	circles Circles
}

fn main() {
	app := &App{}
	window := ui.window(
		width: 500
		height: 400
		title: 'Circle drawer'
		mode: .resizable
		state: app
		children: [
			ui.column(
				spacing: 10
				margin_: 20
				widths: ui.stretch
				heights: [ui.compact, ui.stretch]
				children: [
					ui.row(
						spacing: 20
						widths: [ui.stretch, 40, 40, ui.stretch]
						children: [ui.spacing(),
							ui.button(id: 'btn_undo', text: 'Undo', radius: 5, onclick: click_undo),
							ui.button(id: 'btn_redo', text: 'Redo', radius: 5, onclick: click_redo),
							ui.spacing()]
					),
					ui.canvas_plus(
						bg_color: gx.white
						bg_radius: .025
						on_draw: draw_circles
						on_click: click_circles
						on_mouse_move: mouse_move_circles
					),
				]
			),
		]
	)
	ui.run(window)
}

fn draw_circles(d ui.DrawDevice, c &ui.CanvasLayout, app &App) {
	for i, circle in app.circles.circles[..app.circles.last] {
		if i == app.circles.hover {
			c.draw_device_circle_filled(d, circle.x, circle.y, circle.radius, gx.light_gray)
		}
		c.draw_device_circle_empty(d, circle.x, circle.y, circle.radius, gx.black)
	}
}

fn click_circles(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut app := &App(c.ui.window.state)
	println('click $e.x $e.y nb pts = $app.circles.circles.len')
	app.circles.circles.trim(app.circles.last)
	app.circles.add(e.x, e.y, 20)
	app.circles.last += 1
	mut btn_redo := c.ui.window.button('btn_redo')
	btn_redo.disabled = true
}

fn mouse_move_circles(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	mut app := &App(c.ui.window.state)
	// println("move $e.x $e.y nb pts = $app.circles.circles.len")
	app.circles.hover = -1
	for i, circle in app.circles.circles[..app.circles.last] {
		if math.pow((circle.x - e.x), 2) + math.pow((circle.y - e.y), 2) <= math.pow(circle.radius,
			2) {
			app.circles.hover = i
			break
		}
	}
}

fn click_undo(mut a App, b &ui.Button) {
	if a.circles.last > 0 {
		a.circles.last -= 1
	}
	mut btn_redo := b.ui.window.button('btn_redo')
	btn_redo.disabled = false
}

fn click_redo(mut a App, b &ui.Button) {
	if a.circles.last < a.circles.circles.len - 1 {
		a.circles.last += 1
	}
}
