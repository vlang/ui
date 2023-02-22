module users

import ui
import gx

struct User {
	first_name string
	last_name  string
	age        int
	country    string
}

[heap]
pub struct AppUsers {
pub mut:
	id      string
	window  &ui.Window = unsafe { nil }
	layout  &ui.Layout = ui.empty_stack
	users   []User
	pbar    &ui.ProgressBar = unsafe { nil }
	label   &ui.Label       = unsafe { nil }
	country &ui.Radio       = unsafe { nil }
	//
	first_name string
	last_name  string
	age        string
	password   string
	is_error   bool
}

[params]
pub struct AppUsersParams {
pub mut:
	id    string
	users []User = [
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
}

pub fn new(p AppUsersParams) &AppUsers {
	mut app := &AppUsers{
		id: p.id
		users: p.users
	}
	app.make_layout()
	return app
}

pub fn (mut app AppUsers) make_layout() {
	mut logo := 'v-logo'
	$if android {
		logo = 'img/logo.png'
	}
	app.country = ui.radio(
		width: 200
		values: ['United States', 'Canada', 'United Kingdom', 'Australia']
		title: 'Country'
	)
	app.pbar = ui.progressbar(
		width: 170
		max: 10
		val: 2
		// theme: "red"
	)
	app.label = ui.label(id: 'counter', text: '2/10', text_font_name: 'fixed_bold_italic')
	app.layout = ui.row(
		bg_color: gx.white
		margin_: .02
		spacing: .02
		widths: [ui.compact, ui.stretch] // 1.0 == .64 + .3 + .02 + 2 * .02
		children: [
			ui.column(
				spacing: 10
				widths: ui.compact
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
						widths: ui.compact
						heights: 20.0
						spacing: 80
						children: [
							ui.button(
								width: 60
								text: 'Add user'
								tooltip: 'Required fields:\n  * First name\n  * Last name\n  * Age'
								// on_click: app.btn_add_click
								radius: .0
							),
							ui.button(
								width: 40
								tooltip: 'about'
								text: '?'
								// on_click: btn_help_click
								radius: .3
							),
						]
					),
					ui.row(
						spacing: 10
						widths: [
							150.0,
							40,
						]
						heights: ui.compact
						children: [
							app.pbar,
							app.label,
						]
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
				children: [
					ui.canvas_plus(
						width: 400
						height: 275
						// on_draw: app.draw
						bg_color: gx.Color{255, 220, 220, 150}
						bg_radius: 10
						// text_size: 20
					),
					ui.picture(
						id: 'logo'
						width: 50
						height: 50
						path: logo
					),
				]
			),
		]
	)
}
