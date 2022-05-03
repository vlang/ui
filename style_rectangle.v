module ui

import gx
import toml

// Rectangle

pub struct RectangleShapeStyle {
pub mut:
	border_color gx.Color // = rect_border_color
	color        gx.Color = transparent
}

pub struct RectangleStyle {
	RectangleShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

[params]
pub struct RectangleStyleParams {
mut:
	style        string   = no_style
	border_color gx.Color = no_color
	color        gx.Color = no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn rectangle_style(p RectangleStyleParams) RectangleStyleParams {
	return p
}

pub fn (rects RectangleStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['border_color'] = hex_color(rects.border_color)
	toml['color'] = hex_color(rects.color)
	toml['text_font_name'] = rects.text_font_name
	toml['text_color'] = hex_color(rects.text_color)
	toml['text_size'] = rects.text_size
	toml['text_align'] = int(rects.text_align)
	toml['text_vertical_align'] = int(rects.text_vertical_align)
	return toml.to_toml()
}

pub fn (mut rects RectangleStyle) from_toml(a toml.Any) {
	rects.border_color = HexColor(a.value('border_color').string()).color()
	rects.color = HexColor(a.value('color').string()).color()
	rects.text_font_name = a.value('text_font_name').string()
	rects.text_color = HexColor(a.value('text_color').string()).color()
	rects.text_size = a.value('text_size').int()
	rects.text_align = TextHorizontalAlign(a.value('text_align').int())
	rects.text_vertical_align = TextVerticalAlign(a.value('text_vertical_align').int())
}

pub fn (mut rect Rectangle) load_style() {
	// println("btn load style $rect.theme_style")
	mut style := if rect.theme_style == '' { rect.ui.window.theme_style } else { rect.theme_style }
	if rect.style_forced.style != no_style {
		style = rect.style_forced.style
	}
	rect.update_theme_style(style)
	// forced overload default style
	rect.update_style(rect.style_forced)
}

pub fn (mut rect Rectangle) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in rect.ui.styles {
		rects := rect.ui.styles[style].rect
		rect.theme_style = theme
		rect.update_shape_theme_style(rects)
		mut dtw := DrawTextWidget(rect)
		dtw.update_theme_style(rects)
	}
}

pub fn (mut rect Rectangle) update_style(p RectangleStyleParams) {
	rect.update_shape_style(p)
	mut dtw := DrawTextWidget(rect)
	dtw.update_theme_style_params(p)
}

fn (mut rect Rectangle) update_shape_theme_style(rects RectangleStyle) {
	rect.style.border_color = rects.border_color
	rect.style.color = rects.color
}

fn (mut rect Rectangle) update_shape_style(p RectangleStyleParams) {
	if p.border_color != no_color {
		rect.style.border_color = p.border_color
	}
	if p.color != no_color {
		rect.style.color = p.color
	}
}

fn (mut rect Rectangle) update_style_forced(p RectangleStyleParams) {
	if p.border_color != no_color {
		rect.style_forced.border_color = p.border_color
	}
	if p.color != no_color {
		rect.style_forced.color = p.color
	}
	mut dtw := DrawTextWidget(rect)
	dtw.update_theme_style_params(p)
}
