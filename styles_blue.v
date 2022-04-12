module ui

import gx

pub fn (mut gui UI) load_blue_style() {
	// button
	gui.styles.btn['blue'] = ButtonFullStyle{
		border_color: button_border_color
		bg_color: gx.light_blue
		bg_color_pressed: gx.rgb(0, 0, 119)
		bg_color_hover: gx.rgb(0, 0, 219)
	}
}
