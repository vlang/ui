module ui

import gx

const (
	empty_text_cfg = gx.TextCfg{}
)

pub fn is_empty_text_cfg(t gx.TextCfg) bool {
	return t.str() == ui.empty_text_cfg.str()
}

//-----  Generic for performance

// T is Widget with text_cfg field
fn text_size<T>(w &T, text string) (int, int) {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_size(text)
}

fn text_width<T>(w &T, text string) int {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_width(text)
}

fn text_height<T>(w &T, text string) int {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_height(text)
}

// T is a widget Type with text_cfg field
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

fn draw_text_with_color<T>(w &T, x int, y int, text_ string, color gx.Color) {
	if w.text_size > 0 {
		_, win_height := w.ui.window.size()
		tc := gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
			color: color
		}
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		tc := gx.TextCfg{
			...w.text_cfg
			color: color
		}
		w.ui.gg.draw_text(x, y, text_, tc)
	}
}

//--------- DrawText interface (for Tooltip and Message)
// Rmk: this can be used for Widget having these fields too

interface DrawText {
	ui &UI
mut:
	text_cfg gx.TextCfg
	text_size f64
}

fn init_text_cfg(mut w DrawText) {
	if is_empty_text_cfg(w.text_cfg) {
		w.text_cfg = w.ui.window.text_cfg
	}
	if w.text_size > 0 {
		_, win_height := w.ui.window.size()
		w.text_cfg = gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
		}
	}
}

// No text_size to not conflict with
fn get_text_size(w DrawText, text_ string) (int, int) {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_size(text_)
}

fn set_text_cfg_color(mut w DrawText, color gx.Color) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		color: color
	}
}

fn set_text_cfg_size(mut w DrawText, size int) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		size: size
	}
}

fn set_text_cfg_style(mut w DrawText, bold bool, italic bool, mono bool) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		bold: bold
		italic: italic
		mono: mono
	}
}

fn set_text_cfg_align(mut w DrawText, align gx.HorizontalAlign) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		align: align
	}
}

fn set_text_cfg_vertical_align(mut w DrawText, align gx.VerticalAlign) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		vertical_align: align
	}
}

// pub fn draw_text_line(w DrawText, x int, y int, text_ string) {
// 	w.ui.gg.draw_text(x, y, text_, w.text_cfg)
// }

// pub fn draw_text_line_with_color(w DrawText, x int, y int, text_ string, color gx.Color) {
// 	tc := gx.TextCfg{
// 		...w.text_cfg
// 		color: color
// 	}
// 	w.ui.gg.draw_text(x, y, text_, tc)
// }

pub fn draw_text_lines(w DrawText, x int, y int, lines []string) {
	mut th := 0
	for line in lines {
		w.ui.gg.draw_text(x, y + th, line, w.text_cfg)
		_, tmp := get_text_size(w, line)
		th += tmp
	}
}

fn update_text_size(mut w DrawText) {
	window := w.ui.window
	_, win_height := window.size()
	if w.text_size > 0 {
		w.text_cfg = gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
		}
	}
}

//------- Futher functions

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

// This a a generic function
fn point_inside<T>(w &T, x f64, y f64) bool {
	wx, wy := w.x + w.offset_x, w.y + w.offset_y
	return x >= wx && x <= wx + w.width && y >= wy && y <= wy + w.height
}
