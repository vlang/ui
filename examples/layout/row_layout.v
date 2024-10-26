import ui
import gx

const win_width = 1200
const win_height = 500
const btn_width = 200
const btn_height = 30
const port = 1337
const lb_height = 0

@[heap]
struct App {
mut:
	sizes map[string]f64
}

fn main() {
	mut app := &App{}
	app.sizes = {
		'100':            100.0
		'20':             20.0
		'.3':             .3
		'ui.stretch':     ui.stretch
		'1.5*ui.stretch': 1.5 * ui.stretch
		'2*ui.stretch':   2 * ui.stretch
		'3*ui.stretch':   3 * ui.stretch
	}
	window := ui.window(
		width:     win_width
		height:    win_height
		title:     'Stack widths and heights management'
		mode:      .resizable
		on_resize: win_resize
		on_init:   win_init
		layout:    ui.column(
			heights:  [ui.compact, ui.compact, ui.stretch]
			spacing:  .01
			children: [
				ui.row(
					widths:   ui.compact
					heights:  ui.compact
					margin_:  5
					spacing:  .03
					children: [
						ui.row(
							id:       'row_btn1'
							title:    'btn1'
							margin_:  .05
							spacing:  .1
							widths:   ui.compact
							heights:  ui.compact
							children: [
								ui.listbox(
									id:        'lb1w'
									height:    lb_height
									selection: 0
									on_change: app.lb_change
									items:     {
										'.3':             '.3'
										'100':            '100'
										'ui.stretch':     'ui.stretch'
										'ui.compact':     'ui.compact'
										'1.5*ui.stretch': '1.5 * ui.stretch'
										'2*ui.stretch':   '2 * ui.stretch'
										'3*ui.stretch':   '3 * ui.stretch'
									}
								),
								ui.listbox(
									id:        'lb1h'
									height:    lb_height
									selection: 0
									on_change: app.lb_change
									items:     {
										'.3':         '.3'
										'20':         '20'
										'ui.stretch': 'ui.stretch'
										'ui.compact': 'ui.compact'
									}
								),
							]
						),
						ui.row(
							id:       'row_btn2'
							title:    'btn2'
							margin_:  .05
							spacing:  .1
							widths:   ui.compact
							heights:  ui.compact
							children: [
								ui.listbox(
									id:        'lb2w'
									height:    lb_height
									selection: 1
									on_change: app.lb_change
									items:     {
										'.3':             '.3'
										'100':            '100'
										'ui.stretch':     'ui.stretch'
										'ui.compact':     'ui.compact'
										'1.5*ui.stretch': '1.5 * ui.stretch'
										'2*ui.stretch':   '2 * ui.stretch'
										'3*ui.stretch':   '3 * ui.stretch'
									}
								),
								ui.listbox(
									id:        'lb2h'
									height:    lb_height
									selection: 1
									on_change: app.lb_change
									items:     {
										'.3':         '.3'
										'20':         '20'
										'ui.stretch': 'ui.stretch'
										'ui.compact': 'ui.compact'
									}
								),
							]
						),
						ui.row(
							id:       'row_space'
							title:    'Margins and Spacing'
							margin_:  .05
							spacing:  .1
							widths:   ui.compact
							heights:  ui.compact
							children: [
								ui.listbox(
									id:        'lbmargin'
									height:    lb_height
									selection: 3
									on_change: lb_change_sp
									items:     {
										'20':  'margin_: 20'
										'50':  'margin_: 50'
										'.05': 'margin_: .05'
										'.1':  'margin_: .1'
									}
								),
								ui.listbox(
									id:        'lbspace'
									height:    lb_height
									selection: 3
									on_change: lb_change_sp
									items:     {
										'20':  'spacing: 20'
										'50':  'spacing: 50'
										'.05': 'spacing: .05'
										'.1':  'spacing: .1'
									}
								),
							]
						),
					]
				),
				ui.column(
					margin:   ui.Margin{
						right: .05
						left:  .05
					}
					spacing:  .01
					widths:   ui.stretch
					bg_color: gx.Color{255, 255, 255, 128}
					children: [
						ui.label(
							id:     'l_btns_sizes'
							height: 25
							text:   'Button 1 & 2 declaration: ui.button(width: 200, height: 30, ...)'
						),
						ui.label(
							id:     'l_stack_sizes'
							height: 25
							text:   'Row (Stack) declaration:  ui.row( margin_: 20, spacing: 20, widths: [.3, 100], heights: [.3, ui.compact])'
						),
					]
				),
				ui.row(
					id:       'row'
					widths:   [
						.3,
						100,
					]
					heights:  [
						.3,
						ui.compact,
					]
					margin_:  .1
					spacing:  .1
					bg_color: gx.Color{50, 100, 0, 50}
					children: [
						ui.button(
							id:     'btn1'
							width:  200
							height: 30
							text:   'Button 1'
						),
						ui.button(
							id:     'btn2'
							width:  200
							height: 30
							text:   'Button 2'
						),
					]
				),
			]
		)
	)
	ui.run(window)
}

