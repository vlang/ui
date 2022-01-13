fn is_v_code_dir(path string) bool {
	entries := ls(path) or { return false }
	for entry in entries {
		if entry.ends_with('.v') && is_file(join_path(path, entry)) {
			return true
		}
	}
	return false
}

examples_dir := resource_abs_path('.')
entries := ls(examples_dir) or { return }
mut err := 0
for entry in entries {
	is_dir_project := (is_dir(entry) && is_v_code_dir(entry))
	if !is_dir_project && !entry.ends_with('.v') {
		continue
	}
	if entry == 'webview.v' {
		$if !macos {
			continue
		}
	}
	println(entry)
	ret := system('v $examples_dir/$entry')
	if ret != 0 {
		err++
	}
}
if err > 0 {
	err_count := if err == 1 { '1 error' } else { '$err errors' }
	println('\nFailed with ${err_count}.')
	exit(1)
}
