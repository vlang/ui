const (
	files_to_skip = [
		'button.v', // struct syntax, struct comment removal, type comment err
		'checkbox.v', // struct comment removal
		'listbox.v', // type comment err
		'picture.v', // type comment err
		'radio.v', // struct comment removal
		'textbox.v', // struct comment removal
		'pngs.v', // bin2v file
	]
)

root_dir := resource_abs_path('.') + '/'
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
	println('\nError: $errs of $v_files.len files are not formatted')
	exit(1)
}
