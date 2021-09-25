module ui

import gx
import os
import sokol.sgl

const no_string = '_none_'

// Rmk: Some sort of replacement of text stuff inside ui_extra_draw.v
pub interface DrawTextWidget {
	id string
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

pub fn (w DrawTextWidget) font_size() int {
	return w.text_style().size
}

// Usage:
// set_text_style(id: "id") where "id" defined as a style locally or inside w.ui
// set_text_style(font_name: ..., size: ..., color: ..., )
pub fn (mut w DrawTextWidget) set_text_style(ts TextStyle) {
	ts2 := w.text_styles.hash[ts.id] or { w.ui.text_styles[ts.id] or { ts } }
	w.text_styles.current = ts2
}

pub fn (mut w DrawTextWidget) update_text_style(ts TextStyleConfig) {
	mut ts_ := if ts.id == ui.no_string {
		&(w.text_styles.current)
	} else if ts.id in w.text_styles.hash {
		&(w.text_styles.hash[ts.id])
	} else if ts.id in w.ui.text_styles {
		&(w.ui.text_styles[ts.id])
	} else {
		&(w.text_styles.current)
	}
	unsafe {
		*ts_ = TextStyle{
			...(*ts_)
			size: if ts.size < 0 { ts_.size } else { ts.size }
			font_name: if ts.font_name == ui.no_string { ts_.font_name } else { ts.font_name }
			color: if ts.color == no_color { ts_.color } else { ts.color }
		}
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

// TextStyle is similar to gg.TextCfg (main difference: font_name and id)
// Also, thanks to text_style_id, it can be used as an OptionConfig
pub struct TextStyle {
pub mut:
	// text style identifier
	id string = ui.no_string
	// fields
	font_name      string
	color          gx.Color = gx.black
	size           int      = 16
	align          gx.HorizontalAlign = .left
	vertical_align gx.VerticalAlign   = .top
	mono           bool
}

[params]
pub struct TextStyleConfig {
	// text style identifier
	id string = ui.no_string
	// fields
	font_name string   = ui.no_string
	color     gx.Color = no_color
	size      int      = -1
}

pub struct TextStyles {
pub mut:
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
	// IMPORTANT: This fix issue that makes DrawTextFont not working for fontstash
	// (in fons__getGlyph, added becomes 0)
	ui.gg.ft.fons.reset_atlas(512, 512)
	bytes := os.read_bytes(font_path) or { []byte{} }
	// gg := ui.gg
	// mut f := ui.fonts
	if bytes.len > 0 {
		font := ui.gg.ft.fons.add_font_mem(c'sans', bytes.data, bytes.len, 0)
		if font >= 0 {
			ui.fonts.hash[font_name] = font
			$if fontset ? {
				println('font $font $font_name added ($font_path)')
			}
		} else {
			$if fontset ? {
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

pub fn font_path_list() []string {
	mut font_root_path := ''
	$if windows {
		font_root_path = 'C:/windows/fonts'
	}
	$if macos {
		font_root_path = '/System/Library/Fonts/*'
	}
	$if linux {
		font_root_path = '/usr/share/fonts/truetype/*'
	}
	$if android {
		font_root_path = '/system/fonts/*'
	}
	font_paths := os.glob('$font_root_path/*.ttf') or { panic(err) }
	return font_paths
}

// font_path differs depending on os
pub fn (mut w Window) add_font(id string, font_path string) {
	$if windows {
		w.ui.add_font(id, 'C:/windows/fonts/$font_path')
	} $else {
		w.ui.add_font(id, font_path)
	}
}
