module libvg

import x.ttf
import os

// TODO: documentation
pub fn (mut r Raster) attach_bitmap() {
	bmp := ttf.BitMap{
		tf:       unsafe { nil }
		buf:      r.data.data
		buf_size: r.width * r.height * r.channels
		width:    r.width
		height:   r.height
		bp:       r.channels
		// space_cw: 1.0
		// space_mult: 1.0/16.0
		// use_font_metrics: false
		// justify: true
		// justify_fill_ratio: 0.75
	}
	r.bmp = &bmp
}

// TODO: documentation
pub fn (mut r Raster) add_ttf(ttf_filename string) {
	mut ttf_font := ttf.TTF_File{}
	ttf_font.buf = os.read_bytes(ttf_filename) or { panic(err) }
	ttf_font.init()
	r.ttf_fonts[ttf_filename] = ttf_font
}

// TODO: documentation
pub fn (mut r Raster) attach_ttf(ttf_filename string) {
	the_font_ptr := r.ttf_fonts[ttf_filename]
	r.ttf_font = &the_font_ptr
	r.bmp.tf = r.ttf_font
}

// TODO: documentation
pub fn (r &Raster) get_info_string() {
	// print font info
	println(r.ttf_font.get_info_string())
}

@[params]
pub struct SetFontSizeParams {
pub:
	font_size  int
	device_dpi int = 72
}

// TODO: documentation
pub fn (mut r Raster) set_font_size(p SetFontSizeParams) {
	// Formula for scale calculation
	// scaler := (font_size * device dpi) / (72dpi * em_unit)
	scale := f32(p.font_size * p.device_dpi) / f32(72 * r.ttf_font.units_per_em)
	r.bmp.scale = scale
}

// TODO: documentation
pub fn (mut r Raster) init_style(ts BitmapTextStyle) {
	r.attach_ttf(ts.font_path)
	r.init_filler()
	r.set_font_size(font_size: ts.size, device_dpi: 72)
	r.color = ts.color
	r.bmp.justify = false // true
	r.bmp.align = .left
	r.style = .filled
}

// TODO: documentation
pub fn (r &Raster) get_y_base() f32 {
	// height of the font to use in the buffer to separate the lines
	y_base := f32((r.ttf_font.y_max - r.ttf_font.y_min) * r.bmp.scale)
	return y_base
}
