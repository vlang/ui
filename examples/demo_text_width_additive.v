import ui
import gx

fn main() {
	win := ui.window(
		width:  1000
		height: 600
		title:  'V UI: Test text_width_additive'
		mode:   .resizable
		layout: ui.column(
			widths:   ui.stretch
			heights:  [ui.compact, ui.stretch]
			margin_:  5
			spacing:  10
			children: [
				ui.textbox(
					id:          'text'
					placeholder: 'Type text here to show textwidth below...'
					text_size:   20
					on_change:   fn (tb_text &ui.TextBox) {
						mut tb := tb_text.ui.window.get_or_panic[ui.TextBox]('info')
						// that's weird text_width is not additive function
						ustr := tb_text.text.runes()
						mut total_twa, mut total_tw, mut total_ts := 0.0, 0.0, 0.0
						mut out := "text_width_additive vs text_width vs text_size:'\n\n"
						for i in 0 .. ustr.len {
							twa := ui.DrawTextWidget(tb).text_width_additive(ustr[i..(i + 1)].string())
							total_twa += twa
							tw := ui.DrawTextWidget(tb).text_width(ustr[i..(i + 1)].string())
							total_tw += tw
							ts, _ := ui.DrawTextWidget(tb).text_size(ustr[i..(i + 1)].string())
							total_ts += ts
							full_twa := ui.DrawTextWidget(tb).text_width_additive(ustr[..i + 1].string())
							full_tw := ui.DrawTextWidget(tb).text_width(ustr[..i + 1].string())
							full_ts, _ := ui.DrawTextWidget(tb).text_size(ustr[..i + 1].string())
							out += '${i}) ${ustr[i..(i + 1)].string()}  (${twa} vs ${tw} vs ${ts})  (${total_twa} == ${full_twa} vs ${total_tw} == ${full_tw} vs ${total_ts} == ${full_ts}) \n'
						}
						tb.set_text(out)
					}
				),
				ui.textbox(
					id:       'info'
					mode:     .multiline | .read_only
					bg_color: gx.hex(0xfcf4e4ff)
					// text: &app.info
					text_size: 24
				),
			]
		)
	)
	ui.run(win)
}
