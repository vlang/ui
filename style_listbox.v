module ui

import gx
import toml

// ListBox

pub struct ListBoxShapeStyle {
pub mut:
	radius           f32
	border_color     gx.Color
	bg_color         gx.Color
	bg_color_pressed gx.Color
	bg_color_hover   gx.Color
}

pub struct ListBoxStyle {
	ListBoxShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .center
	text_vertical_align TextVerticalAlign   = .middle
}

[params]
pub struct ListBoxStyleParams {
	style            string = no_style
	radius           f32
	border_color     gx.Color = no_color
	bg_color         gx.Color = no_color
	bg_color_pressed gx.Color = no_color
	bg_color_hover   gx.Color = no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn listbox_style(p ListBoxStyleParams) ListBoxStyleParams {
	return p
}

pub fn (lbs ListBoxStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['radius'] = lbs.radius
	toml['border_color'] = hex_color(lbs.border_color)
	toml['bg_color'] = hex_color(lbs.bg_color)
	toml['bg_color_pressed'] = hex_color(lbs.bg_color_hover)
	toml['bg_color_hover'] = hex_color(lbs.bg_color_pressed)
	toml['text_font_name'] = lbs.text_font_name
	toml['text_color'] = hex_color(lbs.text_color)
	toml['text_size'] = lbs.text_size
	toml['text_align'] = int(lbs.text_align)
	toml['text_vertical_align'] = int(lbs.text_vertical_align)
	return toml.to_toml()
}

pub fn (mut lbs ListBoxStyle) from_toml(a toml.Any) {
	lbs.radius = a.value('radius').f32()
	lbs.border_color = HexColor(a.value('border_color').string()).color()
	lbs.bg_color = HexColor(a.value('bg_color').string()).color()
	lbs.bg_color_hover = HexColor(a.value('bg_color_pressed').string()).color()
	lbs.bg_color_pressed = HexColor(a.value('bg_color_hover').string()).color()
	lbs.text_font_name = a.value('text_font_name').string()
	lbs.text_color = HexColor(a.value('text_color').string()).color()
	lbs.text_size = a.value('text_size').int()
	lbs.text_align = TextHorizontalAlign(a.value('text_align').int())
	lbs.text_vertical_align = TextVerticalAlign(a.value('text_vertical_align').int())
}

pub fn (mut lb ListBox) load_style() {
	// println("btn load style $lb.theme_style")
	style := if lb.theme_style == '' { lb.ui.window.theme_style } else { lb.theme_style }
	lb.update_style(style: style)
	// forced overload default style
	lb.update_style(lb.style_forced)
}

fn (mut lb ListBox) update_shape_style(lbs ListBoxStyle) {
	lb.style.radius = lbs.radius
	lb.style.border_color = lbs.border_color
	lb.style.bg_color = lbs.bg_color
	lb.style.bg_color_pressed = lbs.bg_color_pressed
	lb.style.bg_color_hover = lbs.bg_color_hover
}

fn (mut lb ListBox) update_shape_style_params(p ListBoxStyleParams) {
	if p.radius > 0 {
		lb.style.radius = p.radius
	}
	if p.border_color != no_color {
		lb.style.border_color = p.border_color
	}
	if p.bg_color != no_color {
		lb.style.bg_color = p.bg_color
	}
	if p.bg_color_pressed != no_color {
		lb.style.bg_color_pressed = p.bg_color_pressed
	}
	if p.bg_color_hover != no_color {
		lb.style.bg_color_hover = p.bg_color_hover
	}
}

pub fn (mut lb ListBox) update_style(p ListBoxStyleParams) {
	// println("update_style <$p.style>")
	style := if p.style == '' { 'default' } else { p.style }
	if style != no_style && style in lb.ui.styles {
		lbs := lb.ui.styles[style].lb
		lb.theme_style = p.style
		lb.update_shape_style(lbs)
		mut dtw := DrawTextWidget(lb)
		dtw.update_theme_style(lbs)
	} else {
		lb.update_shape_style_params(p)
		mut dtw := DrawTextWidget(lb)
		dtw.update_theme_style_params(p)
	}
}
