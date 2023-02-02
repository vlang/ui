module ui

import gx
import toml

// Slider

pub struct SliderStyle {
pub mut:
	thumb_color             gx.Color = gx.rgb(87, 153, 245)
	bg_color                gx.Color = gx.rgb(219, 219, 219)
	bg_border_color         gx.Color = gx.rgb(191, 191, 191)
	focused_bg_border_color gx.Color = gx.rgb(255, 0, 0)
}

[params]
pub struct SliderStyleParams {
pub mut:
	style                   string   = no_style
	thumb_color             gx.Color = no_color
	bg_color                gx.Color = no_color
	bg_border_color         gx.Color = no_color
	focused_bg_border_color gx.Color = no_color
}

pub fn slider_style(p SliderStyleParams) SliderStyleParams {
	return p
}

pub fn (ss SliderStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['thumb_color'] = hex_color(ss.thumb_color)
	toml_['bg_color'] = hex_color(ss.bg_color)
	toml_['bg_border_color'] = hex_color(ss.bg_border_color)
	toml_['focused_bg_border_color'] = hex_color(ss.focused_bg_border_color)
	return toml_.to_toml()
}

pub fn (mut ss SliderStyle) from_toml(a toml.Any) {
	ss.thumb_color = HexColor(a.value('thumb_color').string()).color()
	ss.bg_color = HexColor(a.value('bg_color').string()).color()
	ss.bg_border_color = HexColor(a.value('bg_border_color').string()).color()
	ss.focused_bg_border_color = HexColor(a.value('focused_bg_border_color').string()).color()
}

fn (mut s Slider) load_style() {
	// println("pgbar load style $s.theme_style")
	mut style := if s.theme_style == '' { s.ui.window.theme_style } else { s.theme_style }
	if s.style_params.style != no_style {
		style = s.style_params.style
	}
	s.update_theme_style(style)
	// forced overload default style
	s.update_style(s.style_params)
}

pub fn (mut s Slider) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in s.ui.styles {
		ss := s.ui.styles[style].slider
		s.theme_style = theme
		s.style.thumb_color = ss.thumb_color
		s.style.bg_color = ss.bg_color
		s.style.bg_border_color = ss.bg_border_color
		s.style.focused_bg_border_color = ss.focused_bg_border_color
	}
}

pub fn (mut s Slider) update_style(p SliderStyleParams) {
	if p.thumb_color != no_color {
		s.style.thumb_color = p.thumb_color
	}
	if p.bg_color != no_color {
		s.style.bg_color = p.bg_color
	}
	if p.bg_border_color != no_color {
		s.style.bg_border_color = p.bg_border_color
	}
	if p.focused_bg_border_color != no_color {
		s.style.focused_bg_border_color = p.focused_bg_border_color
	}
}
