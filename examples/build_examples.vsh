#!/usr/bin/env -S v

fn println_one_of_many(msg string, entry_idx int, entries_len int) {
	eprintln('${entry_idx + 1:2}/${entries_len:-2} ${msg}')
}

examples_dir := join_path(@VMODROOT, 'examples')
mut all_entries := walk_ext(examples_dir, '.v')
all_entries.sort()
mut entries := []string{}

for entry in all_entries {
	if entry.contains('textbox_input') {
		eprintln('skipping ${entry}, part of the folder based `textbox_input` example')
		continue
	}
	$if !macos {
		fname := file_name(entry)
		if fname == 'webview.v' {
			eprintln('skipping ${entry} on !macos')
			continue
		}
	}
	entries << entry
}
entries << join_path(examples_dir, 'textbox_input')

mut err := 0
mut failures := []string{}
chdir(examples_dir)!
for entry_idx, entry in entries {
	cmd := 'v -no-parallel ${entry}'
	println_one_of_many('compile with: ${cmd}', entry_idx, entries.len)
	ret := execute(cmd)
	if ret.exit_code != 0 {
		err++
		eprintln('>>> FAILURE')
		failures << cmd
	}
}

if err > 0 {
	err_count := if err == 1 { '1 error' } else { '${err} errors' }
	for f in failures {
		eprintln('> failed compilation cmd: ${f}')
	}
	eprintln('\nFailed with ${err_count}.')
	exit(1)
}
