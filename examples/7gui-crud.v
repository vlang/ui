import ui

struct Person {
	id      string
	name    string
	surname string
}

struct App {
mut:
	people []Person
}

fn main() {
	app := &App{
		people: [
			person('Iron', 'Man'),
			person('Bat', 'Man'),
			person('James', 'Bond'),
			person('Super', 'Man'),
			person('Cat', 'Woman'),
			person('Wonder', 'Woman'),
		]
	}
	window := ui.window(
		width: 400
		height: 300
		title: 'CRUD'
		state: app
		mode: .resizable
		on_init: win_init
		children: [
			ui.column(
				spacing: 5
				margin_: 10
				widths: ui.stretch
				heights: [ui.compact, ui.stretch, ui.compact]
				children: [
					ui.row(
						widths: ui.stretch
						children: [
							ui.row(
								widths: [70.0, ui.stretch]
								children: [ui.label(text: 'Filter prefix:', justify: ui.center_left),
									ui.textbox(id: 'tb_filter', on_changed: on_changed_filter)]
							),
							ui.spacing(),
						]
					),
					ui.row(
						widths: ui.stretch
						children: [
							ui.listbox(
								id: 'lb_people'
							),
							ui.column(
								margin_: 5
								spacing: 5
								heights: ui.compact
								children: [
									ui.row(
										widths: [60.0, ui.stretch]
										children: [ui.label(text: 'Name:', justify: ui.center_left),
											ui.textbox(id: 'tb_name')]
									),
									ui.row(
										widths: [60.0, ui.stretch]
										children: [
											ui.label(
												text: 'Surname:'
												justify: ui.center_left
											),
											ui.textbox(id: 'tb_surname'),
										]
									),
								]
							),
						]
					),
					ui.row(
						margin_: 5
						spacing: 10
						widths: ui.compact
						heights: 30.0
						children: [
							ui.button(
								id: 'btn_create'
								text: 'Create'
								radius: 5
								onclick: btn_create_click
							),
							ui.button(
								id: 'btn_update'
								text: 'Update'
								radius: 5
								onclick: btn_update_click
							),
							ui.button(
								id: 'btn_delete'
								text: 'Delete'
								radius: 5
								onclick: btn_delete_click
							),
						]
					),
				]
			),
		]
	)
	ui.run(window)
}

fn win_init(win &ui.Window) {
	app := &App(win.state)
	mut lb := win.listbox('lb_people')
	update_listbox(mut lb, app, '')
}

fn on_changed_filter(mut tb ui.TextBox, app &App) {
	mut lb := tb.ui.window.listbox('lb_people')
	update_listbox(mut lb, app, *(tb.text))
}

fn btn_create_click(mut app App, btn &ui.Button) {
	tb_filter := btn.ui.window.textbox('tb_filter')
	tb_name := btn.ui.window.textbox('tb_name')
	tb_surname := btn.ui.window.textbox('tb_surname')
	app.people << person(tb_name.text, tb_surname.text)
	mut lb := btn.ui.window.listbox('lb_people')
	update_listbox(mut lb, app, tb_filter.text)
}

fn btn_update_click(mut app App, btn &ui.Button) {
}

fn btn_delete_click(mut app App, btn &ui.Button) {
}

fn update_listbox(mut lb ui.ListBox, app &App, filter string) {
	mut name := ''
	lb.reset()
	for p in app.people {
		name = person_name(p.name, p.surname)
		if filter == '' || name[0..filter.len] == filter {
			lb.add_item(p.id, name)
		}
	}
}

fn person(name string, surname string) Person {
	return Person{id_name(name, surname), name, surname}
}

fn person_name(name string, surname string) string {
	return '$surname, $name'
}

fn id_name(name string, surname string) string {
	return '${name}_$surname'
}
