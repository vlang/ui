module ui

import gx
import toml

// TextBox

pub struct TextBoxShapeStyle {
pub mut:
	bg_radius f32
	bg_color  gx.Color
}

pub struct TextBoxStyle {
	TextBoxShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

[params]
pub struct TextBoxStyleParams {
pub mut:
	style     string = no_style
	bg_radius f32
	bg_color  gx.Color = no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn textbox_style(p TextBoxStyleParams) TextBoxStyleParams {
	return p
}

pub fn (ts TextBoxStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['bg_radius'] = ts.bg_radius
	toml['bg_color'] = hex_color(ts.bg_color)
	return toml.to_toml()
}

pub fn (mut ts TextBoxStyle) from_toml(a toml.Any) {
	ts.bg_radius = a.value('bg_radius').f32()
	ts.bg_color = HexColor(a.value('bg_color').string()).color()
}

fn (mut t TextBox) load_style() {
	// println("pgbar load style $t.theme_style")
	mut style := if t.theme_style == '' { t.ui.window.theme_style } else { t.theme_style }
	if t.style_forced.style != no_style {
		style = t.style_forced.style
	}
	t.update_theme_style(style)
	// forced overload default style
	t.update_style(t.style_forced)
}

pub fn (mut t TextBox) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in t.ui.styles {
		ts := t.ui.styles[style].tb
		t.theme_style = theme
		t.update_shape_theme_style(ts)
		mut dtw := DrawTextWidget(t)
		dtw.update_theme_style(ts)
	}
}

pub fn (mut t TextBox) update_style(p TextBoxStyleParams) {
	t.update_shape_style(p)
	mut dtw := DrawTextWidget(t)
	dtw.update_theme_style_params(p)
}

pub fn (mut t TextBox) update_shape_theme_style(ts TextBoxStyle) {
	t.style.bg_radius = ts.bg_radius
	t.style.bg_color = ts.bg_color
}

pub fn (mut t TextBox) update_shape_style(p TextBoxStyleParams) {
	if p.bg_radius > 0 {
		t.style.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		t.style.bg_color = p.bg_color
	}
}

pub fn (mut t TextBox) update_style_forced(p TextBoxStyleParams) {
	if p.bg_radius > 0 {
		t.style_forced.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		t.style_forced.bg_color = p.bg_color
	}
	mut dtw := DrawTextWidget(t)
	dtw.update_theme_style_params(p)
}
