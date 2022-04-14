module ui

import gx
import toml
import os

// define style outside Widget definition
// all styles would be collected inside one map attached to ui

pub const (
	no_style = '_no_style_'
	no_color = gx.Color{0, 0, 0, 0}
)

pub struct Style {
pub mut:
	win WindowStyle
	btn ButtonStyle
}

pub fn (s Style) to_toml() string {
	mut toml := ''
	toml += '[win]\n'
	toml += s.win.to_toml()
	toml += '\n[btn]\n'
	toml += s.btn.to_toml()
	return toml
}

pub fn parse_style_toml_file(path string) Style {
	doc := toml.parse_file(path) or { panic(err) }
	mut s := Style{}
	s.win.from_toml(doc.value('win'))
	s.btn.from_toml(doc.value('btn'))
	return s
}

pub fn (s Style) as_toml_file(path string) {
	text := '# $path generated automatically\n' + s.to_toml()
	os.write_file(path, text) or { panic(err) }
}

pub fn style_toml_file(style_id string) string {
	return os.join_path(settings_styles_dir, 'style_${style_id}.toml')
}

// load styles

pub fn (mut gui UI) load_styles() {
	// ensure some theme styles are predefined
	create_theme_styles()
	for style_id in ['default', 'red', 'blue'] {
		gui.load_style_from_file(style_id)
	}
}

pub fn (mut gui UI) load_style_from_file(style_id string) {
	style := parse_style_toml_file(style_toml_file(style_id))
	// println("$style_id: $style")
	gui.styles[style_id] = style
}

// predefined style

fn create_theme_styles() {
	if !os.exists(settings_styles_dir) {
		os.mkdir_all(settings_styles_dir) or { panic(err) }
	}
	if !os.exists(style_toml_file('default')) {
		create_default_style_file()
	}
	if !os.exists(style_toml_file('red')) {
		create_red_style_file()
	}
	if !os.exists(style_toml_file('blue')) {
		create_blue_style_file()
	}
}

pub fn default_style() Style {
	// "" means default
	return Style{
		// window
		win: WindowStyle{
			bg_color: default_window_color
		}
		// button
		btn: ButtonStyle{
			radius: .3
			border_color: button_border_color
			bg_color: gx.white
			bg_color_pressed: gx.rgb(119, 119, 119)
			bg_color_hover: gx.rgb(219, 219, 219)
		}
	}
}

pub fn create_default_style_file() {
	default_style().as_toml_file(style_toml_file('default'))
}

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

pub fn create_blue_style_file() {
	blue_style().as_toml_file(os.join_path(settings_styles_dir, 'style_blue.toml'))
}

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

pub fn create_red_style_file() {
	red_style().as_toml_file(os.join_path(settings_styles_dir, 'style_red.toml'))
}
