module libvg

import gx

pub struct SvgTextStyle {
pub mut:
	font_name      string
	font_path      string
	size           int
	color          gx.Color
	align          string
	vertical_align string
}

// TODO: documentation
pub fn svg_text_style() &SvgTextStyle {
	return &SvgTextStyle{}
}

// utility

// TODO: documentation
pub fn (mut ts SvgTextStyle) set_align(align int) {
	ts.align = match align {
		C.FONS_ALIGN_LEFT { 'start' }
		C.FONS_ALIGN_CENTER { 'middle' }
		C.FONS_ALIGN_RIGHT { 'end' }
		else { '' }
	}
}

// TODO: documentation
pub fn (mut ts SvgTextStyle) set_vertical_align(align int) {
	ts.vertical_align = match align {
		C.FONS_ALIGN_BOTTOM { 'text-top' }
		C.FONS_ALIGN_TOP { 'hanging' } // weird
		C.FONS_ALIGN_MIDDLE { 'middle' }
		C.FONS_ALIGN_BASELINE { 'hanging' }
		else { '' }
	}
}

// Color (because of cycle modules copy here)
pub fn hex_color(c gx.Color) string {
	return '#${c.r.hex()}${c.g.hex()}${c.b.hex()}${c.a.hex()}'
}
