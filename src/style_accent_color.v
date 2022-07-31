module ui

import gx
import math

pub fn (mut w Window) load_accent_color_style(accent_color []int) {
	w.ui.update_accent_color_style(accent_color)
	mut l := Layout(w)
	l.update_theme_style('accent_color')
}

pub fn (mut l Layout) load_accent_color_style(accent_color []int) {
	mut gui := l.get_ui()
	gui.update_accent_color_style(accent_color)
	l.update_theme_style('accent_color')
}

pub fn (mut gui UI) update_accent_color_style(accent_color []int) {
	gui.accent_color = accent_color
	gui.update_style_from_accent_color()
}

pub fn (mut gui UI) update_style_from_accent_color() {
	colors := color_scheme_from_accent_color(gui.accent_color)
	mode := if colors[3] == gx.black { '' } else { '_white' }
	gui.styles['accent_color'] = Style{
		// window
		win: WindowStyle{
			bg_color: colors[0]
		}
		// label
		label: LabelStyle{
			text_color: colors[3]
		}
		// button
		btn: ButtonStyle{
			radius: .1
			border_color: button_border_color
			bg_color: colors[2]
			bg_color_pressed: colors[0]
			bg_color_hover: colors[1]
			text_color: colors[3]
		}
		// textbox
		tb: TextBoxStyle{
			bg_color: colors[2]
			text_color: colors[3]
		}
		// checkbox
		cb: CheckBoxStyle{
			border_color: colors[1]
			bg_color: colors[2]
			check_mode: 'check' + mode
			text_color: colors[3]
		}
		// radio
		radio: RadioStyle{
			border_color: colors[1]
			bg_color: colors[2]
			radio_mode: 'radio' + mode
			text_color: colors[3]
		}
		// progressbar
		pgbar: ProgressBarStyle{
			color: colors[2]
			border_color: colors[3]
			bg_color: colors[1]
			bg_border_color: colors[0]
		}
		// slider
		slider: SliderStyle{
			thumb_color: colors[3]
			bg_color: colors[1]
			bg_border_color: colors[0]
			focused_bg_border_color: colors[2]
		}
		// menu
		menu: MenuStyle{
			border_color: colors[0]
			bar_color: colors[2]
			bg_color: colors[1]
			bg_color_hover: colors[0]
			text_color: colors[3]
		}
		// listbox
		lb: ListBoxStyle{
			border_color: colors[0]
			bg_color: colors[1]
			bg_color_pressed: colors[2]
			bg_color_hover: colors[0]
			text_color: colors[3]
		}
		// dropdown
		dd: DropdownStyle{
			bg_color: colors[1]
			border_color: colors[0]
			focus_color: colors[2]
			drawer_color: colors[3]
			text_color: colors[3]
		}
	}
	gui.cb_image = gui.img('check' + mode)
	gui.radio_selected_image = gui.img('radio' + mode + '_selected')
}

// Inspiration from mui project made by @malisipi

pub fn color_scheme_from_accent_color(accent_color []int) []gx.Color {
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

pub fn (gui &UI) accent_colors() []gx.Color {
	return color_scheme_from_accent_color(gui.accent_color)
}
