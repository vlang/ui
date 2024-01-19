module ui

import gx
import toml

// TextBox

pub struct TextBoxShapeStyle {
pub mut:
	bg_radius f32
	bg_color  gx.Color = gx.white
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

@[params]
pub struct TextBoxStyleParams {
	WidgetTextStyleParams
pub mut:
	style     string = no_style
	bg_radius f32
	bg_color  gx.Color = no_color
}

pub fn (ts TextBoxStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['bg_radius'] = ts.bg_radius
	toml_['bg_color'] = hex_color(ts.bg_color)
	return toml_.to_toml()
}

pub fn (mut ts TextBoxStyle) from_toml(a toml.Any) {
	ts.bg_radius = a.value('bg_radius').f32()
	ts.bg_color = HexColor(a.value('bg_color').string()).color()
	ts.text_color = HexColor(a.value('text_color').string()).color()
	if font_name := a.value_opt('text_font_name') { ts.text_font_name = font_name.string() }
	if size := a.value_opt('text_size') { ts.text_size = size.int() }
	if align := a.value_opt('text_align') { ts.text_align = unsafe { TextHorizontalAlign(align.int()) } }
	if vertical_align := a.value_opt('text_vertical_align') { ts.text_vertical_align = unsafe { TextVerticalAlign(vertical_align.int()) } }
}

fn (mut t TextBox) load_style() {
	// println("pgbar load style $t.theme_style")
	mut style := if t.theme_style == '' { t.ui.window.theme_style } else { t.theme_style }
	if t.style_params.style != no_style {
		style = t.style_params.style
	}
	t.apply_theme_style(style)
	// forced overload default style
	t.update_style(t.style_params)
}

pub fn (mut t TextBox) update_theme_style(style string) {
	// println("update_style <$p.style>")
	t.theme_style = style
	t.apply_theme_style(style)
}

fn (mut t TextBox) apply_theme_style(style string) {
	// println("update_style <$p.style>")
	if style != no_style && style in t.ui.styles {
		ts := t.ui.styles[style].tb
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

pub fn (mut t TextBox) update_style_params(p TextBoxStyleParams) {
	if p.bg_radius > 0 {
		t.style_params.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		t.style_params.bg_color = p.bg_color
	}
	mut dtw := DrawTextWidget(t)
	dtw.update_theme_style_params(p)
}
