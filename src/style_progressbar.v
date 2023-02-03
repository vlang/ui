module ui

import gx
import toml

// ProgressBar

pub struct ProgressBarStyle {
pub mut:
	color           gx.Color
	border_color    gx.Color
	bg_color        gx.Color
	bg_border_color gx.Color
}

[params]
pub struct ProgressBarStyleParams {
pub mut:
	style           string   = no_style
	color           gx.Color = no_color
	border_color    gx.Color = no_color
	bg_color        gx.Color = no_color
	bg_border_color gx.Color = no_color
}

pub fn progressbar_style(p ProgressBarStyleParams) ProgressBarStyleParams {
	return p
}

pub fn (pbs ProgressBarStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['color'] = hex_color(pbs.color)
	toml_['border_color'] = hex_color(pbs.border_color)
	toml_['bg_color'] = hex_color(pbs.bg_color)
	toml_['bg_border_color'] = hex_color(pbs.bg_border_color)
	return toml_.to_toml()
}

pub fn (mut pbs ProgressBarStyle) from_toml(a toml.Any) {
	pbs.color = HexColor(a.value('color').string()).color()
	pbs.border_color = HexColor(a.value('border_color').string()).color()
	pbs.bg_color = HexColor(a.value('bg_color').string()).color()
	pbs.bg_border_color = HexColor(a.value('bg_border_color').string()).color()
}

fn (mut pb ProgressBar) load_style() {
	// println("pgbar load style $pb.theme_style")
	mut style := if pb.theme_style == '' { pb.ui.window.theme_style } else { pb.theme_style }
	if pb.style_params.style != no_style {
		style = pb.style_params.style
	}
	pb.update_theme_style(style)
	// forced overload default style
	pb.update_style(pb.style_params)
}

pub fn (mut pb ProgressBar) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in pb.ui.styles {
		pbs := pb.ui.styles[style].pgbar
		pb.theme_style = theme
		pb.style.color = pbs.color
		pb.style.border_color = pbs.border_color
		pb.style.bg_color = pbs.bg_color
		pb.style.bg_border_color = pbs.bg_border_color
	}
}

pub fn (mut pb ProgressBar) update_style(p ProgressBarStyleParams) {
	if p.color != no_color {
		pb.style.color = p.color
	}
	if p.border_color != no_color {
		pb.style.border_color = p.border_color
	}
	if p.bg_color != no_color {
		pb.style.bg_color = p.bg_color
	}
	if p.bg_border_color != no_color {
		pb.style.bg_border_color = p.bg_border_color
	}
}
