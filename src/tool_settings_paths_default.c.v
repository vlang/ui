module ui

import os

const settings_dir = os.join_path_single(os.config_dir() or { os.home_dir() }, '.vui')
