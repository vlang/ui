module ui

import gx

// pub type TextCfg = gx.TextCfg

const(
	empty_text_cfg = gx.TextCfg{}
)

fn is_empty_text_cfg(t gx.TextCfg) bool {
	return t.str() == empty_text_cfg.str()
}

// fn (t TextCfg) as_text_cfg() gx.TextCfg {
// 	match t {
// 		int {
// 			return gx.TextCfg{
// 				size: t
// 			}
// 		}
// 		gx.TextCfg {
// 			return t
// 		}
// 	}
// }

// Declare Textable widget to be resizable or not
pub fn set_text_fixed(mut child Widget, width_type ChildSize, height_type ChildSize) {
	if child is Button {
		child.fixed_text = (width_type in [.fixed, .compact])
			|| (height_type in [.fixed, .compact])
	} else if child is Label {
		child.fixed_text = (width_type in [.fixed, .compact])
			|| (height_type in [.fixed, .compact])
	} else if child is Radio {
		child.fixed_text = (width_type in [.fixed, .compact])
			|| (height_type in [.fixed, .compact])
	} else if child is TextBox {
		child.fixed_placeholder = (width_type in [.fixed, .compact])
			|| (height_type in [.fixed, .compact])
	}
}

// From now since experimental, put the draw_text methods here!
//  Later if adopted, put it in the associated v files.
fn (w &Button) draw_text(x int, y int, text_ string) {
	window := w.ui.window
	tc := w.text_cfg
	if w.fixed_text {
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		// println("draw_text: ${int(tc.size * window.text_scale)} ${tc.size} ${window.text_scale}")
		w.ui.gg.draw_text(x, y, text_, gx.TextCfg{
			...tc
			size: int(tc.size * window.text_scale)
		})
	}
}

fn (w &Label) draw_text(x int, y int, text_ string) {
	window := w.ui.window
	tc := w.text_cfg
	if w.fixed_text {
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		// println("draw_text: ${int(tc.size * window.text_scale)} ${tc.size} ${window.text_scale}")
		w.ui.gg.draw_text(x, y, text_, gx.TextCfg{
			...tc
			size: int(tc.size * window.text_scale)
		})
	}
}

fn (w &Radio) draw_text(x int, y int, text_ string) {
	window := w.ui.window
	tc := w.text_cfg
	if w.fixed_text {
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		// println("draw_text: ${int(tc.size * window.text_scale)} ${tc.size} ${window.text_scale}")
		w.ui.gg.draw_text(x, y, text_, gx.TextCfg{
			...tc
			size: int(tc.size * window.text_scale)
		})
	}
}

fn (t &TextBox) draw_placeholder(x int, y int, text_ string) {
	window := t.ui.window
	tc := t.placeholder_cfg
	if t.fixed_placeholder {
		t.ui.gg.draw_text(x, y, text_, tc)
	} else {
		// println("draw_text: ${int(tc.size * window.text_scale)} ${tc.size} ${window.text_scale}")
		t.ui.gg.draw_text(x, y, text_, gx.TextCfg{
			...tc
			size: int(tc.size * window.text_scale)
		})
	}
}