fn (app &App) lb_change(lb &ui.ListBox) {
	key, _ := lb.selected() or { '100', '' }

	// mut sw, mut sh := lb.size()
	// println('lb_change: ($sw, $sh)')
	win := lb.ui.window

	/*
	row1 := win.stack("row_btn1")
	sw, sh = row1.size()
	print("row_btn1: ($sw, $sh) and ")
	row2 := win.stack("row_btn2")
	sw, sh = row2.size()
	println("row_btn1: ($sw, $sh)")*/

	mut iw, mut ih := -1, -1
	match lb.id {
		'lb1w' {
			iw = 0
		}
		'lb2w' {
			iw = 1
		}
		'lb1h' {
			ih = 0
		}
		'lb2h' {
			ih = 1
		}
		else {}
	}

	mut s := win.get_or_panic[ui.Stack]('row')
	// if mut s is ui.Stack {
	if iw >= 0 {
		if key == 'ui.compact' {
			s.widths[iw] = f32(btn_width)
		} else {
			s.widths[iw] = f32(app.sizes[key])
		}
	}
	if ih >= 0 {
		if key == 'ui.compact' {
			s.heights[ih] = f32(btn_height)
		} else {
			s.heights[ih] = f32(app.sizes[key])
		}
	}
	set_output_label(win)
	win.update_layout()
	set_sizes_labels(win)
	// } else {
	// 	println('$s.type_name()')
	// }
}

fn lb_change_sp(lb &ui.ListBox) {
	key, _ := lb.selected() or { '10', '' }

	win := lb.ui.window
	mut s := win.get_or_panic[ui.Stack]('row')

	match lb.id {
		'lbspace' {
			s.spacings[0] = key.f32()
		}
		'lbmargin' {
			marg := key.f32()
			s.margins.top, s.margins.bottom, s.margins.left, s.margins.right = marg, marg, marg, marg
		}
		else {}
	}

	set_output_label(win)
	win.update_layout()
	set_sizes_labels(win)
}

fn set_output_label(win &ui.Window) {
	lb1w := win.get_or_panic[ui.ListBox]('lb1w')
	lb1h := win.get_or_panic[ui.ListBox]('lb1h')
	lb2w := win.get_or_panic[ui.ListBox]('lb2w')
	lb2h := win.get_or_panic[ui.ListBox]('lb2h')
	mut w1, mut w2, mut h1, mut h2 := '', '', '', ''
	_, w1 = lb1w.selected() or { '100', '' }
	_, w2 = lb2w.selected() or { '100', '' }
	_, h1 = lb1h.selected() or { '100', '' }
	_, h2 = lb2h.selected() or { '100', '' }

	lbm := win.get_or_panic[ui.ListBox]('lbmargin')
	lbs := win.get_or_panic[ui.ListBox]('lbspace')
	_, marg := lbm.selected() or { '100', '' }
	_, sp := lbs.selected() or { '100', '' }
	mut lss := win.get_or_panic[ui.Label]('l_stack_sizes')
	lss.set_text('Row (Stack) declaration: ui.row( ${marg}, ${sp}, widths: [${w1}, ${w2}], heights: [${h1}, ${h2}])')
}

fn set_sizes_labels(win &ui.Window) {
	mut btn1 := win.get_or_panic[ui.Button]('btn1')
	mut row_btn1 := win.get_or_panic[ui.Stack]('row_btn1')
	mut w, mut h := btn1.size()
	row_btn1.title = 'Btn1: (${w}, ${h})'

	mut row_btn2 := win.get_or_panic[ui.Stack]('row_btn2')
	mut btn2 := win.get_or_panic[ui.Button]('btn2')
	w, h = btn2.size()
	row_btn2.title = 'Btn2: (${w}, ${h})'
}

fn win_resize(win &ui.Window, w int, h int) {
	set_sizes_labels(win)
}

fn win_init(win &ui.Window) {
	set_sizes_labels(win)
	mut lb := win.get_or_panic[ui.ListBox]('lb1w')
	sw, sh := lb.size()
	mut row := win.get_or_panic[ui.Stack]('row_btn1')
	rw, rh := row.size()
	println('win init (${sw}, ${sh}) (${row.x}, ${row.y} ,${rw}, ${rh})')
	set_output_label(win)
	win.update_layout()
}
