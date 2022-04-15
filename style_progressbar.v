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
	mut toml := map[string]toml.Any{}
	toml['color'] = hex_color(pbs.color)
	toml['border_color'] = hex_color(pbs.border_color)
	toml['bg_color'] = hex_color(pbs.bg_color)
	toml['bg_border_color'] = hex_color(pbs.bg_border_color)
	return toml.to_toml()
}

pub fn (mut pbs ProgressBarStyle) from_toml(a toml.Any) {
	pbs.color = HexColor(a.value('color').string()).color()
	pbs.border_color = HexColor(a.value('border_color').string()).color()
	pbs.bg_color = HexColor(a.value('bg_color').string()).color()
	pbs.bg_border_color = HexColor(a.value('bg_border_color').string()).color()
}

fn (mut pb ProgressBar) load_style() {
	// println("pgbar load style $pb.theme_style")
	style := if pb.theme_style == '' { pb.ui.window.theme_style } else { pb.theme_style }
	pb.update_style(style: style)
	// forced overload default style
	pb.update_style(pb.style_forced)
}

pub fn (mut pb ProgressBar) update_style(p ProgressBarStyleParams) {
	// println("update_style <$p.style>")
	style := if p.style == '' { 'default' } else { p.style }
	if style != no_style && style in pb.ui.styles {
		pbs := pb.ui.styles[style].pgbar
		pb.theme_style = p.style
		pb.style.color = pbs.color
		pb.style.border_color = pbs.border_color
		pb.style.bg_color = pbs.bg_color
		pb.style.bg_border_color = pbs.bg_border_color
	} else {
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
}
