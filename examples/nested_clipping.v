import ui
import gx
import math

const win_width = 500
const win_height = 385
const margin = 10
const spill = 1000

const instructions = ' Click on a box to toggle clipping in boxes'
const instructions2 = ' Use keys 1-4 to toggle clipping in quadrants:'

type ContentFn = fn (int) ui.Widget

fn make_box(id string) ui.Widget {
	return ui.canvas_layout(
		id:          id
		bg_color:    gx.black
		on_draw:     box_draw
		on_mouse_up: box_click
		clipping:    true
	)
}

fn ordinal(i int) string {
	a := i % 10
	if a in [1, 2, 3] {
		if i % 100 !in [11, 12, 13] {
			match a {
				1 { return '${i}st' }
				2 { return '${i}nd' }
				3 { return '${i}rd' }
				else {}
			}
		}
	}
	return '${i}th'
}

fn box_draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	cols := [
		gx.Color{
			r: 128
			g: 16
			b: 0
		},
		gx.Color{
			r: 80
			g: 128
			b: 0
		},
		gx.Color{
			r: 0
			g: 110
			b: 64
		},
		gx.Color{
			r: 0
			g: 64
			b: 100
		},
	]!
	mut col := cols[c.id#[-2..-1].int() - 1]
	f := 1 + (4 - c.id#[-1..].f32()) * 2 / 3
	col.r = u8(math.min(255, int(col.r * f)))
	col.g = u8(math.min(255, int(col.g * f)))
	col.b = u8(math.min(255, int(col.b * f)))
	w, h := c.width - 2 * margin, c.height - 2 * margin
	c.draw_device_rect_filled(d, -spill, margin, w + 2 * spill, h, col)
	c.draw_device_rect_filled(d, margin, -spill, w, h + 2 * spill, col)
	c.draw_device_rect_filled(d, margin, margin, w, h, gx.white)
	order := c.id[1..2].int() * 4 - 4 + c.id[2..3].int() // 'b${q}${b}'
	c.draw_device_text(d, margin + 2, margin + 2, 'drawn: ${ordinal(order)}')
	clip := if c.clipping { 'yes' } else { 'no' }
	c.draw_device_text(d, margin + 2, margin + 2 + 12, 'clip: ${clip}')
}

fn box_click(mut c ui.CanvasLayout, e ui.MouseEvent) {
	if e.button == .left {
		c.clipping = !c.clipping
	}
}

fn make_quad(id string, content_fn ContentFn) ui.Widget {
	return ui.column(
		heights:  ui.stretch
		spacing:  10
		margin_:  10
		id:       id
		children: [
			ui.row(
				spacing:  10
				widths:   ui.stretch
				heights:  ui.stretch
				children: [content_fn(1), content_fn(2)]
			),
			ui.row(
				spacing:  10
				widths:   ui.stretch
				heights:  ui.stretch
				children: [content_fn(3), content_fn(4)]
			),
		]
	)
}

fn win_key(w &ui.Window, e ui.KeyEvent) {
	match e.key {
		._1 {
			mut q := w.get_or_panic[ui.Stack]('q1')
			q.clipping = !q.clipping
		}
		._2 {
			mut q := w.get_or_panic[ui.Stack]('q2')
			q.clipping = !q.clipping
		}
		._3 {
			mut q := w.get_or_panic[ui.Stack]('q3')
			q.clipping = !q.clipping
		}
		._4 {
			mut q := w.get_or_panic[ui.Stack]('q4')
			q.clipping = !q.clipping
		}
		.escape {
			// TODO: w.close() not implemented (no multi-window support yet!)
			if w.ui.dd is ui.DrawDeviceContext {
				w.ui.dd.quit()
			}
		}
		else {}
	}
	update_status(w)
}

fn update_status(w &ui.Window) {
	mut status := instructions2
	for i in 1 .. 5 { // 1...4 doesn't work!?
		mut q := w.get_or_panic[ui.Stack]('q${i}')
		clip := if q.clipping { 'clip' } else { '----' }
		status += ' ${clip}'
	}
	w.get_or_panic[ui.Label]('status').text = status
	//	w.get_widget_by_id_or_panic[ui.Label]('status').text = status
}

fn main() {
	mut win := ui.window(
		width:       win_width
		height:      win_height
		title:       'V nested clipping'
		mode:        .resizable
		on_key_down: win_key
		on_init:     win_init
		layout:      ui.column(
			heights:  [ui.stretch, 15.0, 15.0]
			widths:   ui.stretch
			children: [
				make_quad('', fn (q int) ui.Widget {
					return make_quad('q${q}', fn [q] (b int) ui.Widget {
						return make_box('b${q}${b}')
					})
				}),
				ui.label(
					text: &instructions
				),
				ui.label(
					id:   'status'
					text: &instructions2
				),
			]
		)
	)
	ui.run(win)
}

fn win_init(w &ui.Window) {
	// w.canvas_layout('b11').clipping = false
	// w.canvas_layout('b14').clipping = false
	// w.canvas_layout('b41').clipping = false
	// w.canvas_layout('b44').clipping = false
	// w.get_widget_by_id_or_panic[ui.Stack]('q4').clipping = true
	update_status(w)
}
