module ui

import os

const (
	settings_dir        = os.join_path(get_config_directory(), '.vui')
	settings_styles_dir = os.join_path(get_config_directory(), '.vui', 'styles')
)

pub fn get_config_directory() string {
	config_path := os.getenv('XDG_CONFIG_HOME')
	if config_path != '' {
		return config_path
	}
	return os.join_path(os.home_dir(), '.config')
}
