import ui
import gx

struct App {
mut:
	window &ui.Window = unsafe { nil }
	text   string
	info   string
}

fn main() {
	mut app := &App{}
	mut s := ''
	for i in 0 .. 100 {
		s += 'line (${i})'.repeat(5)
		s += '\n'
	}
	app.text = s
	app.window = ui.window(
		width:   800
		height:  600
		title:   'V UI: Scrollview'
		mode:    .resizable
		on_init: fn (win &ui.Window) {
			$if test_textwidth ? {
				mut tb := win.get_or_panic[ui.TextBox]('info')
				tb.tv.test_textwidth('abcdefghijklmnrputwxyz &éèdzefzefzef')
			}
		}
		layout:  ui.row(
			widths:   ui.stretch
			heights:  ui.stretch
			children: [
				ui.textbox(
					id:        'info'
					mode:      .multiline | .read_only
					text:      &app.info
					text_size: 24
				),
				ui.textbox(
					id:               'text'
					mode:             .multiline | .read_only
					bg_color:         gx.hex(0xfcf4e4ff)
					text:             &app.text
					text_size:        24
					on_scroll_change: on_scroll_change
				),
			]
		)
	)
	ui.run(app.window)
}

fn on_scroll_change(sw ui.ScrollableWidget) {
	mut tb := sw.ui.window.get_or_panic[ui.TextBox]('info')
	mut s := ''
	sv := sw.scrollview
	ox, oy := sv.orig_xy()
	s += 'textbox ${sw.id} has scrollview? ${sw.has_scrollview}'
	s += '\nat (${sw.x}, ${sw.y}) orig: (${ox}, ${oy})'
	s += '\nwith scrollview offset: (${sv.offset_x}, ${sv.offset_y})'
	s += '\nwith btn: (${sv.btn_x}, ${sv.btn_y})'
	tb.set_text(s)
}
