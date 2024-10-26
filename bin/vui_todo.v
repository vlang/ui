import ui

const w_width = 400
const w_height = 600
const w_title = 'V DO'

struct Task {
mut:
	title string
	done  bool
}

@[heap]
struct State {
pub mut:
	tasks     map[int]Task
	inputs    []string
	last_task int = 1
	input     string
	window    &ui.Window = unsafe { nil }
}

fn main() {
	mut app := &State{
		tasks: {
			0: Task{
				title: 'test'
				done:  false
			}
			1: Task{
				title: 'test 2'
				done:  false
			}
		}
	}

	window := ui.window(
		width:  w_width
		height: w_height
		// state: app
		title: w_title
		mode:  .resizable
		// on_scroll: on_scroll
		layout: ui.column(
			margin_:  8
			heights:  [ui.stretch, ui.compact]
			children: [
				ui.column(
					id:         'entries_column'
					heights:    ui.compact
					spacing:    4
					scrollview: true
					children:   tasks(mut app)
				),
				ui.row(
					widths:   [ui.stretch, ui.compact]
					spacing:  4
					children: [ui.textbox(text: &app.input, on_enter: app.on_enter),
						ui.button(text: '+', on_click: app.btn_add_task)]
				),
			]
		)
	)

	app.window = window
	ui.run(window)
}

fn tasks(mut app State) []ui.Widget {
	mut tasks := []ui.Widget{}

	for i, _ in app.tasks {
		tasks << entry(i, mut app)
	}

	return tasks
}

fn entry(task_id int, mut app State) &ui.Stack {
	task := app.tasks[task_id]
	app.inputs << task.title.clone()
	// THIS WEIRDLY DOES NOT WORK:
	// mut tb := ui.textbox(id: "task_tb_$task_id", text: &(app.tasks[task_id].title), on_char: txb_enter_edit)
	// So the introduction of app.inputs
	mut tb := ui.textbox(
		id:      'task_tb_${task_id}'
		text:    &(app.inputs[app.inputs.len - 1])
		on_char: app.txb_enter_edit
	)
	tb.z_index = ui.z_index_hidden
	row := ui.row(
		id:       'task_row_${task_id}'
		widths:   [ui.compact, ui.stretch, ui.stretch, ui.compact]
		spacing:  4
		children: [
			ui.checkbox(id: 'task_cb_${task_id}', checked: task.done, on_click: app.cb_task),
			ui.label(id: 'task_lab_${task_id}', text: task.title.clone()),
			tb,
			ui.button(id: 'task_btn_${task_id}', text: 'E', on_click: app.btn_task),
		]
	)
	return row
}

fn task_entry_index(column &ui.Stack, task_id int) int {
	return column.child_index_by_id('task_row_${task_id}')
}

fn (mut app State) cb_task(cb &ui.CheckBox) {
	task_id := cb.id.split('_').last().int()
	app.tasks[task_id].done = cb.checked
}

fn (mut app State) btn_add_task(btn &ui.Button) {
	app.add_task()
}

fn (mut app State) btn_task(mut btn ui.Button) {
	task_id := btn.id.split('_').last().int()
	win := btn.ui.window

	mut column := win.get_or_panic[ui.Stack]('entries_column')
	mut lab := win.get_or_panic[ui.Label]('task_lab_${task_id}')
	// println('btn_task($btn.text) $task_id lab=<$lab.text>')
	mut tb := win.get_or_panic[ui.TextBox]('task_tb_${task_id}')

	println('tb=<${*tb.text}>')
	task_index := task_entry_index(column, task_id)

	//
	println(' at ${task_index}')

	if btn.text == 'E' {
		if task_index > -1 {
			mut labw := ui.Widget(lab)
			labw.set_depth(ui.z_index_hidden)
			mut tbw := ui.Widget(tb)
			tbw.set_depth(0)
			btn.text = 'D'
			win.update_layout()
			tb.focus()
		}
	} else {
		if task_index > -1 {
			column.remove(at: task_index)
			app.tasks.delete(task_index)
		}
	}
}

fn (mut app State) txb_enter_edit(mut tb ui.TextBox, keycode u32) {
	if keycode == 13 {
		// println("on_enter: $app.tasks")
		task_id := tb.id.split('_').last().int()
		win := tb.ui.window
		mut lab := win.get_or_panic[ui.Label]('task_lab_${task_id}')
		mut btn := win.get_or_panic[ui.Button]('task_btn_${task_id}')
		mut labw := ui.Widget(lab)
		labw.set_depth(0)
		mut tbw := ui.Widget(tb)
		tbw.set_depth(ui.z_index_hidden)
		lab.text = *tb.text
		btn.text = 'E'
		win.update_layout()
	}
}

fn (mut app State) add_task() {
	window := app.window
	app.last_task += 1
	new_task := Task{
		title: app.input.clone()
		done:  false
	}
	app.tasks[app.last_task] = new_task
	app.input = ''

	// println("add $app.last_task $app.tasks")

	mut column := window.get_or_panic[ui.Stack]('entries_column')

	column.add(
		child: entry(app.last_task, mut app)
	)
}

fn (mut app State) on_enter(_ &ui.TextBox) {
	app.add_task()
	println(app.tasks)
}
