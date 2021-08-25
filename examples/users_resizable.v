import ui
import gx
import os

const (
	win_width   = 780
	win_height  = 395
	nr_cols     = 4
	cell_height = 25
	cell_width  = 100
	table_width = cell_width * nr_cols
)

struct User {
	first_name string
	last_name  string
	age        int
	country    string
}

struct State {
mut:
	first_name string
	last_name  string
	age        string
	password   string
	pbar       &ui.ProgressBar
	users      []User
	window     &ui.Window = voidptr(0)
	label      &ui.Label
	country    &ui.Radio
	txt_pos    int
	started    bool
	is_error   bool
}

fn main() {
	mut logo := os.resource_abs_path(os.join_path('assets/img', 'logo.png'))
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
		state: app
		title: 'V UI Demo'
		mode: .resizable
		native_message: false
		children: [
			ui.row(
				margin_: .02
				spacing: .02
				widths: [.3, .64] // 1.0 == .64 + .3 + .02 + 2 * .02
				children: [
					ui.column(
					spacing: 10
					heights: ui.compact
					scrollview: true
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
							id: 'btn_row'
							widths: [.5, .2]
							heights: 20.
							spacing: .3
							children: [
								ui.button(
								text: 'Add user'
								tooltip: 'Required fields:\n  * First name\n  * Last name\n  * Age'
								onclick: btn_add_click
								radius: .3
							),
								ui.button(
									tooltip: 'about'
									text: '?'
									onclick: btn_help_click
									radius: .3
								),
							]
						),
						ui.row(
							spacing: .05
							widths: [.8, .15]
							heights: ui.compact
							children: [app.pbar, app.label]
						),
					]
				),
					ui.column(
						scrollview: true
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
							ui.compact,
						]
						bg_color: gx.white
						children: [
							ui.canvas_plus(
								width: 400
								height: 275
								on_draw: draw
								text_size: 20
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

fn menu_click() {
}

fn btn_help_click(a voidptr, b &ui.Button) {
	// ui.message_box('Built with V UI')
	b.ui.window.message('Built with V UI\nThus \nAnd')
}

/*
fn (mut app App) btn_add_click(b &Button) {

}
*/
fn btn_add_click(mut app State, x voidptr) {
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
	app.label.set_text('$app.users.len/10')
	// ui.message_box('$new_user.first_name $new_user.last_name has been added')
}

fn draw(c &ui.CanvasLayout, app &State) {
	w, h := c.width, c.height
	c.draw_rect(0, 0, w, h, gx.white)
	marginx, marginy := 20, 20
	for i, user in app.users {
		y := marginy + i * cell_height
		// Outer border
		c.draw_empty_rect(marginx, y, table_width, cell_height, gx.gray)
		// Vertical separators
		c.draw_line(cell_width, y, cell_width, y + cell_height, gx.gray)
		c.draw_line(cell_width * 2, y, cell_width * 2, y + cell_height, gx.gray)
		c.draw_line(cell_width * 3, y, cell_width * 3, y + cell_height, gx.gray)
		// Text values
		c.draw_text(marginx + 5, y + 5, user.first_name)
		c.draw_text(marginx + 5 + cell_width, y + 5, user.last_name)
		c.draw_text(marginx + 5 + cell_width * 2, y + 5, user.age.str())
		c.draw_text_with_color(marginx + 5 + cell_width * 3, y + 5, user.country, gx.blue)
	}
}
