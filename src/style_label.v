module ui

import gx
import toml

pub struct LabelStyle {
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int                 = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

pub struct LabelStyleParams {
	WidgetTextStyleParams
pub mut:
	style string = no_style
}

pub fn (ls LabelStyle) to_toml() string {
	mut toml_ := map[string]toml.Any{}
	toml_['text_font_name'] = ls.text_font_name
	toml_['text_color'] = hex_color(ls.text_color)
	toml_['text_size'] = ls.text_size
	toml_['text_align'] = int(ls.text_align)
	toml_['text_vertical_align'] = int(ls.text_vertical_align)
	return toml_.to_toml()
}

pub fn (mut ls LabelStyle) from_toml(a toml.Any) {
	ls.text_font_name = a.value('text_font_name').string()
	ls.text_color = HexColor(a.value('text_color').string()).color()
	ls.text_size = a.value('text_size').int()
	ls.text_align = unsafe { TextHorizontalAlign(a.value('text_align').int()) }
	ls.text_vertical_align = unsafe { TextVerticalAlign(a.value('text_vertical_align').int()) }
}

pub fn (mut l Label) load_style() {
	// println("btn load style $rect.theme_style")
	mut style := if l.theme_style == '' { l.ui.window.theme_style } else { l.theme_style }
	if l.style_params.style != no_style {
		style = l.style_params.style
	}
	l.update_theme_style(style)
	// forced overload default style
	l.update_style(l.style_params)
}

pub fn (mut l Label) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in l.ui.styles {
		ls := l.ui.styles[style].label
		l.theme_style = theme
		mut dtw := DrawTextWidget(l)
		dtw.update_theme_style(ls)
	}
}

pub fn (mut l Label) update_style(p LabelStyleParams) {
	mut dtw := DrawTextWidget(l)
	dtw.update_theme_style_params(p)
}
