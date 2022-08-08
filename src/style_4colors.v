module ui

import gx

pub fn (mut w Window) load_4colors_style(colors []gx.Color) {
	w.ui.update_4colors_style(colors)
	mut l := Layout(w)
	l.update_theme_style('4colors')
}

pub fn (mut l Layout) load_4colors_style(colors []gx.Color) {
	mut gui := l.get_ui()
	gui.update_4colors_style(colors)
	l.update_theme_style('4colors')
}

pub fn (mut gui UI) update_4colors_style(colors []gx.Color) {
	gui.style_colors = colors
	gui.update_style_from_4colors()
}

pub fn (mut gui UI) update_style_from_4colors() {
	colors := gui.style_colors
	mode := if colors[3] == gx.black { '' } else { '_white' }
	gui.styles['4colors'] = Style{
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
			bg_color_pressed: colors[0]
			bg_color_hover: colors[2]
			text_color: colors[3]
		}
		// dropdown
		dd: DropdownStyle{
			bg_color: colors[1]
			border_color: colors[0]
			focus_color: colors[2]
			drawer_color: colors[2]
			text_color: colors[3]
		}
	}
	gui.cb_image = gui.img('check' + mode)
	gui.down_arrow = gui.img('arrow' + mode)
	gui.radio_selected_image = gui.img('radio' + mode + '_selected')
}
