import ui
import gg
import gx

const (
	win_width   = 660
	win_height  = 385
	nr_cols     = 4
	cell_height = 25
	cell_width  = 100
	table_width = cell_width * nr_cols
)

struct Todo {
	id        int
	title     string
	completed bool
}

[heap]
struct State {
mut:
	id        int
	title     string
	completed bool
	todos     []Todo
	pbar      &ui.ProgressBar
	window    &ui.Window = unsafe { nil }
	label     &ui.Label
	txt_pos   int
	started   bool
	is_error  bool
}

fn main() {
	mut app := &State{
		todos: [
			Todo{
				id: 1
				title: 'Learn V'
				completed: false
			},
			Todo{
				id: 2
				title: 'Build Todo Example'
				completed: false
			},
		]
		pbar: ui.progressbar(
			width: 170
			max: 5
			val: 2
		)
		label: ui.label(
			text: '2/5'
		)
	}

	window := ui.window(
		width: win_width
		height: win_height
		title: 'Todo Example - Max of V (5)'
		children: [
			ui.row(
				margin: ui.Margin{10, 10, 10, 10}
				widths: [200.0, ui.stretch]
				spacing: 30
				children: [
					ui.column(
						spacing: 13
						children: [
							ui.textbox(
								max_len: 100
								placeholder: 'Enter Todo'
								width: 200
								is_focused: true
								is_error: &app.is_error
								text: &app.title
							),
							ui.checkbox(
								text: 'Completed'
								checked: false
							),
							ui.button(
								text: 'Add Todo'
								width: 200
								on_click: app.add_todo
							),
							ui.row(
								spacing: 5
								children: [
									app.pbar,
									app.label,
								]
							),
						]
					),
					ui.column(
						alignments: ui.HorizontalAlignments{
							center: [
								0,
							]
							right: [
								1,
							]
						}
						widths: [
							ui.stretch,
							ui.compact,
						]
						heights: [
							ui.stretch,
							100.0,
						]
						children: [
							ui.canvas(
								width: 400
								height: 275
								draw_fn: app.canvas_draw
							),
						]
					),
				]
			),
		]
	)
	app.window = window
	ui.run(window)
}

fn (mut app State) add_todo(b &ui.Button) {
	if app.title.len == 0 {
		app.is_error = true
		return
	}
	if app.todos.len == 5 {
		ui.message_box('Max of 5 Todos reached. \nWiping the first Todo to make room!')
		app.todos = app.todos[1..5]
	}

	app.is_error = false
	app.id = app.todos[app.todos.len - 1].id + 1
	new_todo := Todo{
		id: app.id
		title: app.title
		completed: false
	}
	app.todos << new_todo
	app.pbar.val++
	app.title = ''
	app.completed = false
	app.label.set_text('${app.todos.len}/5')
	// ui.message_box('$new_todo.id $new_todo.title has been added')
}

fn (app &State) canvas_draw(gg_ &gg.Context, c &ui.Canvas) { // x_offset int, y_offset int) {
	x_offset, y_offset := c.x, c.y
	w, h := c.width, c.height
	x := x_offset
	gg_.draw_rect_filled(x - 20, 0, w + 120, h + 120, gx.white)
	for i, todo in app.todos {
		y := y_offset + 20 + i * cell_height
		// Outer border
		gg_.draw_rect_empty(x, y, table_width, cell_height, gx.gray)
		// Vertical separators
		gg_.draw_line(x + cell_width, y, x + cell_width, y + cell_height, gx.gray)
		gg_.draw_line(x + cell_width * 3, y, x + cell_width * 3, y + cell_height, gx.gray)
		// Text values
		gg_.draw_text_def(x + 5, y + 5, todo.id.str())
		gg_.draw_text_def(x + 5 + cell_width, y + 5, todo.title)
		gg_.draw_text_def(x + 5 + cell_width * 3, y + 5, todo.completed.str())
	}
}
