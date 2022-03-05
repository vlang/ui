fn is_v_code_dir(path string) bool {
	entries := ls(path) or { return false }
	for entry in entries {
		if entry.ends_with('.v') && is_file(join_path(path, entry)) {
			return true
		}
	}
	return false
}

fn println_one_of_many(msg string, entry_idx int, entries_len int) {
	println('${entry_idx + 1:2}/${entries_len:-2} $msg')
}

examples_dir := resource_abs_path('.')
all_entries := ls(examples_dir) or { return }
mut entries := []string{}
for entry in all_entries {
	is_dir_project := (is_dir(entry) && is_v_code_dir(entry))
	if !is_dir_project && !entry.ends_with('.v') {
		println('skipping $entry')
		continue
	}
	if entry == 'webview.v' {
		$if !macos {
			println('skipping $entry on !macos')
			continue
		}
	}
	entries << entry
}
mut err := 0
mut failures := []string{}
for entry_idx, entry in entries {
	cmd := 'v $examples_dir/$entry'
	println_one_of_many('compile with: $cmd', entry_idx, entries.len)
	ret := system(cmd)
	if ret != 0 {
		err++
		eprintln('>>> FAILURE')
		failures << cmd
	}
}
if err > 0 {
	err_count := if err == 1 { '1 error' } else { '$err errors' }
	for f in failures {
		eprintln('> failed compilation cmd: $f')
	}
	eprintln('\nFailed with ${err_count}.')
	exit(1)
}
