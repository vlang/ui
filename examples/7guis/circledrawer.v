import ui
import gx
import math

const default_radius = 20

// Circle

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

// Action

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

// App

@[heap]
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
		id:     'sw_radius'
		layout: ui.column(
			width:    200
			height:   60
			margin_:  10
			spacing:  10
			bg_color: ui.alpha_colored(gx.light_gray, 100)
			widths:   ui.stretch
			heights:  ui.compact
			children: [
				ui.label(text: 'Adjust radius', justify: ui.center_center),
				ui.slider(
					id:               'sl_radius'
					orientation:      .horizontal
					max:              50
					val:              20
					on_value_changed: app.slider_changed
				),
			]
		)
	)
	mut window := ui.window(
		width:  500
		height: 400
		title:  'Circle drawer'
		mode:   .resizable
		layout: ui.column(
			spacing:  10
			margin_:  20
			widths:   ui.stretch
			heights:  [ui.compact, ui.stretch]
			children: [
				ui.row(
					spacing:  20
					widths:   [ui.stretch, 40, 40, ui.stretch]
					children: [ui.spacing(),
						ui.button(
							id:       'btn_undo'
							text:     'Undo'
							radius:   5
							on_click: app.click_undo
						),
						ui.button(
							id:       'btn_redo'
							text:     'Redo'
							radius:   5
							on_click: app.click_redo
						),
						ui.spacing()]
				),
				ui.canvas_plus(
					bg_color:      gx.white
					bg_radius:     .025
					clipping:      true
					on_draw:       app.draw_circles
					on_click:      app.click_circles
					on_mouse_move: app.mouse_move_circles
				),
			]
		)
	)
	window.subwindows << sw_radius
	ui.run(window)
}

fn (app &App) draw_circles(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	for i, circle in app.state.circles {
		if i == app.hover {
			c.draw_device_circle_filled(d, circle.x, circle.y, circle.radius, gx.light_gray)
		}
		c.draw_device_circle_empty(d, circle.x, circle.y, circle.radius, gx.black)
	}
}

fn (mut app App) click_circles(c &ui.CanvasLayout, e ui.MouseEvent) {
	mut sw := c.ui.window.get_or_panic[ui.SubWindow]('sw_radius')
	if c.ui.btn_down[0] {
		if sw.is_visible() {
			sw.set_visible(false)
			sl := c.ui.window.get_or_panic[ui.Slider]('sl_radius')
			action := ActionSetCircleRadius{
				circle_index: app.sel
				new_radius:   f32(sl.val)
				old_radius:   app.sel_radius
			}
			app.state.add_action(action)
			action.do(mut app.state)
		} else {
			radius := default_radius
			circle := Circle{f32(e.x), f32(e.y), f32(radius)}
			action := ActionAddCircle{circle}
			app.state.add_action(action)
			app.state.reset_history() // clear the end of history from the current action
			action.do(mut app.state)
		}
	} else if c.ui.btn_down[1] {
		app.sel = app.state.point_inside(f32(e.x), f32(e.y))
		if app.sel >= 0 {
			app.sel_radius = app.state.circles[app.sel].radius
			sw.set_visible(true)
			sw.set_pos(e.x + int(app.sel_radius), e.y + int(app.sel_radius))
			sw.update_layout()
		}
	}
	mut btn_undo := c.ui.window.get_or_panic[ui.Button]('btn_undo')
	check_undo_disabled(app.state, mut btn_undo)
	mut btn_redo := c.ui.window.get_or_panic[ui.Button]('btn_redo')
	check_redo_disabled(app.state, mut btn_redo)
}

fn (mut app App) mouse_move_circles(c &ui.CanvasLayout, e ui.MouseMoveEvent) {
	app.hover = app.state.point_inside(f32(e.x), f32(e.y))
}

fn (mut app App) click_undo(mut b ui.Button) {
	if !b.ui.btn_down[0] {
		return
	}
	app.state.undo()
	check_undo_disabled(app.state, mut b)
	mut redo := b.ui.window.get_or_panic[ui.Button]('btn_redo')
	check_redo_disabled(app.state, mut redo)
}

fn (mut app App) click_redo(mut b ui.Button) {
	if !b.ui.btn_down[0] {
		return
	}
	app.state.redo()
	check_redo_disabled(app.state, mut b)
	mut undo := b.ui.window.get_or_panic[ui.Button]('btn_undo')
	check_undo_disabled(app.state, mut undo)
}

fn check_undo_disabled(state State, mut undo ui.Button) {
	undo.disabled = state.current_action == -1
}

fn check_redo_disabled(state State, mut redo ui.Button) {
	redo.disabled = state.current_action == state.history.len - 1
}

fn (mut app App) slider_changed(sl &ui.Slider) {
	app.state.circles[app.sel].radius = sl.val
}
