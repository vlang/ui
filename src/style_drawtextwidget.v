module ui

import gx

// Embedded in most Widget Styles

pub struct WidgetTextStyle {
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .center
	text_vertical_align TextVerticalAlign   = .middle
}

[params]
pub struct WidgetTextStyleParams {
pub mut:
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

// Style with Text

interface DrawTextWidgetStyle {
mut:
	text_font_name string
	text_color gx.Color
	text_size int
	text_align TextHorizontalAlign
	text_vertical_align TextVerticalAlign
}

interface DrawTextWidgetStyleParams {
	text_font_name string
	text_color gx.Color
	text_size f64
	text_align TextHorizontalAlign
	text_vertical_align TextVerticalAlign
}

pub fn (mut dtw DrawTextWidget) update_theme_style(ds DrawTextWidgetStyle) {
	dtw.update_style(
		font_name: ds.text_font_name
		color: ds.text_color
		size: ds.text_size
		align: ds.text_align
		vertical_align: ds.text_vertical_align
	)
}

pub fn (mut dtw DrawTextWidget) update_theme_style_params(ds DrawTextWidgetStyleParams) {
	if ds.text_size > 0 {
		dtw.update_text_size(ds.text_size)
	}
	mut ts, mut ok := TextStyleParams{}, false
	if ds.text_font_name != '' {
		ok = true
		ts.font_name = ds.text_font_name
	}
	if ds.text_color != no_color {
		ok = true
		ts.color = ds.text_color
	}
	if ds.text_align != .@none {
		ok = true
		ts.align = ds.text_align
	}
	if ds.text_vertical_align != .@none {
		ok = true
		ts.vertical_align = ds.text_vertical_align
	}
	if ok {
		dtw.update_style(ts)
	}
}
