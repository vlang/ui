module ui

import toml
import os

const (
	settings_dir        = os.join_path(os.home_dir(), '.vui')
	settings_styles_dir = os.join_path(os.home_dir(), '.vui', 'styles')
)
