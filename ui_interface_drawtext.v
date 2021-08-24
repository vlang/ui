module ui

import gx
import os
import sokol.sgl

pub struct TextStyle {
mut:
	font_name 		string
	color          	gx.Color = gx.black
	size           	int   = 16
	align          	gx.HorizontalAlign = .left
	vertical_align 	gx.VerticalAlign   = .top
	mono           	bool
	// To define text style id/name
	text_style_id 	string
}

pub struct TextStyles {
mut:
	cfgs		map[string]TextStyle
}

// Sort of shareable FontSets between DrawTextWidget via ui field
struct FontSet {
mut:
	fonts 		map[string]int
}

pub fn (mut ui UI) add_font(font_name string, font_path string) {
	println("add font $font_name at $font_path")
	bytes := os.read_bytes(font_path) or { []byte{} }
	// gg := ui.gg
	// mut f := ui.fonts 
	if bytes.len > 0 {
		font := C.fonsAddFontMem(ui.gg.ft.fons, c'sans', bytes.data, bytes.len, false)
		if font > 0 {
			ui.fonts.fonts[font_name] = font
			println("font $font $font_name added ($font_path)")
		} else {
			println("font $font_name NOT added ($font_path)")
		}
	}
	println("$ui.fonts")
}

pub interface DrawTextWidget {
mut:
	ui 				&UI
	text_styles		TextStyles
	text_style_id  	string
}

pub fn (mut w DrawTextWidget) add_font(font_name string, font_path string) {	
	w.ui.add_font(font_name, font_path)
}

// define style to be used with drawtext
pub fn (mut w DrawTextWidget) add_style(ts TextStyle) {
	if ts.text_style_id == '' {
		eprintln("Warning: nothing done in set_style since text_style_id is missing")
		return
	}
	w.text_styles.cfgs[ts.text_style_id] = TextStyle{
		font_name:  ts.font_name
		color: ts.color  
		size: ts.size 
		align: ts.align 
		vertical_align: ts.vertical_align 
		mono: ts.mono
	}
}

pub fn (mut w DrawTextWidget) set_style(text_style_id string) {
	w.text_style_id = text_style_id
}

pub fn (w DrawTextWidget) load_style() {
	if w.text_style_id == "" {
		println("warning: text_style_id needs to be specified ")
	}
	ts := w.text_styles.cfgs[w.text_style_id]
	// println("select style $w.text_style_id $ts")
	gg := w.ui.gg
	fons := gg.ft.fons
	// println("$w.ui.fonts.fonts")
	// println("font ${w.ui.fonts.fonts[ts.font_name]} loaded")
	fons.set_font(w.ui.fonts.fonts[ts.font_name])

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

pub fn (w DrawTextWidget) drawtext(x int, y int, text string) {
	if w.text_style_id != "" {
		w.load_style()
		scale := if w.ui.gg.ft.scale == 0 { f32(1) } else { w.ui.gg.ft.scale }
		C.fonsDrawText(w.ui.gg.ft.fons, x * scale, y * scale, &char(text.str), 0) // TODO: check offsets/alignment
	}
}
