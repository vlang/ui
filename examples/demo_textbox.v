import ui
import gx

struct State {
mut:
	tb1  string
	tb2m string
	tb3m string
}

fn main() {
	mut app := &State{
		tb1: 'hggyjgyguguglul'
		tb2m: 'toto bbub jhuui jkhuhui hubhuib\ntiti tutu toto\ntata tata'.repeat(1000)
		tb3m: 'toto bbub jhuui jkhuhui hubhuib\ntiti tutu toto\ntata tata'
	}
	lines := app.tb2m.split('\n')
	mut s := ''
	for i, l in lines {
		s += '($i) $l\n'
	}
	app.tb2m = s
	c := ui.column(
		widths: ui.stretch
		heights: [ui.compact, ui.compact, ui.stretch, ui.stretch]
		margin_: 5
		spacing: 10
		children: [
			ui.textbox(
				id: 'tb1'
				text: &app.tb1
				fitted_height: true
			),
			ui.row(
				spacing: 5
				children: [
					ui.label(text: 'Word wrap'),
					ui.switcher(open: true, id: 'sw2', onclick: on_switch_click),
					ui.switcher(open: true, id: 'sw3', onclick: on_switch_click),
				]
			),
			ui.textbox(
				mode: .multiline | .word_wrap
				id: 'tb2m'
				text: &app.tb2m
				height: 200
				text_size: 24
				bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
			),
			ui.textbox(
				mode: .read_only | .multiline | .word_wrap
				id: 'tb3m'
				text: &app.tb2m
				height: 200
				text_size: 24
				on_scroll_change: on_scroll_change
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
	tbs := if switcher.id == 'sw2' { 'tb2m' } else { 'tb3m' }
	mut tb := switcher.ui.window.textbox(tbs)
	tb.tv.switch_wordwrap()
}

fn on_scroll_change(sw ui.ScrollableWidget) {
	println('sw cb example: $sw.id has scrollview? $sw.has_scrollview with x: $sw.x and y: $sw.y')
}
