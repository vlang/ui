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
	style    string = no_style
	bg_color gx.Color
}

pub fn (w WindowStyle) to_toml() string {
	mut toml := map[string]toml.Any{}
	toml['bg_color'] = hex_color(w.bg_color)
	return toml.to_toml()
}

pub fn (mut w WindowStyle) from_toml(a toml.Any) {
	w.bg_color = HexColor(a.value('bg_color').string()).color()
}

pub fn (mut w Window) update_style(p WindowStyleParams) {
	// println("update_style <$p.style>")
	style := if p.style == '' { 'default' } else { p.style }
	if style != no_style && style in w.ui.styles {
		ws := w.ui.styles[style].win
		w.bg_color = ws.bg_color
		mut gui := w.ui
		gui.gg.set_bg_color(w.bg_color)
	}
}
