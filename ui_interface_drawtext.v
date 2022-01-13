module ui

import gx
import gg
import os
import sokol.sgl
import sokol.sfons

const no_string = '_none_'

pub enum TextHorizontalAlign {
	@none = -10
	left = C.FONS_ALIGN_LEFT
	center = C.FONS_ALIGN_CENTER
	right = C.FONS_ALIGN_RIGHT
}

pub enum TextVerticalAlign {
	@none = -10
	top = C.FONS_ALIGN_TOP
	middle = C.FONS_ALIGN_MIDDLE
	bottom = C.FONS_ALIGN_BOTTOM
	baseline = C.FONS_ALIGN_BASELINE
}

// Rmk: Some sort of replacement of text stuff inside ui_extra_draw.v
pub interface DrawTextWidget {
	id string
mut:
	ui &UI
	text_styles TextStyles
}

// TextStyle is similar to gg.TextCfg (main difference: font_name and id)
pub struct TextStyle {
pub mut:
	// text style identifier
	id string = ui.no_string
	// fields
	font_name      string   = 'system'
	color          gx.Color = gx.black
	size           int      = 16
	align          TextHorizontalAlign = .left
	vertical_align TextVerticalAlign   = .top
	mono           bool
}

[params]
pub struct TextStyleParams {
	// text style identifier
	id string = ui.no_string
	// fields
	font_name      string   = ui.no_string
	color          gx.Color = no_color
	size           int      = -1
	align          TextHorizontalAlign = .@none
	vertical_align TextVerticalAlign   = .@none
}

pub struct TextStyles {
pub mut:
	current TextStyle
	hash    map[string]TextStyle
}

pub fn (mut w DrawTextWidget) add_font(font_name string, font_path string) {
	w.ui.add_font(font_name, font_path)
}

pub fn (mut w DrawTextWidget) init_style(ts TextStyleParams) {
	w.set_current_style(ts)
}

pub fn (w DrawTextWidget) text_style(ts TextStyleParams) TextStyle {
	ts_ := if ts.id == ui.no_string { w.text_styles.current } else { w.style_by_id(ts.id) }
	return TextStyle{
		...ts_
		size: if ts.size < 0 { ts_.size } else { ts.size }
		font_name: if ts.font_name == ui.no_string { ts_.font_name } else { ts.font_name }
		color: if ts.color == no_color { ts_.color } else { ts.color }
		align: if ts.align == .@none { ts_.align } else { ts.align }
		vertical_align: if ts.vertical_align == .@none {
			ts_.vertical_align
		} else {
			ts.vertical_align
		}
	}
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
	// println(w.text_styles.hash)
}

pub fn (mut w DrawTextWidget) update_style(ts TextStyleParams) {
	mut ts_ := if ts.id in w.text_styles.hash {
		&(w.text_styles.hash[ts.id])
	} else {
		&(w.text_styles.current)
	}
	unsafe {
		*ts_ = TextStyle{
			...(*ts_)
			size: if ts.size < 0 { ts_.size } else { ts.size }
			font_name: if ts.font_name == ui.no_string { ts_.font_name } else { ts.font_name }
			color: if ts.color == no_color { ts_.color } else { ts.color }
			align: if ts.align == .@none { ts_.align } else { ts.align }
			vertical_align: if ts.vertical_align == .@none {
				ts_.vertical_align
			} else {
				ts.vertical_align
			}
		}
	}
}

pub fn (mut w DrawTextWidget) update_text_size(size f64) {
	if size > 0 {
		_, win_height := w.ui.window.size()
		mut ts := w.text_styles.current
		ts.size = text_size_as_int(size, win_height)
	}
}

pub fn (w DrawTextWidget) style_by_id(id string) TextStyle {
	return w.text_styles.hash[id] or { w.ui.text_styles[id] or { w.ui.text_styles['_default_'] } }
}

// current style
pub fn (w DrawTextWidget) current_style() TextStyle {
	return w.text_styles.current
}

pub fn (mut w DrawTextWidget) set_current_style(ts TextStyleParams) {
	w.text_styles.current = w.text_style(ts)
}

pub fn (w DrawTextWidget) load_style() {
	ts := w.current_style()
	// println("current style: $ts")
	w.load_style_(ts)
}

pub fn (w DrawTextWidget) load_style_(ts TextStyle) {
	// println("load style ${w.style_id()} $ts")
	gg := w.ui.gg
	fons := gg.ft.fons
	fons.set_font(w.ui.fonts.hash[ts.font_name])

	scale := if gg.ft.scale == 0 { f32(1) } else { gg.ft.scale }
	size := if ts.mono { ts.size - 2 } else { ts.size }
	fons.set_size(scale * f32(size))
	gg.ft.fons.set_align(int(ts.align) | int(ts.vertical_align))
	color := sfons.rgba(ts.color.r, ts.color.g, ts.color.b, ts.color.a)
	if ts.color.a != 255 {
		sgl.load_pipeline(gg.timage_pip)
	}
	gg.ft.fons.set_color(color)
	ascender := f32(0.0)
	descender := f32(0.0)
	lh := f32(0.0)
	fons.vert_metrics(&ascender, &descender, &lh)
}

pub fn (w DrawTextWidget) font_size() int {
	return w.current_style().size
}

pub fn (w DrawTextWidget) draw_text(x int, y int, text string) {
	scale := if w.ui.gg.ft.scale == 0 { f32(1) } else { w.ui.gg.ft.scale }
	w.ui.gg.ft.fons.draw_text(x * scale, y * scale, text) // TODO: check offsets/alignment
}

pub fn (w DrawTextWidget) draw_styled_text(x int, y int, text string, ts TextStyleParams) {
	w.load_style_(w.text_style(ts))
	scale := if w.ui.gg.ft.scale == 0 { f32(1) } else { w.ui.gg.ft.scale }
	w.ui.gg.ft.fons.draw_text(x * scale, y * scale, text) // TODO: check offsets/alignment
}

pub fn (w DrawTextWidget) text_size(text string) (int, int) {
	return w.ui.gg.text_size(text)
}

pub fn (w DrawTextWidget) text_width(text string) int {
	return w.ui.gg.text_width(text)
}

pub fn (w DrawTextWidget) text_width_additive(text string) f64 {
	ctx := w.ui.gg
	adv := ctx.ft.fons.text_bounds(0, 0, text, &f32(0))
	return adv / ctx.scale
}

pub fn (w DrawTextWidget) text_height(text string) int {
	return w.ui.gg.text_height(text)
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
		font := ui.gg.ft.fons.add_font_mem('sans', bytes, false)
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

pub fn (mut u UI) update_style(ts TextStyleParams) {
	if ts.id in u.text_styles {
		mut ts_ := &(u.text_styles[ts.id])
		unsafe {
			*ts_ = TextStyle{
				...(*ts_)
				size: if ts.size < 0 { ts_.size } else { ts.size }
				font_name: if ts.font_name == ui.no_string { ts_.font_name } else { ts.font_name }
				color: if ts.color == no_color { ts_.color } else { ts.color }
			}
		}
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
		if os.exists('C:/windows/fonts/$font_path') {
			w.ui.add_font(id, 'C:/windows/fonts/$font_path')
		}
	} $else {
		if os.exists(font_path) {
			w.ui.add_font(id, font_path)
		}
	}
}

pub fn (mut w Window) init_styles() {
	w.ui.add_font('system', gg.system_font_path())
	// init default style
	w.ui.add_style(id: '_default_')
}
