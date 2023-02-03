module ui

import toml
import os

const (
	settings_dir        = os.join_path(os.home_dir(), '.vui')
	settings_styles_dir = os.join_path(os.home_dir(), '.vui', 'styles')
)

// Tool for TOML

pub fn load_settings() {
}

[params]
struct PrintTomlParams {
	title string
}

fn printed_toml(v toml.Any, p PrintTomlParams) string {
	mut out := ''
	am := v.as_map()
	for k, e in am {
		title := if p.title == '' { k } else { '${p.title}.${k}' }
		indent := ['  '].repeat(title.split('.').len - 1).join('')
		toml_ := e.as_map().to_toml()
		if toml_[0..4] == '0 = ' {
			out += '${indent}${k} = ${e.to_toml()}\n'
		} else if toml_.contains('{') {
			// map
			out += printed_toml(e.as_map(),
				title: title
			)
		} else {
			out += '${indent}[${title}]\n'
			mut res := ''
			for l in toml_.split('\n') {
				res += '${indent}${l}\n'
			}
			out += res
		}
	}
	return out
}
