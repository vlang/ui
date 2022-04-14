module ui

import gx
import os

pub fn red_style() Style {
	return Style{
		// win
		win: WindowStyle{
			bg_color: gx.red
		}
		// button
		btn: ButtonStyle{
			border_color: button_border_color
			bg_color: gx.light_red
			bg_color_pressed: gx.rgb(119, 0, 0)
			bg_color_hover: gx.rgb(219, 0, 0)
		}
	}
}

// pub fn (mut gui UI) load_red_style() {
// 	style := 'red'
// 	// window
// 	gui.styles[style] = red_style()
// }

pub fn create_red_style_file() {
	red_style().as_toml_file(os.join_path(settings_styles_dir, 'style_red.toml'))
}
