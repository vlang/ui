examples_dir := resource_abs_path('.')
chdir(examples_dir)
files := ls('.') or { return }
v_files := files.filter(it.ends_with('.v'))
mut err := 0
for file in v_files {
	println(file)
	ret := system('v -w $file')
	if ret != 0 {
		err++
	}
}
if err > 0 {
	success := v_files.len - err
	println('\nFailed with $err errors and $success successful')
	exit(1)
}
