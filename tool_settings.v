module ui

import toml
import os

const (
	settings_dir        = os.join_path(os.home_dir(), '.vui')
	settings_styles_dir = os.join_path(os.home_dir(), '.vui', 'styles')
)

// Tool for TOML

pub fn load_settings() {
	if !os.exists(ui.settings_styles_dir) {
		os.mkdir_all(ui.settings_styles_dir) or { panic(err) }
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

[params]
struct PrintTomlParams {
	title string
}

fn printed_toml(v toml.Any, p PrintTomlParams) string {
	mut out := ''
	am := v.as_map()
	for k, e in am {
		title := if p.title == '' { k } else { '${p.title}.$k' }
		indent := ['  '].repeat(title.split('.').len - 1).join('')
		toml := e.as_map().to_toml()
		if toml[0..4] == '0 = ' {
			out += '$indent$k = $e.to_toml()\n'
		} else if toml.contains('{') {
			// map
			out += printed_toml(e.as_map(),
				title: title
			)
		} else {
			out += '$indent[$title]\n'
			mut res := ''
			for l in toml.split('\n') {
				res += '$indent$l\n'
			}
			out += res
		}
	}
	return out
}
