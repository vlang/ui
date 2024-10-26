import ui

struct Person {
	id      string
	name    string
	surname string
}

@[heap]
struct App {
mut:
	people     []Person
	lb_people  &ui.ListBox = unsafe { nil }
	tb_filter  &ui.TextBox = unsafe { nil }
	tb_name    &ui.TextBox = unsafe { nil }
	tb_surname &ui.TextBox = unsafe { nil }
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
		width:   400
		height:  300
		title:   'CRUD'
		mode:    .resizable
		on_init: app.win_init
		layout:  ui.column(
			spacing:  5
			margin_:  10
			widths:   ui.stretch
			heights:  [ui.compact, ui.stretch, ui.compact]
			children: [
				ui.row(
					widths:   ui.stretch
					children: [
						ui.row(
							widths:   [70.0, ui.stretch]
							children: [ui.label(text: 'Filter prefix:', justify: ui.center_left),
								ui.textbox(id: 'tb_filter', on_change: app.on_change_filter)]
						),
						ui.spacing(),
					]
				),
				ui.row(
					widths:   ui.stretch
					children: [
						ui.listbox(
							id: 'lb_people'
						),
						ui.column(
							margin_:  5
							spacing:  5
							heights:  ui.compact
							children: [
								ui.row(
									widths:   [60.0, ui.stretch]
									children: [ui.label(text: 'Name:', justify: ui.center_left),
										ui.textbox(id: 'tb_name')]
								),
								ui.row(
									widths:   [60.0, ui.stretch]
									children: [
										ui.label(
											text:    'Surname:'
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
					margin_:  5
					spacing:  10
					widths:   ui.compact
					heights:  30.0
					children: [
						ui.button(
							id:       'btn_create'
							text:     'Create'
							radius:   5
							on_click: app.btn_create_click
						),
						ui.button(
							id:       'btn_update'
							text:     'Update'
							radius:   5
							on_click: app.btn_update_click
						),
						ui.button(
							id:       'btn_delete'
							text:     'Delete'
							radius:   5
							on_click: app.btn_delete_click
						),
					]
				),
			]
		)
	)
	ui.run(window)
}

fn (mut app App) win_init(win &ui.Window) {
	// init app fields
	app.lb_people = win.get_or_panic[ui.ListBox]('lb_people')
	app.tb_filter = win.get_or_panic[ui.TextBox]('tb_filter')
	app.tb_name = win.get_or_panic[ui.TextBox]('tb_name')
	app.tb_surname = win.get_or_panic[ui.TextBox]('tb_surname')
	// init listbox content
	app.update_listbox()
}

fn (mut app App) on_change_filter(mut tb ui.TextBox) {
	app.update_listbox()
}

fn (mut app App) btn_create_click(btn &ui.Button) {
	p := person(app.tb_name.text, app.tb_surname.text)
	if p.id !in app.people.map(it.id) {
		app.people << p
	}
	app.update_listbox()
}

fn (mut app App) btn_update_click(btn &ui.Button) {
	app.update_selected_person()
}

fn (mut app App) btn_delete_click(btn &ui.Button) {
	app.delete_selected_person()
}

fn (mut app App) update_listbox() {
	mut name := ''
	filter := *(app.tb_filter.text)
	app.lb_people.reset()
	for p in app.people {
		name = person_name(p.name, p.surname)
		if filter == '' || name[0..filter.len] == filter {
			app.lb_people.add_item(p.id, name)
		}
	}
}

fn (mut app App) update_selected_person() {
	id, _ := app.lb_people.selected_item()
	if id != '' {
		for i, p in app.people {
			if p.id == id {
				app.people[i] = person(app.tb_name.text, app.tb_surname.text)
			}
		}
		app.update_listbox()
	}
}

fn (mut app App) delete_selected_person() {
	id, _ := app.lb_people.selected_item()
	if id != '' {
		for i, p in app.people {
			if p.id == id {
				app.people.delete(i)
			}
		}
		app.update_listbox()
	}
}

fn person(name string, surname string) Person {
	return Person{id_name(name, surname), name, surname}
}

fn person_name(name string, surname string) string {
	return '${surname}, ${name}'
}

fn id_name(name string, surname string) string {
	return '${name}_${surname}'
}
