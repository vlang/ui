import ui

struct State {
	tb1  string
	tb2m string
}

fn main() {
	mut app := &State{
		tb1: 'hggyjgyguguglul'
		tb2m: 'toto bbub jhuui jkhuhui hubhuib\ntiti tutu toto\ntata tata'
	}
	c := ui.column(
		widths: ui.stretch
		heights: [ui.compact, ui.compact, ui.stretch]
		margin_: 5
		spacing: 10
		children: [
			ui.textbox(
				id: 'tb1'
				text: &app.tb1
			),
			ui.row(
				spacing: 5
				children: [
					ui.label(text: 'Word wrap'),
					ui.switcher(open: true, onclick: on_switch_click),
				]
			),
			ui.textbox(
				is_multiline: true
				is_wordwrap: true
				id: 'tb2m'
				text: &app.tb2m
				height: 200
				text_size: 24
			),
		]
	)
	w := ui.window(
		state: app
		width: 500
		height: 300
		mode: .resizable
		children: [c]
	)
	ui.run(w)
}

fn on_switch_click(mut app voidptr, switcher &ui.Switch) {
	mut tb := switcher.ui.window.textbox('tb2m')
	tb.tv.switch_wordwrap()
	tb.focus()
}
