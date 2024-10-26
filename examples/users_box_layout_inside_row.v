import ui
import gx

const win_width = 780
const win_height = 395
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
	mut logo := 'v-logo'
	$if android {
		logo = 'img/logo.png'
	}
	mut app := &State{
		users:   [
			User{
				first_name: 'Sam'
				last_name:  'Johnson'
				age:        29
				country:    'United States'
			},
			User{
				first_name: 'Kate'
				last_name:  'Williams'
				age:        26
				country:    'Canada'
			},
		]
		country: ui.radio(
			width:  200
			values: ['United States', 'Canada', 'United Kingdom', 'Australia']
			title:  'Country'
		)
		pbar:    ui.progressbar(
			width: 170
			max:   10
			val:   2
			// theme: "red"
		)
		label:   ui.label(text: '2/10')
	}
	mut window := ui.window(
		width:    win_width
		height:   win_height
		title:    'V UI Demo'
		mode:     .resizable
		bg_color: ui.color_solaris
		// theme: 'red'
		native_message: false
		layout:         ui.row(
			widths:   ui.stretch
			heights:  ui.stretch
			children: [
				ui.box_layout(
					id:       'bl'
					children: {
						'col1: (0.05,0.05) ++ (0.24,0.79)': ui.column(
							spacing:    10
							widths:     ui.compact
							heights:    ui.compact
							scrollview: true
							bg_color:   gx.white
							// margin_: 10
							children: [
								ui.textbox(
									max_len:     20
									width:       200
									placeholder: 'First name'
									text:        &app.first_name
									// is_focused: &app.started
									is_error:   &app.is_error
									is_focused: true
								),
								ui.textbox(
									max_len:     50
									width:       200
									placeholder: 'Last name'
									text:        &app.last_name
									is_error:    &app.is_error
								),
								ui.textbox(
									max_len:     3
									width:       200
									placeholder: 'Age'
									is_numeric:  true
									text:        &app.age
									is_error:    &app.is_error
								),
								ui.textbox(
									width:       200
									placeholder: 'Password'
									is_password: true
									max_len:     20
									text:        &app.password
								),
								ui.checkbox(
									checked: true
									text:    'Online registration'
								),
								ui.checkbox(text: 'Subscribe to the newsletter'),
								app.country,
								ui.row(
									id:       'btn_row'
									widths:   [.5, .2]
									heights:  20.0
									spacing:  .3
									children: [
										ui.button(
											text:     'Add user'
											tooltip:  'Required fields:\n  * First name\n  * Last name\n  * Age'
											on_click: app.btn_add_click
											radius:   .0
										),
										ui.button(
											tooltip:  'about'
											text:     '?'
											on_click: btn_help_click
											radius:   .3
										),
									]
								),
								ui.row(
									spacing:  .05
									widths:   [
										.8,
										.15,
									]
									heights:  ui.compact
									children: [
										app.pbar,
										app.label,
									]
								),
							]
						)
						'col2: (0.32,0.21) ++ (0.68,0.78)': ui.column(
							scrollview: true
							alignments: ui.HorizontalAlignments{
								center: [
									0,
								]
								right:  [
									1,
								]
							}
							widths:     [
								ui.stretch,
								ui.compact,
							]
							heights:    [
								ui.stretch,
								ui.compact,
							]
							children:   [
								ui.canvas_plus(
									width:     400
									height:    275
									on_draw:   app.draw
									bg_color:  gx.Color{255, 220, 220, 150}
									bg_radius: 10
									// text_size: 20
								),
								ui.picture(
									id:     'logo'
									width:  50
									height: 50
									path:   logo
								),
							]
						)
					}
				),
			]
		)
	)
	app.window = window

	// add shortcut
	window.add_shortcut_theme()

	ui.run(window)
}

fn btn_help_click(b &ui.Button) {
	// ui.message_box('Built with V UI')
	b.ui.window.message('  Built with V UI\n  Thus \n  And')
}

/*
fn (mut app App) btn_add_click(b &Button) {

}
*/
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
		last_name:  app.last_name  // .text
		age:        app.age.int()
		country:    app.country.selected_value()
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

fn (app &State) draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	marginx, marginy := 20, 20
	for i, user in app.users {
		y := marginy + i * cell_height
		// Outer border
		c.draw_device_rect_empty(d, marginx, y, table_width, cell_height, gx.gray)
		// Vertical separators
		c.draw_device_line(d, cell_width, y, cell_width, y + cell_height, gx.gray)
		c.draw_device_line(d, cell_width * 2, y, cell_width * 2, y + cell_height, gx.gray)
		c.draw_device_line(d, cell_width * 3, y, cell_width * 3, y + cell_height, gx.gray)
		// Text values
		c.draw_device_text(d, marginx + 5, y + 5, user.first_name)
		c.draw_device_text(d, marginx + 5 + cell_width, y + 5, user.last_name)
		c.draw_device_text(d, marginx + 5 + cell_width * 2, y + 5, user.age.str())
		c.draw_device_text(d, marginx + 5 + cell_width * 3, y + 5, user.country)
	}
}
