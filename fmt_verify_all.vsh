const (
	files_to_skip = []string{}
)

root_dir := resource_abs_path('.')
v_files := walk_ext(root_dir, '.v')
mut errs := 0
for file in v_files {
	if file.trim_prefix(root_dir) in files_to_skip {
		continue
	}
	ret := system('v fmt -verify $file')
	if ret != 0 {
		errs++
	}
}
if errs > 0 {
	println('\nFail: $errs of $v_files.len files are not formatted')
	exit(1)
}
