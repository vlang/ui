import math
import os
import gx
import ui

@[heap]
struct App {
mut:
	text       string
	window     &ui.Window
	rows       []&ui.Layout
	result     f64
	is_float   bool
	new_number bool
	operands   []f64
	operations []string
}

fn main() {
	ops := [
		['C', '%', '^', '÷'],
		['7', '8', '9', '*'],
		['4', '5', '6', '-'],
		['1', '2', '3', '+'],
		['0', '.', '±', '='],
	]
	mut app := &App{
		window: unsafe { nil }
	}
	mut children := []ui.Widget{}
	children = [
		ui.textbox(
			text:          &app.text
			placeholder:   '0'
			fitted_height: true
			// width: 135
			text_size: 1.0 / 10
			read_only: true
		),
	]

	for row_ops in ops {
		mut row_children := []ui.Widget{}
		for op in row_ops {
			row_children << ui.button(
				text:      op
				on_click:  app.btn_click
				text_size: 1.0 / 20
				radius:    .25
				// theme: 'blue'
				hoverable: true
			)
		}
		children << ui.row(
			spacing:  .02
			widths:   ui.stretch
			children: row_children
		)
	}

	app.window = ui.window(
		width:     300
		height:    400
		title:     'V Calc'
		mode:      .resizable // .max_size //
		font_path: os.resource_abs_path(os.join_path('../assets/fonts/', 'RobotoMono-Regular.ttf'))
		theme:     'red'
		children:  [
			ui.column(
				margin_:  10
				spacing:  .02
				heights:  ui.stretch // [ui.compact, ui.stretch, ui.stretch, ui.stretch, ui.stretch, ui.stretch] // or [30.0, ui.stretch, ui.stretch, ui.stretch, ui.stretch, ui.stretch]
				bg_color: gx.rgb(240, 180, 130)
				children: children
			),
		]
	)
	// app.text = "size= ${app.window.width} ${app.window.height}"
	app.window.add_shortcut_theme()
	ui.run(app.window)
}

fn (mut app App) btn_click(btn &ui.Button) {
	op := btn.text
	number := app.text
	if op == 'C' {
		app.result = 0
		app.operands = []
		app.operations = []
		app.new_number = true
		app.is_float = false
		app.update_result()
		return
	}
	if op[0].is_digit() || op == '.' {
		// Can only have one `.` in a number
		if op == '.' && number.contains('.') {
			return
		}
		if app.new_number {
			app.text = btn.text
			app.new_number = false
			app.is_float = false
		} else {
			// Append a new digit
			app.text = number + btn.text
		}
		return
	}
	if number.contains('.') {
		app.is_float = true
	}
	if op in ['+', '-', '÷', '*', '±', '='] {
		if !app.new_number {
			app.new_number = true
			app.operands << number.f64()
		}
		app.operations << op
		app.calculate()
	}
	app.update_result()
}

fn (mut app App) update_result() {
	// Format and print the result
	if !math.trunc(app.result).eq_epsilon(app.result) {
		app.text = '${app.result:-15.10f}'
	} else {
		app.text = int(app.result).str()
	}
}

fn pop_f64(a []f64) (f64, []f64) {
	res := a.last()
	return res, a[0..a.len - 1]
}

fn pop_string(a []string) (string, []string) {
	res := a.last()
	return res, a[0..a.len - 1]
}

fn (mut app App) calculate() {
	mut a := f64(0)
	mut b := f64(0)
	mut op := ''
	mut operands := app.operands.clone()
	mut operations := app.operations.clone()
	mut result := if operands.len == 0 { f64(0.0) } else { operands.last() }
	mut i := 0
	for {
		i++
		if operations.len == 0 {
			break
		}
		op, operations = pop_string(operations)
		if op == '=' {
			continue
		}
		if operands.len < 1 {
			operations << op
			break
		}
		b, operands = pop_f64(operands)
		if op == '±' {
			result = -b
			operands << result
			continue
		}
		if operands.len < 1 {
			operations << op
			operands << b
			break
		}
		a, operands = pop_f64(operands)
		match op {
			'+' {
				result = a + b
			}
			'-' {
				result = a - b
			}
			'*' {
				result = a * b
			}
			'÷' {
				if int(b) == 0 {
					eprintln('Division by zero!')
					b = 0.0000000001
				}
				result = a / b
			}
			else {
				operands << a
				operands << b
				result = b
				eprintln('Unknown op: ${op} ')
				break
			}
		}
		operands << result
		// eprintln('i: ${i:4d} | res: ${result} | op: $op | operands: $operands | operations: $operations')
	}
	app.operations = operations
	app.operands = operands
	app.result = result
	// eprintln('----------------------------------------------------')
	// eprintln('Operands: $app.operands  | Operations: $app.operations ')
	// eprintln('-------- result: $result | i: $i -------------------')
}
