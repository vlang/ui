module ui

import gx
import toml

// Button

pub struct ButtonShapeStyle {
pub mut:
	radius           f32
	border_color     gx.Color
	bg_color         gx.Color
	bg_color_pressed gx.Color
	bg_color_hover   gx.Color
}

pub struct ButtonStyle {
	ButtonShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .center
	text_vertical_align TextVerticalAlign   = .middle
}

[params]
pub struct ButtonStyleParams {
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

pub fn (bs ButtonStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['radius'] = bs.radius
	toml['border_color'] = hex_color(bs.border_color)
	toml['bg_color'] = hex_color(bs.bg_color)
	toml['bg_color_pressed'] = hex_color(bs.bg_color_hover)
	toml['bg_color_hover'] = hex_color(bs.bg_color_pressed)
	toml['text_font_name'] = bs.text_font_name
	toml['text_color'] = hex_color(bs.text_color)
	toml['text_size'] = bs.text_size
	toml['text_align'] = int(bs.text_align)
	toml['text_vertical_align'] = int(bs.text_vertical_align)
	return toml.to_toml()
}

pub fn (mut bs ButtonStyle) from_toml(a toml.Any) {
	bs.radius = a.value('radius').f32()
	bs.border_color = HexColor(a.value('border_color').string()).color()
	bs.bg_color = HexColor(a.value('bg_color').string()).color()
	bs.bg_color_hover = HexColor(a.value('bg_color_pressed').string()).color()
	bs.bg_color_pressed = HexColor(a.value('bg_color_hover').string()).color()
	bs.text_font_name = a.value('text_font_name').string()
	bs.text_color = HexColor(a.value('text_color').string()).color()
	bs.text_size = a.value('text_size').int()
	bs.text_align = TextHorizontalAlign(a.value('text_align').int())
	bs.text_vertical_align = TextVerticalAlign(a.value('text_vertical_align').int())
}

pub fn (mut b Button) load_style() {
	// println("btn load style $b.theme_style")
	style := if b.theme_style == '' { b.ui.window.theme_style } else { b.theme_style }
	b.update_style(style: style)
	// forced overload default style
	b.update_style(b.style_forced)
}

pub fn (mut b Button) update_style(p ButtonStyleParams) {
	// println("update_style <$p.style>")
	style := if p.style == '' { 'default' } else { p.style }
	if style != no_style && style in b.ui.styles {
		bs := b.ui.styles[style].btn
		b.theme_style = p.style
		b.style.radius = bs.radius
		b.style.border_color = bs.border_color
		b.style.bg_color = bs.bg_color
		b.style.bg_color_pressed = bs.bg_color_pressed
		b.style.bg_color_hover = bs.bg_color_hover
		mut dtw := DrawTextWidget(b)
		dtw.update_theme_style(bs)
	} else {
		if p.radius > 0 {
			b.style.radius = p.radius
		}
		if p.border_color != no_color {
			b.style.border_color = p.border_color
		}
		if p.bg_color != no_color {
			b.style.bg_color = p.bg_color
		}
		if p.bg_color_pressed != no_color {
			b.style.bg_color_pressed = p.bg_color_pressed
		}
		if p.bg_color_hover != no_color {
			b.style.bg_color_hover = p.bg_color_hover
		}
		mut dtw := DrawTextWidget(b)
		dtw.update_theme_style_params(p)
	}
}

// TODO: to remove when tested
// pub fn (mut b Button) update_style(p ButtonStyleParams) {
// 	// println("update_style <$p.style>")
// 	style := if p.style == '' { 'default' } else { p.style }
// 	if style != no_style && style in b.ui.styles {
// 		bs := b.ui.styles[style].btn
// 		b.theme_style = p.style
// 		b.style.radius = bs.radius
// 		b.style.border_color = bs.border_color
// 		b.style.bg_color = bs.bg_color
// 		b.style.bg_color_pressed = bs.bg_color_pressed
// 		b.style.bg_color_hover = bs.bg_color_hover
// 		mut dtw := DrawTextWidget(b)
// 		dtw.update_style(
// 			font_name: bs.text_font_name
// 			color: bs.text_color
// 			size: bs.text_size
// 			align: bs.text_align
// 			vertical_align: bs.text_vertical_align
// 		)
// 	} else {
// 		if p.radius > 0 {
// 			b.style.radius = p.radius
// 		}
// 		if p.border_color != no_color {
// 			b.style.border_color = p.border_color
// 		}
// 		if p.bg_color != no_color {
// 			b.style.bg_color = p.bg_color
// 		}
// 		if p.bg_color_pressed != no_color {
// 			b.style.bg_color_pressed = p.bg_color_pressed
// 		}
// 		if p.bg_color_hover != no_color {
// 			b.style.bg_color_hover = p.bg_color_hover
// 		}
// 		mut dtw := DrawTextWidget(b)
// 		if p.text_size > 0 {
// 			dtw.update_text_size(p.text_size)
// 		}
// 		mut ts, mut ok := TextStyleParams{}, false
// 		if p.text_font_name != '' {
// 			ok = true
// 			ts.font_name = p.text_font_name
// 		}
// 		if p.text_color != no_color {
// 			ok = true
// 			ts.color = p.text_color
// 		}
// 		if p.text_align != .@none {
// 			ok = true
// 			ts.align = p.text_align
// 		}
// 		if p.text_vertical_align != .@none {
// 			ok = true
// 			ts.vertical_align = p.text_vertical_align
// 		}
// 		if ok {
// 			dtw.update_style(ts)
// 		}
// 	}
// }
