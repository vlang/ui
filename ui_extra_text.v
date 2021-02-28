module ui

import gx

const (
	empty_text_cfg = gx.TextCfg{}
)

pub fn is_empty_text_cfg(t gx.TextCfg) bool {
	return t.str() == ui.empty_text_cfg.str()
}

fn draw_text<T>(w &T, x int, y int, text_ string) {
	window := w.ui.window
	if w.text_size > 0 {
		_, win_height := window.size()
		tc := gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
		}
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		w.ui.gg.draw_text(x, y, text_, w.text_cfg)
	}
}

// text_size: f64
//   0  (default)  => system
//   16 (or 16.)   => fixed font size
//   .5 (in ]0,1]) => proprtion of height window
pub fn text_size_as_int(size f64, win_height int) int {
	return if size > 0 && size < 1 {
		// println("tsai: ${int(size * win_height)} = $size * $win_height")
		int(size * win_height)
	} else if size == int(size) {
		int(size)
	} else {
		0
	}
}
