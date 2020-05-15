import ui
import gx
import os

const (
	win_width = 700
	win_height = 385
	nr_cols = 4
	cell_height = 25
	cell_width = 100
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
	window     &ui.Window
	label      &ui.Label
	country    &ui.Radio
	txt_pos    int
	started    bool
}

fn main() {
	mut app := &State{
		users: [
			User{
				first_name: 'Sam'
				last_name: 'Johnson'
				age: 29
				country: 'United States'
			}
			User{
				first_name: 'Kate'
				last_name: 'Williams'
				age: 26
				country: 'Canada'
			}
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
		label: ui.label(
			text: '2/10'
		)
	}
	window := ui.window({
		width: win_width
		height: win_height
		state: app
		title: 'V UI Demo'
	}, [
		ui.row({
			stretch: true
			margin: {top:10,left:10,right:10,bottom:10}
		}, [
			ui.column({
				width: 200
				spacing: 13
			}, [
				ui.textbox(
					max_len: 20
					width: 200
					placeholder: 'First name'
					text: &app.first_name
					//is_focused: &app.started
				)
				ui.textbox(
					max_len: 50
					width: 200
					placeholder: 'Last name'
					text: &app.last_name
				)
				ui.textbox(
					max_len: 3
					width: 200
					placeholder: 'Age'
					is_numeric: true
					text: &app.age
				)
				ui.textbox(
					width: 200
					placeholder: 'Password'
					is_password: true
					max_len: 20
					text: &app.password
				)
				ui.checkbox(
					checked: true
					text: 'Online registration'
				)
				ui.checkbox(
					text: 'Subscribe to the newsletter'
				)
				app.country
				ui.row({
					spacing: 85
				}, [
					ui.button(
						text: 'Add user'
						onclick: btn_add_click
					)
					ui.button(
						text: '?'
						onclick: btn_help_click
					)
				])
				ui.row({
					spacing: 5
					alignment: .center
				}, [
					app.pbar
					app.label
				])
			])
			ui.column({
				stretch: true
				alignment: .right
			},[
				ui.canvas(
					height: 275
					draw_fn: canvas_draw
				),
				ui.picture(
					width: 100
					height: 100
					path: os.resource_abs_path( 'logo.png' )
				)
			])
		]),
		ui.menu(
			items: [
				ui.MenuItem{'Delete all users', menu_click},
				ui.MenuItem{'Export users', menu_click},
				ui.MenuItem{'Exit', menu_click},
			]
		)
	])
	app.window = window
	ui.run(window)
}

fn menu_click() {

}

fn btn_help_click(a, b voidptr) {
	ui.message_box('Built with V UI')
}

/*
fn (app mut App) btn_add_click(b &Button) {

}
*/

fn btn_add_click(mut app State, x voidptr) {
	//println('nr users=$app.users.len')
	//ui.notify('user', 'done')
	//app.window.set_cursor(.hand)
	if app.users.len >= 10 {
		return
	}
	if app.first_name == '' ||  app.last_name == '' {
		return
	}
	new_user := User{
		first_name: app.first_name //first_name.text
		last_name: app.last_name//.text
		age: app.age.int()
		country: app.country.selected_value()
	}
	app.users << new_user
	app.pbar.val++
	app.first_name = ''
	//app.first_name.focus()
	app.last_name = ''
	app.age = ''
	app.password = ''
	app.label.set_text('$app.users.len/10')
	//ui.message_box('$new_user.first_name $new_user.last_name has been added')
}

fn canvas_draw(app &State) {
	gg := app.window.ui.gg
	mut ft := app.window.ui.ft
	x := 240
	gg.draw_rect(x - 20, 0, table_width + 100, 800, gx.white)
	for i, user in app.users {
		y := 20 + i * cell_height
		// Outer border
		gg.draw_empty_rect(x, y, table_width, cell_height, gx.Gray)
		// Vertical separators
		gg.draw_line(x + cell_width, y, x + cell_width, y + cell_height, gx.Gray)
		gg.draw_line(x + cell_width * 2, y, x + cell_width * 2, y + cell_height, gx.Gray)
		gg.draw_line(x + cell_width * 3, y, x + cell_width * 3, y + cell_height, gx.Gray)
		// Text values
		ft.draw_text_def(x + 5, y + 5, user.first_name)
		ft.draw_text_def(x + 5 + cell_width, y + 5, user.last_name)
		ft.draw_text_def(x + 5 + cell_width * 2, y + 5, user.age.str())
		ft.draw_text_def(x + 5 + cell_width * 3, y + 5, user.country)
	}
}
