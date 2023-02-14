module component

import ui
// import gx

// TODO: documentation
pub fn setting_color(param string) {
}

pub struct SettingFont {
	param   string
	lb_text string
mut:
	layout   &ui.Stack
	lb_param &ui.Label
	lb_font  &ui.Label
	btn_font &ui.Button
}

[params]
pub struct SettingFontParams {
	id    string
	param string
	text  string
}

// TODO: documentation
pub fn setting_font(s SettingFontParams) &ui.Stack {
	lb_param := ui.label(text: s.text)
	lb_font := ui.label(text: s.id)
	btn_font := fontbutton(text: 'font', dtw: lb_font)
	layout := ui.row(
		widths: [100.0, 100, 20]
		heights: 20.0
		children: [lb_param, lb_font, btn_font]
	)
	sf := &SettingFont{
		layout: layout
		lb_param: lb_param
		lb_font: lb_font
		btn_font: btn_font
	}
	ui.component_connect(sf, layout, lb_param, lb_font)
	return layout
}

// TODO: documentation
pub fn setting_int(param string) &ui.Stack {
	return ui.row()
}

// TODO: documentation
pub fn setting_f32(param string) &ui.Stack {
	return ui.row()
}

// TODO: documentation
pub fn settings_bool(param string) &ui.Stack {
	return ui.row()
}
