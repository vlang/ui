module ui

import gx
import toml

// Dropdown

pub struct DropdownShapeStyle {
pub mut:
	bg_color     gx.Color = gx.rgb(240, 240, 240)
	border_color gx.Color = gx.rgb(223, 223, 223)
	focus_color  gx.Color = gx.rgb(50, 50, 50)
	drawer_color gx.Color = gx.rgb(255, 255, 255)
}

struct DropdownStyle {
	DropdownShapeStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int                 = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

@[params]
pub struct DropdownStyleParams {
	WidgetTextStyleParams
pub mut:
	style        string   = no_style
	bg_color     gx.Color = no_color
	border_color gx.Color = no_color
	focus_color  gx.Color = no_color
	drawer_color gx.Color = no_color
}

pub fn dropdown_style(p DropdownStyleParams) DropdownStyleParams {
	return p
}

pub fn (dds DropdownStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['bg_color'] = hex_color(dds.bg_color)
	toml_['border_color'] = hex_color(dds.border_color)
	toml_['focus_color'] = hex_color(dds.focus_color)
	toml_['drawer_color'] = hex_color(dds.drawer_color)
	return toml_.to_toml()
}

pub fn (mut dds DropdownStyle) from_toml(a toml.Any) {
	dds.bg_color = HexColor(a.value('bg_color').string()).color()
	dds.border_color = HexColor(a.value('border_color').string()).color()
	dds.focus_color = HexColor(a.value('focus_color').string()).color()
	dds.drawer_color = HexColor(a.value('drawer_color').string()).color()
}

fn (mut dd Dropdown) load_style() {
	// println("pgbar load style $dd.theme_style")
	mut style := if dd.theme_style == '' { dd.ui.window.theme_style } else { dd.theme_style }
	if dd.style_params.style != no_style {
		style = dd.style_params.style
	}
	dd.update_theme_style(style)
	// forced overload default style
	dd.update_style(dd.style_params)
}

pub fn (mut dd Dropdown) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in dd.ui.styles {
		dds := dd.ui.styles[style].dd
		dd.theme_style = theme
		dd.update_shape_theme_style(dds)
		mut dtw := DrawTextWidget(dd)
		dtw.update_theme_style(dds)
	}
}

pub fn (mut dd Dropdown) update_style(p DropdownStyleParams) {
	// println("update_style <$p.style>")
	dd.update_shape_style(p)
	mut dtw := DrawTextWidget(dd)
	dtw.update_theme_style_params(p)
}

fn (mut dd Dropdown) update_shape_theme_style(dds DropdownStyle) {
	dd.style.bg_color = dds.bg_color
	dd.style.border_color = dds.border_color
	dd.style.focus_color = dds.focus_color
	dd.style.drawer_color = dds.drawer_color
}

pub fn (mut dd Dropdown) update_shape_style(p DropdownStyleParams) {
	if p.bg_color != no_color {
		dd.style.bg_color = p.bg_color
	}
	if p.border_color != no_color {
		dd.style.border_color = p.border_color
	}
	if p.focus_color != no_color {
		dd.style.focus_color = p.focus_color
	}
	if p.drawer_color != no_color {
		dd.style.drawer_color = p.drawer_color
	}
}

pub fn (mut dd Dropdown) update_style_params(p DropdownStyleParams) {
	if p.bg_color != no_color {
		dd.style_params.bg_color = p.bg_color
	}
	if p.border_color != no_color {
		dd.style_params.border_color = p.border_color
	}
	if p.focus_color != no_color {
		dd.style_params.focus_color = p.focus_color
	}
	if p.drawer_color != no_color {
		dd.style_params.drawer_color = p.drawer_color
	}
	mut dtw := DrawTextWidget(dd)
	dtw.update_theme_style_params(p)
}
