module ui

import gx

//=== Basic Message Dialog ===/
// Before sokol deals with multiple window (soon)

fn (mut win Window) add_message_dialog() {
	mut dlg := column(
		id: '_msg_dlg_col'
		alignment: .center
		widths: compact
		heights: compact
		spacing: 10
		margin: Margin{5, 5, 5, 5}
		bg_color: gx.Color{140, 210, 240, 100}
		bg_radius: .3
		children: [
			label(id: '_msg_dlg_lab', text: ' Hello World'),
			button(
				id: '_msg_dlg_btn'
				text: 'OK'
				width: 100
				radius: .3
				z_index: 1000
				on_click: message_dialog_click
			),
		]
	)
	dlg.is_root_layout = false
	win.children << dlg
	dlg.set_visible(false)
}

fn message_dialog_click(b &Button) {
	mut dlg := b.ui.window.get_or_panic[Stack]('_msg_dlg_col')
	dlg.set_visible(false)
}

pub fn (win &Window) message(s string) {
	if win.native_message {
		message_box(s)
	} else {
		mut dlg := win.get_or_panic[Stack]('_msg_dlg_col')
		mut msg := win.get_or_panic[Label]('_msg_dlg_lab')
		msg.set_text(s)
		mut tw, mut th := text_lines_size(s.split('\n'), win.ui)
		msg.propose_size(tw, th)
		if tw < 200 {
			tw = 200
		}
		th += 50
		// println("msg: ($tw, $th) $s")
		dlg.propose_size(tw, th)
		ww, wh := win.size()
		dlg.set_pos(ww / 2 - tw / 2, wh / 2 - th / 2)
		dlg.set_visible(true)
		dlg.update_layout()
	}
}

/*
// Playing with Styled Text

struct TextChunk {
	text  string
	start int
	stop  int
	cfg   gx.TextCfg
}

pub struct TextContext {
	chunks []TextChunk
	colors map[string]gx.Color
	styles map[string]gx.TextCfg
}

struct TextView {
	x       int
	y       int
	width   int
	height  int
	context &TextContext = unsafe { nil }
}


* default: {style: "", size: 10, color: black}

* start:

	- style: normal "", italic {i], bold {b], underline {u]
	- size: uint8 (ex: {12])
	- color: r,g,b,a or hexa (0x00000000) string lowercase (ex: {red])
	- font-family: string capitalized

- combined: {...|...|...]

end:

- idem with closing [...} or [...|...|...}
- empty [} means last opened


current:

custom style: blurr

stack of style operations:

{b] {t] [b} [t}
*/
