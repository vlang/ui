module ui

import sokol.sapp

// wrapper just to not include `import sokol.sapp`

pub fn get_num_dropped_files() int {
	return sapp.get_num_dropped_files()
}

pub fn get_dropped_file_path(i int) string {
	return sapp.get_dropped_file_path(i)
}
