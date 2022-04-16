module ui

import gx
import gg
import toml

// Window

pub struct WindowStyle {
pub mut:
	bg_color gx.Color
}

[params]
pub struct WindowStyleParams {
mut:
	style    string   = no_style
	bg_color gx.Color = no_color
}

pub fn (w WindowStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['bg_color'] = hex_color(w.bg_color)
	return toml.to_toml()
}

pub fn (mut w WindowStyle) from_toml(a toml.Any) {
	w.bg_color = HexColor(a.value('bg_color').string()).color()
}

pub fn (mut w Window) load_style() {
	mut style := w.theme_style
	if w.style_forced.style != no_style {
		style = w.style_forced.style
	}
	w.update_theme_style(style)
	// println("w bg: $w.bg_color")
	w.update_style(w.style_forced)
	// println("w2 bg: $w.bg_color")
	mut gui := w.ui
	gui.gg.set_bg_color(w.bg_color)
}

pub fn (mut w Window) update_theme_style(theme string) {
	// println("update_style <$p.style>")
	style := if theme == '' { 'default' } else { theme }
	if style != no_style && style in w.ui.styles {
		ws := w.ui.styles[style].win
		w.theme_style = theme
		w.bg_color = ws.bg_color
	}
}

fn (mut w Window) update_style(p WindowStyleParams) {
	if p.bg_color != no_color {
		w.bg_color = p.bg_color
	}
}
