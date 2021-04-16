import ui
import gx

const (
	win_width  = 1200
	win_height = 500
	btn_width  = 200
	btn_height = 30
	port       = 1337
)

struct App {
mut:
	window ui.Window
	sizes  map[string]f64
}

fn main() {
	mut app := &App{}
	app.sizes = map{
		'100':            100.
		'20':             20.
		'.3':             .3
		'ui.stretch':     ui.stretch
		'1.5*ui.stretch': 1.5 * ui.stretch
		'2*ui.stretch':   2 * ui.stretch
		'3*ui.stretch':   3 * ui.stretch
	}
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Stack widths and heights management'
		state: app
		mode: .resizable
		on_resize: win_resize
		on_init: win_init
	}, [
		ui.column({
			heights: [ui.compact, ui.stretch, ui.compact, ui.stretch]
		}, [
			ui.row({
			margin_: .05
			spacings: [.01, .03, .01]
			widths: ui.stretch
		}, [ui.label(id: 'l1w', text: 'Button 1 width:'),
			ui.label(
			id: 'l1h'
			text: 'Button 1 height:'
		),
			ui.label(id: 'l2w', text: 'Button 2 width:'),
			ui.label(
				id: 'l2h'
				text: 'Button 2 height:'
			),
		]),
			ui.row({
				margin_: .05
				spacings: [.01, .03, .01]
				widths: ui.stretch
			}, [
				ui.listbox({
				id: 'lb1w'
				width: 100
				height: 120
				selection: 0
				on_change: lb_change
				// draw_lines: true
			}, map{
				'.3':             '.3'
				'100':            '100'
				'ui.stretch':     'ui.stretch'
				'ui.compact':     'ui.compact'
				'1.5*ui.stretch': '1.5 * ui.stretch'
				'2*ui.stretch':   '2 * ui.stretch'
				'3*ui.stretch':   '3 * ui.stretch'
			}),
				ui.listbox({
					id: 'lb1h'
					width: 100
					height: 120
					selection: 0
					on_change: lb_change
					// draw_lines: true
				}, map{
					'.3':         '.3'
					'20':         '20'
					'ui.stretch': 'ui.stretch'
					'ui.compact': 'ui.compact'
				}),
				ui.listbox({
					id: 'lb2w'
					width: 100
					height: 120
					selection: 1
					on_change: lb_change
					// draw_lines: true
				}, map{
					'.3':             '.3'
					'100':            '100'
					'ui.stretch':     'ui.stretch'
					'ui.compact':     'ui.compact'
					'1.5*ui.stretch': '1.5 * ui.stretch'
					'2*ui.stretch':   '2 * ui.stretch'
					'3*ui.stretch':   '3 * ui.stretch'
				}),
				ui.listbox({
					id: 'lb2h'
					width: 100
					height: 120
					selection: 1
					on_change: lb_change
					// draw_lines: true
				}, map{
					'.3':         '.3'
					'20':         '20'
					'ui.stretch': 'ui.stretch'
					'ui.compact': 'ui.compact'
				}),
			]),
			ui.column({ margin_: .02, spacing: .01, widths: ui.stretch, bg_color: gx.white },
				[
				ui.label(
				id: 'l_btns_sizes'
				height: 25
				text: 'Button 1 & 2 declaration: ui.button({width: 200, height: 30, ...})'
			),
				ui.label(
					id: 'l_stack_sizes'
					height: 25
					text: 'Row (Stack) declaration:  ui.row({ widths: [.3, 100], heights: [.3, ui.compact]})'
				),
			]),
			ui.row({
				id: 'row'
				widths: [.3, 100]
				heights: [.3, ui.compact]
				margin_: .1
				spacing: .1
				bg_color: gx.Color{50, 100, 0, 50}
			}, [
				ui.button(
				id: 'btn1'
				width: 200
				height: 30
				text: 'Button 1'
				//   onclick: btn_connect
			),
				ui.button(
					id: 'btn2'
					width: 200
					height: 30
					text: 'Button 2'
					//   onclick: btn_connect
				),
			]),
		]),
	])
	ui.run(app.window)
}

fn lb_change(app &App, lb &ui.ListBox) {
	id, _ := lb.selected() or { '100', '' }

	win := lb.ui.window
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

	mut s := win.widgets['row']
	if mut s is ui.Stack {
		if iw >= 0 {
			if id == 'ui.compact' {
				s.widths[iw] = f32(btn_width)
			} else {
				s.widths[iw] = f32(app.sizes[id])
			}
		}
		if ih >= 0 {
			if id == 'ui.compact' {
				s.heights[ih] = f32(btn_height)
			} else {
				s.heights[ih] = f32(app.sizes[id])
			}
		}
		set_output_label(win)
		win.update_layout()
		set_sizes_labels(win)
	} else {
		println('$s.type_name()')
	}
}

fn set_output_label(win &ui.Window) {
	lb1w, lb1h, lb2w, lb2h := win.widgets['lb1w'], win.widgets['lb1h'], win.widgets['lb2w'], win.widgets['lb2h']
	mut w1, mut w2, mut h1, mut h2 := '', '', '', ''
	if lb1w is ui.ListBox {
		_, w1 = lb1w.selected() or { '100', '' }
	}
	if lb2w is ui.ListBox {
		_, w2 = lb2w.selected() or { '100', '' }
	}
	if lb1h is ui.ListBox {
		_, h1 = lb1h.selected() or { '100', '' }
	}
	if lb2h is ui.ListBox {
		_, h2 = lb2h.selected() or { '100', '' }
	}
	mut lss := win.widgets['l_stack_sizes']
	if mut lss is ui.Label {
		lss.set_text('Row (Stack) declaration: ui.row({ margin_: .1, spacing: .1, widths: [$w1, $w2], heights: [$h1, $h2]})')
	}
}

fn set_sizes_labels(win &ui.Window) {
	mut l1w, l1h, mut btn1 := win.widgets['l1w'], win.widgets['l1h'], win.widgets['btn1']
	mut w, mut h := btn1.size()
	if mut l1w is ui.Label {
		l1w.set_text('Button 1 width: $w')
	}
	if mut l1h is ui.Label {
		l1h.set_text('Button 1 height: $h')
	}

	mut l2w, l2h, mut btn2 := win.widgets['l2w'], win.widgets['l2h'], win.widgets['btn2']
	w, h = btn2.size()
	if mut l2w is ui.Label {
		l2w.set_text('Button 2 width: $w')
	}
	if mut l2h is ui.Label {
		l2h.set_text('Button 2 height: $h')
	}
}

fn win_resize(w int, h int, win &ui.Window) {
	set_sizes_labels(win)
}

fn win_init(win &ui.Window) {
	set_sizes_labels(win)
	set_output_label(win)
}
