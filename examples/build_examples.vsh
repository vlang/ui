examples_dir := resource_abs_path('.')
files := ls(examples_dir) or { return }
mut err := 0
for file in files {
	if !file.ends_with('.v') {
		continue
	}
	println(file)
	ret := system('v -w $examples_dir/$file')
	if ret != 0 {
		err++
	}
}
if err > 0 {
	err_count := if err == 1 { '1 error' } else { '$err errors' }
	println('\nFailed with ${err_count}.')
	exit(1)
}
