import ui
import gg
import gx
import os

const win_width = 780
const win_height = 385
const nr_cols = 4
const cell_height = 25
const cell_width = 100
const table_width = cell_width * nr_cols

struct User {
	first_name string
	last_name  string
	age        int
	country    string
}

@[heap]
struct State {
mut:
	first_name string
	last_name  string
	age        string
	password   string
	pbar       &ui.ProgressBar
	users      []User
	window     &ui.Window = unsafe { nil }
	label      &ui.Label
	country    &ui.Radio
	txt_pos    int
	started    bool
	is_error   bool
}

fn main() {
	mut logo := os.resource_abs_path(os.join_path('../assets/img', 'logo.png'))
	$if android {
		logo = 'img/logo.png'
	}
	mut app := &State{
		users: [
			User{
				first_name: 'Sam'
				last_name: 'Johnson'
				age: 29
				country: 'United States'
			},
			User{
				first_name: 'Kate'
				last_name: 'Williams'
				age: 26
				country: 'Canada'
			},
		]
		country: ui.radio(
			width: 200
			values: ['United States', 'Canada', 'United Kingdom', 'Australia']
			title: 'Country'
		)
		pbar: ui.progressbar(
			width: 170
			max: 10
			val: 2
		)
		label: ui.label(text: '2/10')
	}
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI Demo'
		// bg_color: gx.light_blue
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
								max_len: 20
								width: 200
								placeholder: 'First name'
								text: &app.first_name
								// is_focused: &app.started
								is_error: &app.is_error
								is_focused: true
							),
							ui.textbox(
								max_len: 50
								width: 200
								placeholder: 'Last name'
								text: &app.last_name
								is_error: &app.is_error
							),
							ui.textbox(
								max_len: 3
								width: 200
								placeholder: 'Age'
								is_numeric: true
								text: &app.age
								is_error: &app.is_error
							),
							ui.textbox(
								width: 200
								placeholder: 'Password'
								is_password: true
								max_len: 20
								text: &app.password
							),
							ui.checkbox(
								checked: true
								text: 'Online registration'
							),
							ui.checkbox(text: 'Subscribe to the newsletter'),
							app.country,
							ui.row(
								spacing: 65
								widths: ui.compact
								children: [
									ui.button(
										text: 'Add user'
										on_click: app.btn_add_click
									),
									ui.button(
										text: '?'
										on_click: btn_help_click
									),
								]
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
							ui.picture(
								width: 100
								height: 100
								path: logo
							),
						]
					),
				]
			),
			// ui.menu(
			// 	items: [ui.MenuItem{'Delete all users', menu_click},
			// 		ui.MenuItem{'Export users', menu_click}, ui.MenuItem{'Exit', menu_click}]
			// ),
		]
	)
	app.window = window
	ui.run(window)
}

// fn menu_click() {
// }

fn btn_help_click(b voidptr) {
	ui.message_box('Built with V UI')
}

fn (mut app State) btn_add_click(b &ui.Button) {
	// println('nr users=$app.users.len')
	// ui.notify('user', 'done')
	// app.window.set_cursor(.hand)
	if app.users.len >= 10 {
		return
	}
	if app.first_name == '' || app.last_name == '' || app.age == '' {
		app.is_error = true
		return
	}
	new_user := User{
		first_name: app.first_name // first_name.text
		last_name: app.last_name // .text
		age: app.age.int()
		country: app.country.selected_value()
	}
	app.users << new_user
	app.pbar.val++
	app.first_name = ''
	// app.first_name.focus()
	app.last_name = ''
	app.age = ''
	app.password = ''
	app.label.set_text('${app.users.len}/10')
	// ui.message_box('$new_user.first_name $new_user.last_name has been added')
}

fn (app &State) canvas_draw(gg_ &gg.Context, c &ui.Canvas) { // x_offset int, y_offset int) {
	x_offset, y_offset := c.x, c.y
	w, h := c.width, c.height
	x := x_offset
	gg_.draw_rect_filled(x - 20, 0, w + 120, h + 120, gx.white)
	for i, user in app.users {
		y := y_offset + 20 + i * cell_height
		// Outer border
		gg_.draw_rect_empty(x, y, table_width, cell_height, gx.gray)
		// Vertical separators
		gg_.draw_line(x + cell_width, y, x + cell_width, y + cell_height, gx.gray)
		gg_.draw_line(x + cell_width * 2, y, x + cell_width * 2, y + cell_height, gx.gray)
		gg_.draw_line(x + cell_width * 3, y, x + cell_width * 3, y + cell_height, gx.gray)
		// Text values
		gg_.draw_text_def(x + 5, y + 5, user.first_name)
		gg_.draw_text_def(x + 5 + cell_width, y + 5, user.last_name)
		gg_.draw_text_def(x + 5 + cell_width * 2, y + 5, user.age.str())
		gg_.draw_text_def(x + 5 + cell_width * 3, y + 5, user.country)
	}
}
