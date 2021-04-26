module ui

import gx

const (
	empty_text_cfg = gx.TextCfg{}
)

pub fn is_empty_text_cfg(t gx.TextCfg) bool {
	return t.str() == ui.empty_text_cfg.str()
}

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

fn init_text_cfg<T>(mut w T) {
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

// NB: here as an alternative of generic function that I think is more efficient
// So do we need performance for this task?
// fn point_inside(wid Widget, x f64, y f64) bool {
// 	mut w := wid // because of v fmt issue about interface, size() needs a receiver mutable
// 	width, height := w.size()
// 	wx, wy :=w.x + w.offset_x, w.y + w.offset_y
// 	return x >= wx && x <= wx + width && y >= wy && y <= wy + height
// }

// This a a generic function. This could become a simple function as above
fn point_inside<T>(w &T, x f64, y f64) bool {
	wx, wy := w.x + w.offset_x, w.y + w.offset_y
	return x >= wx && x <= wx + w.width && y >= wy && y <= wy + w.height
}

// DrawText interface

interface DrawText {
	ui &UI
mut:
	text_cfg gx.TextCfg
	text_size f64
}

fn text_size_(w DrawText, text_ string) (int, int) {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_size(text_)
}

fn set_text_color(mut w DrawText, color gx.Color) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		color: color
	}
}

fn set_text_size(mut w DrawText, size int) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		size: size
	}
}

fn set_text_style(mut w DrawText, bold bool, italic bool, mono bool) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		bold: bold
		italic: italic
		mono: mono
	}
}

pub fn draw_text_line(w DrawText, x int, y int, text_ string) {
	w.ui.gg.draw_text(x, y, text_, w.text_cfg)
}

pub fn draw_text_line_with_color(w DrawText, x int, y int, text_ string, color gx.Color) {
	tc := gx.TextCfg{
		...w.text_cfg
		color: color
	}
	w.ui.gg.draw_text(x, y, text_, tc)
}

pub fn draw_text_lines(w DrawText, x int, y int, lines []string) {
	mut th := 0
	for line in lines {
		w.ui.gg.draw_text(x, y + th, line, w.text_cfg)
		_, tmp := text_size_(w, line)
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
