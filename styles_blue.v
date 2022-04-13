module ui

import gx
import os

pub fn blue_style() Style {
	return Style{
		// win
		win: WindowStyle{
			bg_color: gx.blue
		}
		// button
		btn: ButtonStyle{
			border_color: button_border_color
			bg_color: gx.light_blue
			bg_color_pressed: gx.rgb(0, 0, 119)
			bg_color_hover: gx.rgb(0, 0, 219)
		}
	}
}

pub fn (mut gui UI) load_blue_style() {
	style := 'blue'
	// window
	gui.styles[style] = blue_style()
}

pub fn create_blue_style_file() {
	blue_style().as_toml_file(os.join_path(settings_styles_dir, 'style_blue.toml'))
}
