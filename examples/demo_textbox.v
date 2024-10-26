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
		tb1:  'hggyjgyguguglul'
		tb2m: 'toto bbub jhuui jkhuhui hubhuib\ntiti tutu toto\ntata tata'.repeat(1000)
		tb3m: 'toto bbub jhuui jkhuhui hubhuib\ntiti tutu toto\ntata tata'.repeat(3)
	}
	lines := app.tb2m.split('\n')
	mut s := ''
	for l in lines {
		s += '${l}\n'
	}
	app.tb2m = s
	c := ui.column(
		widths:   ui.stretch
		heights:  [ui.compact, ui.compact, ui.stretch, ui.stretch, ui.stretch]
		margin_:  5
		spacing:  10
		children: [
			ui.textbox(
				id:            'tb1'
				text:          &app.tb1
				fitted_height: true
			),
			ui.row(
				spacing:  5
				children: [
					ui.label(text: 'Word wrap'),
					ui.switcher(open: false, id: 'sw2', on_click: on_switch_click),
					ui.switcher(open: false, id: 'sw2bis', on_click: on_switch_click),
					ui.switcher(open: false, id: 'sw3', on_click: on_switch_click),
				]
			),
			ui.textbox(
				mode:      .multiline
				id:        'tb2m'
				text:      &app.tb2m
				height:    200
				text_size: 24
				bg_color:  gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
			),
			ui.textbox(
				mode:             .read_only | .multiline
				id:               'tb2m-bis'
				text:             &app.tb2m
				height:           200
				text_size:        24
				on_scroll_change: on_scroll_change
			),
			ui.textbox(
				mode:       .read_only | .multiline
				scrollview: false
				id:         'tb3m'
				text:       &app.tb3m
				height:     200
				text_size:  24
			),
		]
	)
	w := ui.window(
		width:  500
		height: 300
		mode:   .resizable
		layout: c
	)
	ui.run(w)
}

fn on_switch_click(switcher &ui.Switch) {
	tbs := match switcher.id {
		'sw2' { 'tb2m' }
		'sw2bis' { 'tb2m-bis' }
		else { 'tb3m' }
	}
	mut tb := switcher.ui.window.get_or_panic[ui.TextBox](tbs)
	tb.tv.switch_wordwrap()
}

fn on_scroll_change(sw ui.ScrollableWidget) {
	// println('sw cb example: $sw.id has scrollview? $sw.has_scrollview with x: $sw.x and y: $sw.y')
}
