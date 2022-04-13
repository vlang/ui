module ui

import gx

pub fn (mut gui UI) load_red_style() {
	// button
	gui.styles.btn['red'] = ButtonStyle{
		border_color: button_border_color
		bg_color: gx.light_red
		bg_color_pressed: gx.rgb(119, 0, 0)
		bg_color_hover: gx.rgb(219, 0, 0)
	}
}
