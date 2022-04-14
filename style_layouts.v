module ui

import gx
import toml

// CanvasLayout

pub struct CanvasLayoutStyle {
pub mut:
	color           gx.Color = gx.rgb(87, 153, 245)
	border_color    gx.Color = gx.rgb(76, 133, 213)
	bg_color        gx.Color = gx.rgb(219, 219, 219)
	bg_border_color gx.Color = gx.rgb(191, 191, 191)
}

[params]
pub struct CanvasLayoutStyleParams {
pub mut:
	style           string   = no_style
	color           gx.Color = no_color
	border_color    gx.Color = no_color
	bg_color        gx.Color = no_color
	bg_border_color gx.Color = no_color
}

pub fn (ls CanvasLayoutStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['color'] = hex_color(ls.color)
	toml['border_color'] = hex_color(ls.border_color)
	toml['bg_color'] = hex_color(ls.bg_color)
	toml['bg_border_color'] = hex_color(ls.bg_border_color)
	return toml.to_toml()
}

pub fn (mut ls CanvasLayoutStyle) from_toml(a toml.Any) {
	ls.color = HexColor(a.value('color').string()).color()
	ls.border_color = HexColor(a.value('border_color').string()).color()
	ls.bg_color = HexColor(a.value('bg_color').string()).color()
	ls.bg_border_color = HexColor(a.value('bg_border_color').string()).color()
}

fn (mut l CanvasLayout) load_style() {
	// println("pgbar load style $l.theme_style")
	style := if l.theme_style == '' { l.ui.window.theme_style } else { l.theme_style }
	l.update_style(style: style)
	// forced overload default style
	l.update_style(l.style_forced)
}

pub fn (mut l CanvasLayout) update_style(p CanvasLayoutStyleParams) {
	// println("update_style <$p.style>")
	style := if p.style == '' { 'default' } else { p.style }
	if style != no_style && style in l.ui.styles {
		ls := l.ui.styles[style].pgbar
		l.theme_style = p.style
		l.style.color = ls.color
		l.style.border_color = ls.border_color
		l.style.bg_color = ls.bg_color
		l.style.bg_border_color = ls.bg_border_color
	} else {
		if p.color != no_color {
			l.style.color = p.color
		}
		if p.border_color != no_color {
			l.style.border_color = p.border_color
		}
		if p.bg_color != no_color {
			l.style.bg_color = p.bg_color
		}
		if p.bg_border_color != no_color {
			l.style.bg_border_color = p.bg_border_color
		}
	}
}
