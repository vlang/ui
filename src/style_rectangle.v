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
	text_size           int                 = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

@[params]
pub struct RectangleStyleParams {
	WidgetTextStyleParams
pub mut:
	style        string   = no_style
	border_color gx.Color = no_color
	color        gx.Color = no_color
}

pub fn rectangle_style(p RectangleStyleParams) RectangleStyleParams {
	return p
}

pub fn (rects RectangleStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['border_color'] = hex_color(rects.border_color)
	toml_['color'] = hex_color(rects.color)
	toml_['text_font_name'] = rects.text_font_name
	toml_['text_color'] = hex_color(rects.text_color)
	toml_['text_size'] = rects.text_size
	toml_['text_align'] = int(rects.text_align)
	toml_['text_vertical_align'] = int(rects.text_vertical_align)
	return toml_.to_toml()
}

pub fn (mut rects RectangleStyle) from_toml(a toml.Any) {
	rects.border_color = HexColor(a.value('border_color').string()).color()
	rects.color = HexColor(a.value('color').string()).color()
	rects.text_font_name = a.value('text_font_name').string()
	rects.text_color = HexColor(a.value('text_color').string()).color()
	rects.text_size = a.value('text_size').int()
	rects.text_align = unsafe { TextHorizontalAlign(a.value('text_align').int()) }
	rects.text_vertical_align = unsafe { TextVerticalAlign(a.value('text_vertical_align').int()) }
}

pub fn (mut rect Rectangle) load_style() {
	// println("btn load style $rect.theme_style")
	mut style := if rect.theme_style == '' { rect.ui.window.theme_style } else { rect.theme_style }
	if rect.style_params.style != no_style {
		style = rect.style_params.style
	}
	rect.update_theme_style(style)
	// forced overload default style
	rect.update_style(rect.style_params)
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

pub fn (mut rect Rectangle) update_style_params(p RectangleStyleParams) {
	if p.border_color != no_color {
		rect.style_params.border_color = p.border_color
	}
	if p.color != no_color {
		rect.style_params.color = p.color
	}
	mut dtw := DrawTextWidget(rect)
	dtw.update_theme_style_params(p)
}
