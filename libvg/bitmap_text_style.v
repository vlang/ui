module libvg

import gx
import x.ttf

pub struct BitmapTextStyle {
pub mut:
	font_name      string
	font_path      string
	size           int
	color          gx.Color
	align          ttf.Text_align
	vertical_align f32
}

// TODO: documentation
pub fn bitmap_text_style() &BitmapTextStyle {
	return &BitmapTextStyle{}
}

// TODO: documentation
pub fn (mut ts BitmapTextStyle) set_align(align int) {
	ts.align = match align {
		C.FONS_ALIGN_LEFT { .left }
		C.FONS_ALIGN_CENTER { .center }
		C.FONS_ALIGN_RIGHT { .right }
		else { .justify }
	}
}

// TODO: documentation
pub fn (mut ts BitmapTextStyle) set_vertical_align(align int) {
	ts.vertical_align = match align {
		C.FONS_ALIGN_BOTTOM { f32(0) }
		C.FONS_ALIGN_TOP { f32(-0.3) }
		C.FONS_ALIGN_MIDDLE { f32(-0.6) }
		C.FONS_ALIGN_BASELINE { f32(0) }
		else { f32(0) }
	}
}
