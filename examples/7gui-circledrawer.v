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

fn (mut state State) reset_history() {
	state.history.delete_many(state.current_action, state.history.len - state.current_action - 1)
	// println(state.history)
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

fn (state State) point_inside(x f32, y f32) int {
	mut sel := -1
	for i, circle in state.circles {
		if circle.contains(x, y) {
			sel = i
			break
		}
	}
	return sel
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
	sel        int
	sel_radius f32
	hover      int
	state      State
}

fn main() {
	app := &App{}
	sw_radius := ui.subwindow(
		id: 'sw_radius'
		layout: ui.column(
			width: 200
			height: 60
			margin_: 10
			spacing: 10
			bg_color: ui.alpha_colored(gx.light_gray, 100)
			widths: ui.stretch
			heights: ui.compact
			children: [
				ui.label(text: 'Adjust radius', justify: ui.center_center),
				ui.slider(
					id: 'sl_radius'
					orientation: .horizontal
					max: 50
					val: 20
					on_value_changed: radius_changed
				),
			]
		)
	)
	mut window := ui.window(
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
	window.subwindows << sw_radius
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
	mut sw := c.ui.window.subwindow('sw_radius')
	if c.ui.btn_down[0] {
		if sw.is_visible() {
			sw.set_visible(false)
			sl := c.ui.window.slider('sl_radius')
			action := ActionSetCircleRadius{
				circle_index: app.sel
				new_radius: f32(sl.val)
				old_radius: app.sel_radius
			}
			app.state.add_action(action)
			action.do(mut app.state)
		} else {
			// println("click $e.x $e.y nb pts = $app.state.circles.len")
			radius := 20
			circle := Circle{f32(e.x), f32(e.y), f32(radius)}
			action := ActionAddCircle{circle}
			app.state.add_action(action)
			app.state.reset_history() // clear the end of history from the current action
			action.do(mut app.state)
			// mut btn_redo := c.ui.window.button("btn_redo")
			// btn_redo.disabled = true
		}
	} else if c.ui.btn_down[1] {
		app.sel = app.state.point_inside(f32(e.x), f32(e.y))
		if app.sel >= 0 {
			app.sel_radius = app.state.circles[app.sel].radius
			sw.set_visible(true)
		}
	}
}

fn mouse_move_circles(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	mut app := &App(c.ui.window.state)
	app.hover = app.state.point_inside(f32(e.x), f32(e.y))
}

fn click_undo(mut a App, b &ui.Button) {
	if !b.ui.btn_down[0] {
		return
	}
	a.state.undo()

	// mut btn_redo := b.ui.window.button("btn_redo")
	// btn_redo.disabled = false
}

fn click_redo(mut a App, b &ui.Button) {
	if !b.ui.btn_down[0] {
		return
	}
	a.state.redo()
}

fn radius_changed(mut a App, sl &ui.Slider) {
	a.state.circles[a.sel].radius = sl.val
}
