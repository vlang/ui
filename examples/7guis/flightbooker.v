import ui
import gx
import time

const no_time = time.Time{}

@[heap]
struct App {
mut:
	dd_flight &ui.Dropdown = unsafe { nil }
	tb_oneway &ui.TextBox  = unsafe { nil }
	tb_return &ui.TextBox  = unsafe { nil }
	btn_book  &ui.Button   = unsafe { nil }
}

fn main() {
	app := &App{}
	window := ui.window(
		width:   200
		height:  110
		title:   'Flight booker'
		mode:    .resizable
		on_init: app.win_init
		layout:  ui.column(
			spacing: 5
			margin_: 5
			// widths: ui.stretch
			// heights: ui.stretch
			children: [
				ui.dropdown(
					id:                   'dd_flight'
					z_index:              10
					selected_index:       0
					on_selection_changed: app.dd_change
					items:                [
						ui.DropdownItem{
							text: 'one-way flight'
						},
						ui.DropdownItem{
							text: 'return flight'
						},
					]
				),
				ui.textbox(id: 'tb_oneway', on_change: app.tb_change),
				ui.textbox(id: 'tb_return', read_only: true, on_change: app.tb_change),
				ui.button(
					id:       'btn_book'
					text:     'Book'
					radius:   5
					bg_color: gx.light_gray
					on_click: app.btn_book_click
				),
			]
		)
	)
	ui.run(window)
}

fn (mut app App) win_init(win &ui.Window) {
	app.dd_flight = win.get_or_panic[ui.Dropdown]('dd_flight')
	app.tb_oneway = win.get_or_panic[ui.TextBox]('tb_oneway')
	app.tb_return = win.get_or_panic[ui.TextBox]('tb_return')
	app.btn_book = win.get_or_panic[ui.Button]('btn_book')
	// init dates
	t := time.now()
	date := '${t.day}.${t.month}.${t.year}'
	app.tb_oneway.set_text(date.clone())
	app.tb_return.set_text(date.clone())
}

fn (mut app App) dd_change(dd &ui.Dropdown) {
	match dd.selected().text {
		'one-way flight' {
			app.tb_return.read_only = true
		}
		else {
			app.tb_return.read_only = false
		}
	}
}

fn (mut app App) tb_change(mut tb ui.TextBox) {
	valid := valid_date(tb.text)
	app.btn_book.disabled = !valid
	tb.update_style(
		bg_color: if valid { gx.white } else { gx.orange }
	)
}

fn (app &App) btn_book_click(btn &ui.Button) {
	msg := if app.dd_flight.selected().text == 'one-way flight' {
		'You have booked a one-way flight for ${*(app.tb_oneway.text)}'
	} else {
		'You have booked a return flight from ${*(app.tb_oneway.text)} to ${*(app.tb_return.text)}'
	}
	btn.ui.window.message(msg)
}

fn valid_date(date string) bool {
	mut day, mut month, mut year := 'DDDDD', 'MMMMM', 'YYYYY'
	dmy := date.split('.')
	if dmy.len > 0 {
		day = dmy[0]
	}
	if dmy.len > 1 {
		month = dmy[1]
	}
	if dmy.len > 2 {
		year = dmy[2]
	}
	// YYYY-MM-DD HH:mm:ss
	ts := '${year}-${month}-${day} 00:00:00'
	t := time.parse(ts) or { no_time }
	// println("$t.day/$t.month/$t.year")
	nd := time.days_in_month(t.month, t.year) or { -1 }
	return t != no_time && t.day <= nd
}
