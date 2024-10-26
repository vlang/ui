module ui

import gx
import toml

// Radio

pub struct RadioShapeStyle {
pub mut:
	radio_mode   string = 'radio' // or "radio_white" and maybe one day "square" and "square_white"
	border_color gx.Color
	bg_color     gx.Color = gx.white
}

pub struct RadioStyle {
	RadioShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int                 = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

@[params]
pub struct RadioStyleParams {
	WidgetTextStyleParams
pub mut:
	style        string   = no_style
	border_color gx.Color = no_color
	bg_color     gx.Color = no_color
	radio_mode   string
}

pub fn radio_style(p RadioStyleParams) RadioStyleParams {
	return p
}

pub fn (rs RadioStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['border_color'] = hex_color(rs.border_color)
	toml_['bg_color'] = hex_color(rs.bg_color)
	toml_['radio_mode'] = rs.radio_mode
	toml_['text_font_name'] = rs.text_font_name
	toml_['text_color'] = hex_color(rs.text_color)
	toml_['text_size'] = rs.text_size
	toml_['text_align'] = int(rs.text_align)
	toml_['text_vertical_align'] = int(rs.text_vertical_align)
	return toml_.to_toml()
}

pub fn (mut rs RadioStyle) from_toml(a toml.Any) {
	rs.border_color = HexColor(a.value('border_color').string()).color()
	rs.bg_color = HexColor(a.value('bg_color').string()).color()
	rs.radio_mode = a.value('radio_mode').string()
	rs.text_font_name = a.value('text_font_name').string()
	rs.text_color = HexColor(a.value('text_color').string()).color()
	rs.text_size = a.value('text_size').int()
	rs.text_align = unsafe { TextHorizontalAlign(a.value('text_align').int()) }
	rs.text_vertical_align = unsafe { TextVerticalAlign(a.value('text_vertical_align').int()) }
}

pub fn (mut r Radio) load_style() {
	// println("btn load style $r.theme_style")
	mut style := if r.theme_style == '' { r.ui.window.theme_style } else { r.theme_style }
	if r.style_params.style != no_style {
		style = r.style_params.style
	}
	r.update_theme_style(style)
	// forced overload default style
	r.update_style(r.style_params)
	r.ui.radio_selected_image = r.ui.img(r.style.radio_mode + '_selected')
}

pub fn (mut r Radio) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in r.ui.styles {
		rs := r.ui.styles[style].radio
		r.theme_style = theme
		r.update_shape_theme_style(rs)
		mut dtw := DrawTextWidget(r)
		dtw.update_theme_style(rs)
	}
}

pub fn (mut r Radio) update_style(p RadioStyleParams) {
	r.update_shape_style(p)
	mut dtw := DrawTextWidget(r)
	dtw.update_theme_style_params(p)
}

fn (mut r Radio) update_shape_theme_style(rs RadioStyle) {
	r.style.border_color = rs.border_color
	r.style.bg_color = rs.bg_color
	r.style.radio_mode = rs.radio_mode
}

fn (mut r Radio) update_shape_style(p RadioStyleParams) {
	if p.border_color != no_color {
		r.style.border_color = p.border_color
	}
	if p.bg_color != no_color {
		r.style.bg_color = p.bg_color
	}
	if p.radio_mode != '' {
		r.style.radio_mode = p.radio_mode
	}
}

fn (mut r Radio) update_style_params(p RadioStyleParams) {
	if p.border_color != no_color {
		r.style_params.border_color = p.border_color
	}
	if p.bg_color != no_color {
		r.style_params.bg_color = p.bg_color
	}
	if p.radio_mode != '' {
		r.style_params.radio_mode = p.radio_mode
	}
	mut dtw := DrawTextWidget(r)
	dtw.update_theme_style_params(p)
}
