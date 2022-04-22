module ui

import gx
import toml

// CanvasLayout

pub struct CanvasLayoutShapeStyle {
pub mut:
	bg_radius f32
	bg_color  gx.Color = no_color
}

pub struct CanvasLayoutStyle {
	CanvasLayoutShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

[params]
pub struct CanvasLayoutStyleParams {
pub mut:
	style     string = no_style
	bg_radius f32
	bg_color  gx.Color = no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn canvaslayout_style(p CanvasLayoutStyleParams) CanvasLayoutStyleParams {
	return p
}

pub fn (ls CanvasLayoutStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['bg_radius'] = ls.bg_radius
	toml['bg_color'] = hex_color(ls.bg_color)
	return toml.to_toml()
}

pub fn (mut ls CanvasLayoutStyle) from_toml(a toml.Any) {
	ls.bg_radius = a.value('bg_radius').f32()
	ls.bg_color = HexColor(a.value('bg_color').string()).color()
}

fn (mut l CanvasLayout) load_style() {
	// println("pgbar load style $l.theme_style")
	mut style := if l.theme_style == '' { l.ui.window.theme_style } else { l.theme_style }
	if l.style_forced.style != no_style {
		style = l.style_forced.style
	}
	l.update_theme_style(style)
	// forced overload default style
	l.update_style(l.style_forced)
}

pub fn (mut l CanvasLayout) update_theme_style(theme string) {
	// println("$l.id update_theme_style <$theme>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in l.ui.styles {
		ls := l.ui.styles[style].cl
		l.theme_style = theme
		l.update_shape_theme_style(ls)
		mut dtw := DrawTextWidget(l)
		dtw.update_theme_style(ls)
	}
}

pub fn (mut l CanvasLayout) update_style(p CanvasLayoutStyleParams) {
	// println("$l.id update_style <$p>")
	l.update_shape_style(p)
	mut dtw := DrawTextWidget(l)
	dtw.update_theme_style_params(p)
}

pub fn (mut l CanvasLayout) update_shape_theme_style(ls CanvasLayoutStyle) {
	l.style.bg_radius = ls.bg_radius
	l.style.bg_color = ls.bg_color
}

pub fn (mut l CanvasLayout) update_shape_style(p CanvasLayoutStyleParams) {
	if p.bg_radius > 0 {
		l.style.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		l.style.bg_color = p.bg_color
	}
}

pub fn (mut l CanvasLayout) update_style_forced(p CanvasLayoutStyleParams) {
	if p.bg_radius > 0 {
		l.style_forced.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		l.style_forced.bg_color = p.bg_color
	}
	mut dtw := DrawTextWidget(l)
	dtw.update_theme_style_params(p)
}

// Stack

pub struct StackShapeStyle {
pub mut:
	bg_radius f32
	bg_color  gx.Color = no_color
}

pub struct StackStyle {
	StackShapeStyle // text_style TextStyle
pub mut:
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .left
	text_vertical_align TextVerticalAlign   = .top
}

[params]
pub struct StackStyleParams {
pub mut:
	style     string = no_style
	bg_radius f32
	bg_color  gx.Color = no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn stack_style(p StackStyleParams) StackStyleParams {
	return p
}

pub fn (ls StackStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['bg_radius'] = ls.bg_radius
	toml['bg_color'] = hex_color(ls.bg_color)
	return toml.to_toml()
}

pub fn (mut ls StackStyle) from_toml(a toml.Any) {
	ls.bg_radius = a.value('bg_radius').f32()
	ls.bg_color = HexColor(a.value('bg_color').string()).color()
}

fn (mut l Stack) load_style() {
	// println("stack load style $l.theme_style")
	mut style := if l.theme_style == '' { l.ui.window.theme_style } else { l.theme_style }
	if l.style_forced.style != no_style {
		style = l.style_forced.style
	}
	l.update_theme_style(style)
	// forced overload default style
	l.update_style(l.style_forced)
	// println("s ls $l.theme_style $l.style $l.style_forced")
}

pub fn (mut l Stack) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in l.ui.styles {
		ls := l.ui.styles[style].stack
		l.theme_style = theme
		l.update_shape_theme_style(ls)
		mut dtw := DrawTextWidget(l)
		dtw.update_theme_style(ls)
	}
}

pub fn (mut l Stack) update_style(p StackStyleParams) {
	l.update_shape_style(p)
	mut dtw := DrawTextWidget(l)
	dtw.update_theme_style_params(p)
}

pub fn (mut l Stack) update_shape_theme_style(ls StackStyle) {
	l.style.bg_radius = ls.bg_radius
	l.style.bg_color = ls.bg_color
}

pub fn (mut l Stack) update_shape_style(p StackStyleParams) {
	if p.bg_radius > 0 {
		l.style.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		l.style.bg_color = p.bg_color
	}
}

pub fn (mut l Stack) update_style_forced(p StackStyleParams) {
	if p.bg_radius > 0 {
		l.style_forced.bg_radius = p.bg_radius
	}
	if p.bg_color != no_color {
		l.style_forced.bg_color = p.bg_color
	}
	mut dtw := DrawTextWidget(l)
	dtw.update_theme_style_params(p)
}
