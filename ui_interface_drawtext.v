module ui

import gx
import os
import sokol.sgl

// Rmk: Some sort of replacement of text stuff inside ui_extra_draw.v
pub interface DrawTextWidget {
mut:
	ui &UI
	text_styles TextStyles
}

pub fn (mut w DrawTextWidget) add_font(font_name string, font_path string) {
	w.ui.add_font(font_name, font_path)
}

// define style to be used with drawtext method
pub fn (mut w DrawTextWidget) add_style(ts TextStyle) {
	mut id := ts.id
	if id == '' {
		if ts.font_name == '' {
			eprintln('Warning: nothing done in add_style since id or font_name missing')
			return
		}
		id = ts.font_name
	}
	w.text_styles.hash[id] = TextStyle{
		id: id
		font_name: ts.font_name
		color: ts.color
		size: ts.size
		align: ts.align
		vertical_align: ts.vertical_align
		mono: ts.mono
	}
	println(w.text_styles.hash)
}

pub fn (mut w DrawTextWidget) set_text_style(ts TextStyle) {
	if ts.id == 'default' {
		w.text_styles.current = ts
	} else {
		ts2 := w.text_styles.hash[ts.id] or { w.ui.text_styles[ts.id] or { ts } }
		w.text_styles.current = ts2
	}
}

pub fn (w DrawTextWidget) text_style() TextStyle {
	return w.text_styles.current
}

pub fn (w DrawTextWidget) text_style_by_id(id string) TextStyle {
	return w.text_styles.hash[id] or { w.ui.text_styles[id] }
}

pub fn (w DrawTextWidget) load_current_style() {
	ts := w.text_style()
	// println("current style: $ts")
	w.load_style(ts)
}

pub fn (w DrawTextWidget) load_style(ts TextStyle) {
	// println("load style ${w.text_style_id()} $ts")
	gg := w.ui.gg
	fons := gg.ft.fons
	fons.set_font(w.ui.fonts.hash[ts.font_name])

	scale := if gg.ft.scale == 0 { f32(1) } else { gg.ft.scale }
	size := if ts.mono { ts.size - 2 } else { ts.size }
	fons.set_size(scale * f32(size))
	C.fonsSetAlign(gg.ft.fons, int(ts.align) | int(ts.vertical_align))
	color := C.sfons_rgba(ts.color.r, ts.color.g, ts.color.b, ts.color.a)
	if ts.color.a != 255 {
		sgl.load_pipeline(gg.timage_pip)
	}
	C.fonsSetColor(gg.ft.fons, color)
	ascender := f32(0.0)
	descender := f32(0.0)
	lh := f32(0.0)
	fons.vert_metrics(&ascender, &descender, &lh)
}

pub fn (w DrawTextWidget) draw_text(x int, y int, text string) {
	scale := if w.ui.gg.ft.scale == 0 { f32(1) } else { w.ui.gg.ft.scale }
	C.fonsDrawText(w.ui.gg.ft.fons, x * scale, y * scale, &char(text.str), 0) // TODO: check offsets/alignment
}

pub fn (w DrawTextWidget) draw_styled_text(x int, y int, text string, text_style_id string) {
	w.load_style(w.text_style_by_id(text_style_id))
	scale := if w.ui.gg.ft.scale == 0 { f32(1) } else { w.ui.gg.ft.scale }
	C.fonsDrawText(w.ui.gg.ft.fons, x * scale, y * scale, &char(text.str), 0) // TODO: check offsets/alignment
}

// TODO: renamed text_size soon
pub fn (w DrawTextWidget) text_size(text string) (int, int) {
	return w.ui.gg.text_size(text)
}

pub fn (w DrawTextWidget) text_width(text string) int {
	return w.ui.gg.text_width(text)
}

pub fn (w DrawTextWidget) text_height(text string) int {
	return w.ui.gg.text_height(text)
}

// Several structures related to DrawTextWidget interface

// TextStyle is similar to gg.TextCfg (main difference: font_name and text_style_id)
// Also, thanks to text_style_id, it can be used as an OptionConfig
pub struct TextStyle {
mut:
	// text style identifier
	id string = 'default'
	// fields
	font_name      string
	color          gx.Color = gx.black
	size           int      = 16
	align          gx.HorizontalAlign = .left
	vertical_align gx.VerticalAlign   = .top
	mono           bool
}

pub struct TextStyles {
mut:
	current TextStyle
	hash    map[string]TextStyle
}

pub fn (t &TextStyles) style(id string) TextStyle {
	return t.hash[id]
}

// Sort of shareable FontSets between DrawTextWidget via ui field
struct FontSet {
mut:
	hash map[string]int
}

pub fn (mut ui UI) add_font(font_name string, font_path string) {
	$if fontset ? {
		println('add font $font_name at $font_path')
	}
	bytes := os.read_bytes(font_path) or { []byte{} }
	// gg := ui.gg
	// mut f := ui.fonts
	if bytes.len > 0 {
		font := C.fonsAddFontMem(ui.gg.ft.fons, c'sans', bytes.data, bytes.len, false)
		if font > 0 {
			ui.fonts.hash[font_name] = font
			$if fonset ? {
				println('font $font $font_name added ($font_path)')
			}
		} else {
			$if fonset ? {
				println('font $font_name NOT added ($font_path)')
			}
		}
	} else {
		$if fontset ? {
			println('font bytes unreadable')
		}
	}
	$if fontset ? {
		println('$ui.fonts')
	}
}

// define style to be used with drawtext method
pub fn (mut ui UI) add_style(ts TextStyle) {
	mut id := ts.id
	if id == '' {
		if ts.font_name == '' {
			eprintln('Warning: nothing done in add_style since id or font_name missing')
			return
		}
		id = ts.font_name
	}
	ui.text_styles[id] = TextStyle{
		id: id
		font_name: ts.font_name
		color: ts.color
		size: ts.size
		align: ts.align
		vertical_align: ts.vertical_align
		mono: ts.mono
	}
}
