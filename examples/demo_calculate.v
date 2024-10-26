import ui
import gx

fn main() {
	win := ui.window(
		width:   500
		height:  300
		mode:    .resizable
		on_init: fn (w &ui.Window) {
			w.calculate('11.0')
		}
		layout:  ui.box_layout(
			children: {
				'rect: (0, 25) -> (1,1)':  ui.rectangle(
					color: gx.orange
				)
				'tb: (0,0) -> (100%, 25)': ui.textbox(
					id:         'tb'
					text_value: '((23.3 + 10) / 4) - 3'
					on_enter:   fn (mut tb ui.TextBox) {
						mut res := ui.Widget(tb).get[ui.Label]('res')
						res.set_text(tb.ui.window.calculate(tb.get_text()).str())
					}
				)
				'res: (0, 30) -> (1,1)':   ui.label(
					id:        'res'
					justify:   ui.center
					text_size: 24
				)
			}
		)
	)
	ui.run(win)
}

// mut mc := tools.mini_calc()
// println(mc.calculate("22.0"))
// println(mc.calculate("3 + 22.0"))
// println(mc.calculate("10.0 + 22/2.0"))
// println(mc.calculate("22.0 / 2 + 10.0"))
// println(mc.calculate("(22.0 + (13 - 5) * 4) / 2 + 10.0"))
