module ui

import gx
import toml

// CheckBox

pub struct CheckBoxShapeStyle {
pub mut:
	check_mode   string   = 'check' // or "check_white" and maybe one day "square" and "square_white"
	border_color gx.Color = cb_border_color
	bg_color     gx.Color = gx.white
}

pub struct CheckBoxStyle {
	CheckBoxShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int                 = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

@[params]
pub struct CheckBoxStyleParams {
	WidgetTextStyleParams
pub mut:
	style        string   = no_style
	border_color gx.Color = no_color
	bg_color     gx.Color = no_color
	check_mode   string
}

pub fn checkbox_style(p CheckBoxStyleParams) CheckBoxStyleParams {
	return p
}

pub fn (cbs CheckBoxStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['border_color'] = hex_color(cbs.border_color)
	toml_['bg_color'] = hex_color(cbs.bg_color)
	toml_['check_mode'] = cbs.check_mode
	toml_['text_font_name'] = cbs.text_font_name
	toml_['text_color'] = hex_color(cbs.text_color)
	toml_['text_size'] = cbs.text_size
	toml_['text_align'] = int(cbs.text_align)
	toml_['text_vertical_align'] = int(cbs.text_vertical_align)
	return toml_.to_toml()
}

pub fn (mut cbs CheckBoxStyle) from_toml(a toml.Any) {
	cbs.border_color = HexColor(a.value('border_color').string()).color()
	cbs.bg_color = HexColor(a.value('bg_color').string()).color()
	cbs.check_mode = a.value('check_mode').string()
	cbs.text_font_name = a.value('text_font_name').string()
	cbs.text_color = HexColor(a.value('text_color').string()).color()
	cbs.text_size = a.value('text_size').int()
	cbs.text_align = unsafe { TextHorizontalAlign(a.value('text_align').int()) }
	cbs.text_vertical_align = unsafe { TextVerticalAlign(a.value('text_vertical_align').int()) }
}

pub fn (mut cb CheckBox) load_style() {
	// println("btn load style $cb.theme_style")
	mut style := if cb.theme_style == '' { cb.ui.window.theme_style } else { cb.theme_style }
	if cb.style_params.style != no_style {
		style = cb.style_params.style
	}
	cb.update_theme_style(style)
	// forced overload default style
	cb.update_style(cb.style_params)
	cb.ui.cb_image = cb.ui.img(cb.style.check_mode)
}

pub fn (mut cb CheckBox) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in cb.ui.styles {
		cbs := cb.ui.styles[style].cb
		cb.theme_style = theme
		cb.update_shape_theme_style(cbs)
		mut dtw := DrawTextWidget(cb)
		dtw.update_theme_style(cbs)
	}
}

pub fn (mut cb CheckBox) update_style(p CheckBoxStyleParams) {
	cb.update_shape_style(p)
	mut dtw := DrawTextWidget(cb)
	dtw.update_theme_style_params(p)
}

fn (mut cb CheckBox) update_shape_theme_style(cbs CheckBoxStyle) {
	cb.style.border_color = cbs.border_color
	cb.style.bg_color = cbs.bg_color
	cb.style.check_mode = cbs.check_mode
}

fn (mut cb CheckBox) update_shape_style(p CheckBoxStyleParams) {
	if p.border_color != no_color {
		cb.style.border_color = p.border_color
	}
	if p.bg_color != no_color {
		cb.style.bg_color = p.bg_color
	}
	if p.check_mode != '' {
		cb.style.check_mode = p.check_mode
	}
}

fn (mut cb CheckBox) update_style_params(p CheckBoxStyleParams) {
	if p.border_color != no_color {
		cb.style_params.border_color = p.border_color
	}
	if p.bg_color != no_color {
		cb.style_params.bg_color = p.bg_color
	}
	if p.check_mode != '' {
		cb.style_params.check_mode = p.check_mode
	}
	mut dtw := DrawTextWidget(cb)
	dtw.update_theme_style_params(p)
}
