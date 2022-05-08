import ui
import gx
import math

struct Circle {
	x f32
	y f32
mut:
	radius f32
}

fn (c Circle) contains(x f32, y f32) bool {
	return math.pow((c.x - x), 2) + math.pow((c.y - y), 2) <= math.pow(c.radius, 2)
}

struct Circles {
mut:
	last    int
	hover   int
	circles []Circle
}

struct State {
mut:
	circles        []Circle
	current_action int = -1
	history        []Action
}

fn (mut state State) add_action(action Action) {
	state.history << action
	state.current_action += 1
}

fn (mut state State) undo() {
	if state.current_action >= 0 {
		state.history[state.current_action].undo(mut state)
		state.current_action -= 1
	}
}

fn (mut state State) redo() {
	if state.current_action < state.history.len - 1 {
		state.current_action += 1
		state.history[state.current_action].do(mut state)
	}
}

interface Action {
	do(mut state State)
	undo(mut state State)
}

struct ActionAddCircle {
	circle Circle
}

fn (a ActionAddCircle) do(mut state State) {
	state.circles << a.circle
}

fn (a ActionAddCircle) undo(mut state State) {
	if state.circles.len > 0 {
		state.circles.delete_last()
	} else {
		println('Warning: no circle to delete')
	}
}

struct ActionSetCircleRadius {
	circle_index int
	new_radius   f32
	old_radius   f32
}

fn (a ActionSetCircleRadius) do(mut state State) {
	state.circles[a.circle_index].radius = a.new_radius
}

fn (a ActionSetCircleRadius) undo(mut state State) {
	state.circles[a.circle_index].radius = a.old_radius
}

struct App {
mut:
	hover int
	state State
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
	for i, circle in app.state.circles {
		if i == app.hover {
			c.draw_device_circle_filled(d, circle.x, circle.y, circle.radius, gx.light_gray)
		}
		c.draw_device_circle_empty(d, circle.x, circle.y, circle.radius, gx.black)
	}
}

fn click_circles(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut app := &App(c.ui.window.state)
	// println("click $e.x $e.y nb pts = $app.state.circles.len")
	radius := 20
	circle := Circle{f32(e.x), f32(e.y), f32(radius)}
	action := ActionAddCircle{circle}
	app.state.add_action(action)
	action.do(mut app.state)
	// mut btn_redo := c.ui.window.button("btn_redo")
	// btn_redo.disabled = true
}

fn mouse_move_circles(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	mut app := &App(c.ui.window.state)
	// println("move $e.x $e.y nb pts = $app.circles.circles.len")
	app.hover = -1
	for i, circle in app.state.circles {
		if circle.contains(f32(e.x), f32(e.y)) {
			app.hover = i
			break
		}
	}
}

fn click_undo(mut a App, b &ui.Button) {
	a.state.undo()

	// mut btn_redo := b.ui.window.button("btn_redo")
	// btn_redo.disabled = false
}

fn click_redo(mut a App, b &ui.Button) {
	a.state.redo()
	// if a.circles.last <  a.circles.circles.len - 1 {
	// 	a.circles.last += 1
	// }
}
