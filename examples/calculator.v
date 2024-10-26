import math
import ui

const buttons_per_row = 4
const bwidth = 30
const bheight = 30
const bpadding = 5

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
			text:        &app.text
			placeholder: '0'
			width:       135
			read_only:   true
		),
	]
	for op in ops {
		children << ui.row(
			spacing:  5
			height:   30
			widths:   ui.stretch
			children: get_row(app, op)
		)
	}
	app.window = ui.window(
		width:    145
		height:   210
		title:    'V Calc'
		children: [
			ui.column(
				margin:   ui.Margin{5, 5, 5, 5}
				spacing:  5
				children: children
			),
		]
	)
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

fn get_row(app &App, ops []string) []ui.Widget {
	mut children := []ui.Widget{}
	for op in ops {
		if op == ' ' {
			continue
		}
		children << ui.button(
			text:     op
			on_click: app.btn_click
			width:    bwidth
			height:   bheight
		)
	}
	return children
}
