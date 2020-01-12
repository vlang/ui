module main

import ui
import gx
import os

const (
	win_width = 600
	win_height = 385
	NR_COLS = 3
	CELL_HEIGHT = 25
	CELL_WIDTH = 100
	TABLE_WIDTH = CELL_WIDTH * NR_COLS
)

struct User {
	first_name string
	last_name  string
	age        int
}

struct Context {
mut:
	first_name &ui.TextBox
	last_name  &ui.TextBox
	age        &ui.TextBox
	pbar       &ui.ProgressBar
	users      []User
	window     &ui.Window
	label      &ui.Label
	txt_pos    int
}

struct Foo {
	widgets []ui.IWidgeter
}

fn main() {
	mut ctx := &Context{
		users: [User{
			first_name: 'Sam'
			last_name: 'Johnson'
			age: 29
		},
		User{
			first_name: 'Kate'
			last_name: 'Williams'
			age: 26
		}]
	}
	window := ui.new_window(ui.WindowConfig{
		width: win_width
		height: win_height
		title: 'V UI Demo'
		user_ptr: ctx
		draw_fn: draw
	})
	// mut t1 := ui.new_textbox(mut window, ui.Rect{20, 20, 200, 0},  'First name')
	ctx.first_name = ui.new_textbox(ui.TextBoxConfig{
		max_len: 20
		x: 20
		y: 20
		width: 200
		placeholder: 'First name'
		parent: window
	})
	ctx.last_name = ui.new_textbox(ui.TextBoxConfig{
		max_len: 50
		x: 20
		y: 50
		width: 200
		placeholder: 'Last name'
		parent: window
	})
	ctx.age = ui.new_textbox(ui.TextBoxConfig{
		max_len: 3
		x: 20
		y: 80
		width: 200
		placeholder: 'Age'
		parent: window
		is_numeric: true
	})
	ui.new_textbox(ui.TextBoxConfig{
		x: 20
		y: 110
		width: 200
		placeholder: 'Password'
		parent: window
		is_password: true
		max_len: 20
	})
	ui.new_checkbox(ui.CheckBoxConfig{
		parent: window
		x: 20
		y: 140
		is_checked: true
		text: 'Online registration'
	})
	ui.new_checkbox(ui.CheckBoxConfig{
		parent: window
		x: 20
		y: 165
		text: 'Subscribe to the newsletter'
	})
	ui.new_radio(ui.RadioConfig{
		parent: window
		x: 20
		width: 200
		y: 200
		values: ['United States', 'Canada', 'United Kingdom', 'Australia']
		title: 'Country'
	})
	ui.new_button(ui.ButtonConfig{
		x: 20
		y: 320
		parent: window
		text: 'Add user'
		onclick: btn_add_click
	})
	ctx.pbar = ui.new_progress_bar(ui.ProgressBarConfig{
		parent: window
		x: 20
		y: 350
		width: 200
		max: 10
		val: 2
	})
	ctx.label = ui.new_label(ui.LabelConfig{
		parent: window
		x: 230
		y: 350
		text: '2/10'
	})
	ui.new_picture(ui.PictureConfig{
		parent: window
		x: win_width - 100
		y: win_height - 100
		width: 100
		height: 100
		path: os.resource_abs_path( 'logo.png' )
	})
	ctx.window = window
	ui.run(window)
}

fn btn_add_click(ctx mut Context) {
	ctx.window.set_cursor()
	if ctx.users.len >= 10 {
		return
	}
	if ctx.first_name.text == '' || ctx.last_name.text == '' {
		return
	}
	ctx.users << User{
		first_name: ctx.first_name.text
		last_name: ctx.last_name.text
		age: ctx.age.text.int()
	}
	ctx.pbar.val++
	ctx.first_name.set_text('')
	ctx.first_name.focus()
	ctx.last_name.set_text('')
	ctx.age.set_text('')
	ctx.label.set_text('$ctx.users.len/10')
}

fn draw(ctx mut Context) {
	gg := ctx.window.ctx.gg // TODO
	mut ft := ctx.window.ctx.ft // TODO
	x := 280
	gg.draw_rect(x - 20, 0, TABLE_WIDTH + 100, 800, gx.white)
	for i, user in ctx.users {
		y := 20 + i * CELL_HEIGHT
		// Outer border
		gg.draw_empty_rect(x, y, TABLE_WIDTH, CELL_HEIGHT, gx.Gray)
		// Vertical separators
		gg.draw_line_c(x + CELL_WIDTH, y, x + CELL_WIDTH, y + CELL_HEIGHT, gx.Gray)
		gg.draw_line_c(x + CELL_WIDTH * 2, y, x + CELL_WIDTH * 2, y + CELL_HEIGHT, gx.Gray)
		// Text values
		ft.draw_text_def(x + 5, y + 5, user.first_name)
		ft.draw_text_def(x + 5 + CELL_WIDTH, y + 5, user.last_name)
		ft.draw_text_def(x + 5 + CELL_WIDTH * 2, y + 5, user.age.str())
	}
}
