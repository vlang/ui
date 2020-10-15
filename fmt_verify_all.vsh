const (
	files_to_skip = [
		'button.v', // struct syntax, struct comment removal, type comment err
		'checkbox.v', // struct comment removal
		'listbox.v', // fn param removed, type comment misplacement
		'picture.v', // type comment misplacement
		'radio.v', // struct comment removal
		'textbox.v', // struct comment removal
		'pngs.v', // bin2v file
		'ui.v', // err
		'window.v', // err
		'examples/webview.v', // err
	]
)

root_dir := resource_abs_path('.') + '/'
mut v_files := walk_ext(root_dir, '.v')
v_files = v_files.filter(!it.contains('examples/modules/'))
mut skipped := 0
mut errs := 0
for file in v_files {
	if file.trim_prefix(root_dir) in files_to_skip {
		skipped++
		continue
	}
	ret := system('v fmt -verify $file')
	if ret != 0 {
		errs++
	}
}
successfull := v_files.len - skipped - errs
println('Successfull\t| Skipped\t| Errors\t| Total')
println('$successfull\t\t| $skipped\t\t| $errs\t\t| $v_files.len')
if errs > 0 {
	exit(1)
}
