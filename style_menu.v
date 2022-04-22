module ui

import gx
import toml

// Menu

pub struct MenuShapeStyle {
pub mut:
	border_color gx.Color = menu_border_color
	bg_color     gx.Color = menu_bg_color
}

pub struct MenuStyle {
	MenuShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

[params]
pub struct MenuStyleParams {
mut:
	style        string   = no_style
	border_color gx.Color = no_color
	bg_color     gx.Color = no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn menu_style(p MenuStyleParams) MenuStyleParams {
	return p
}

pub fn (ms MenuStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['border_color'] = hex_color(ms.border_color)
	toml['bg_color'] = hex_color(ms.bg_color)
	toml['text_font_name'] = ms.text_font_name
	toml['text_color'] = hex_color(ms.text_color)
	toml['text_size'] = ms.text_size
	toml['text_align'] = int(ms.text_align)
	toml['text_vertical_align'] = int(ms.text_vertical_align)
	return toml.to_toml()
}

pub fn (mut ms MenuStyle) from_toml(a toml.Any) {
	ms.border_color = HexColor(a.value('border_color').string()).color()
	ms.bg_color = HexColor(a.value('bg_color').string()).color()
	ms.text_font_name = a.value('text_font_name').string()
	ms.text_color = HexColor(a.value('text_color').string()).color()
	ms.text_size = a.value('text_size').int()
	ms.text_align = TextHorizontalAlign(a.value('text_align').int())
	ms.text_vertical_align = TextVerticalAlign(a.value('text_vertical_align').int())
}

pub fn (mut m Menu) load_style() {
	// println("btn load style $m.theme_style")
	mut style := if m.theme_style == '' { m.ui.window.theme_style } else { m.theme_style }
	if m.style_forced.style != no_style {
		style = m.style_forced.style
	}
	m.update_theme_style(style)
	// forced overload default style
	m.update_style(m.style_forced)
}

pub fn (mut m Menu) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in m.ui.styles {
		ms := m.ui.styles[style].menu
		m.theme_style = theme
		m.update_shape_theme_style(ms)
		mut dtw := DrawTextWidget(m)
		dtw.update_theme_style(ms)
	}
}

pub fn (mut m Menu) update_style(p MenuStyleParams) {
	m.update_shape_style(p)
	mut dtw := DrawTextWidget(m)
	dtw.update_theme_style_params(p)
}

fn (mut m Menu) update_shape_theme_style(ms MenuStyle) {
	m.style.border_color = ms.border_color
	m.style.bg_color = ms.bg_color
}

fn (mut m Menu) update_shape_style(p MenuStyleParams) {
	if p.border_color != no_color {
		m.style.border_color = p.border_color
	}
	if p.bg_color != no_color {
		m.style.bg_color = p.bg_color
	}
}

fn (mut m Menu) update_style_forced(p MenuStyleParams) {
	if p.border_color != no_color {
		m.style_forced.border_color = p.border_color
	}
	if p.bg_color != no_color {
		m.style_forced.bg_color = p.bg_color
	}
	mut dtw := DrawTextWidget(m)
	dtw.update_theme_style_params(p)
}
