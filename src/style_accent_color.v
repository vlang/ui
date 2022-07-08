module ui

import gx
import math

pub fn (mut gui UI) update_style_from_accent_color(accent_color []int) {
	gui.accent_color = accent_color
	gui.load_style_from_accent_color()
}

pub fn (mut gui UI) load_style_from_accent_color() {
	colors := color_scheme_from_accent_color(gui.accent_color)
	gui.styles['accent_color'] = Style{
		// window
		win: WindowStyle{
			bg_color: default_window_color
		}
		// button
		btn: ButtonStyle{
			radius: .1
			border_color: button_border_color
			bg_color: colors[1]
			bg_color_pressed: gx.rgb(119, 119, 119)
			bg_color_hover: gx.rgb(219, 219, 219)
		}
		// progressbar
		pgbar: ProgressBarStyle{
			color: gx.rgb(87, 153, 245)
			border_color: gx.rgb(76, 133, 213)
			bg_color: gx.rgb(219, 219, 219)
			bg_border_color: gx.rgb(191, 191, 191)
		}
	}
}

// Inspiration from mui project made by @malisipi

fn color_scheme_from_accent_color(accent_color []int) []gx.Color {
	mut font_color := [0, 0, 0]
	if accent_color[0] + accent_color[1] + accent_color[2] / 3 < 255 * 3 / 2 {
		font_color = [255, 255, 255]
	}

	color_scheme := [
		[accent_color[0] / 3, accent_color[1] / 3, accent_color[2] / 3],
		accent_color,
		[accent_color[0] * 5 / 3, accent_color[1] * 5 / 3, accent_color[2] * 5 / 3],
		font_color,
	]

	mut gx_colors := []gx.Color{}
	for color in color_scheme {
		gx_colors << gx.Color{
			r: u8(math.max(math.min(color[0], 255), 0))
			g: u8(math.max(math.min(color[1], 255), 0))
			b: u8(math.max(math.min(color[2], 255), 0))
		}
	}
	return gx_colors
}
