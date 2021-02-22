module ui

import gx

// text_size: f64
//   0  (default)  => system
//   16 (or 16.)   => fixed font size
//   .5 (in ]0,1]) => proprtion of height window

fn text_size_as_int(size f64, win_height int) int {
	return if size > 0 && size < 1 {
		// println("tsai: ${int(size * win_height)} = $size * $win_height")
		int(size * win_height)
	} else if size == int(size) {
		int(size)
	} else {
		0
	}
}

const (
	empty_text_cfg = gx.TextCfg{}
)

fn is_empty_text_cfg(t gx.TextCfg) bool {
	return t.str() == ui.empty_text_cfg.str()
}

// Declare Textable widget to be resizable or not
fn set_text_fixed(mut child Widget, width_type ChildSize, height_type ChildSize) {
	// println('set_text_fixed: $child.type_name(): $width_type $height_type')
	if child is Button {
		child.fixed_text = (width_type in [.fixed, .compact]) || (height_type in [.fixed, .compact])
	} else if child is Label {
		child.fixed_text = (width_type in [.fixed, .compact]) || (height_type in [.fixed, .compact])
	} else if child is Radio {
		child.fixed_text = (width_type in [.fixed, .compact]) || (height_type in [.fixed, .compact])
	} else if child is TextBox {
		child.fixed_text = (width_type in [.fixed, .compact]) || (height_type in [.fixed, .compact])
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
		text_size := int(f64(tc.size) * window.text_scale)
		tc2 := gx.TextCfg{
			...tc
			size: text_size
		}
		// println("draw_text: ($x, $y) ${text_size} ${tc.size} ${window.text_scale}")
		w.ui.gg.draw_text(x, y, text_, tc2)
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

// more than one function could be introduced if the widget 
// contains several text to draw with different styles.
fn (t &TextBox) draw_text(x int, y int, text_ string) {
	window := t.ui.window
	tc := t.text_cfg
	if t.fixed_text {
		t.ui.gg.draw_text(x, y, text_, tc)
	} else {
		// println("draw_text: ${int(tc.size * window.text_scale)} ${tc.size} ${window.text_scale}")
		t.ui.gg.draw_text(x, y, text_, gx.TextCfg{
			...tc
			size: int(tc.size * window.text_scale)
		})
	}
}
