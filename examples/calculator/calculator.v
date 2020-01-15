import ui

const (
	buttons_per_row = 4
)

struct App {
mut:
	txtbox     &ui.TextBox
	window     &ui.Window
	button_idx int
	btns       []&ui.Button
	op         string
	a f64
	b f64
	result     f64
	is_float bool
	new_number bool
}

fn main() {
	ops := ['C', '', '', '÷', '7', '8', '9', '*', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', '', '=']
	mut app := &App{}
	app.window = ui.new_window({
		width: 175
		height: 220
		title: 'Calculator'
		user_ptr: app
	})
	app.txtbox = ui.new_textbox({
		placeholder: '0'
		parent: app.window
		width: 160
		x: 5
		y: 5
		read_only: true
	})
	for op in ops {
		app.add_button(op)
	}
	ui.run(app.window)
}

fn btn_click(app mut App, btn &ui.Button) {
	op := btn.text
	number := app.txtbox.text
	if op == 'C' {
		app.result = 0
		app.op = ''
		app.new_number = true
		app.txtbox.set_text('0')
		app.is_float = false
		return
	}
	if op[0].is_digit() || op == '.' {
		// Can only have one `.` in a number
		if op == '.'  && number.contains('.') {
			return
		}
		if app.txtbox.text.len >= 17 {
			return
		}
		// First click, replace the zero
		if number == '0' {
			app.txtbox.set_text(btn.text)
		}
		else {
			if app.new_number {
				app.txtbox.set_text(btn.text)
				app.new_number = false
			}	else {
				// Append a new digit
				app.txtbox.set_text(number + btn.text)
			}
		}
		return
	}
	// User pressed + etc several times, ignore it
	if app.new_number {
		return
	}
	if number.contains('.') {
		app.is_float = true
	}
	if op in ['+', '-'] {
		app.op = op
		if op == '+' {
			app.result += number.int()
		} else if op == '-' {
			app.result -= number.int()
		}
		app.new_number  = true
	}
	else if op == '=' {
	}
	// Format and print the result
	if app.is_float {
		app.txtbox.set_text(app.result.str())
	}
	else {
		app.txtbox.set_text(int(app.result).str())
	}
}

fn (ctx mut App) add_button(text string) {
	// Calculate button's coordinates from its index
	x := 5 + ctx.button_idx % buttons_per_row * (30 + 10)
	y := 35 + (ctx.button_idx / buttons_per_row) * 35
	// Skip empty buttons
	if text != '' {
		ctx.btns << ui.new_button({
			text: text
			x: x
			y: y
			parent: ctx.window
			onclick: btn_click
			width: 30
			height: 30
		})
	}
	ctx.button_idx++
}
