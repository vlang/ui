const (
	files_to_skip = [
		'pngs.v', // bin2v file
		// misplaced comments and more:
		'examples/rectangles.v',
		'examples/users.v',
		'listbox.v',
		'radio.v',
		'window.v',
		'picture.v',
		'button.v', // space before first fn arg in type decl
		'checkbox.v', // ^^
		// cannot compile afterwards:
		'textbox.v', // invalid module prefixing, space before first fn arg in type decl
		// vfmt fails on those:
		'ui.v', // unexpected comment
		'examples/webview.v', // expecting struct key
	]
)

root_dir := resource_abs_path('.') + '/'
mut v_files := walk_ext(root_dir, '.v')
v_files = v_files.filter(!it.contains('examples/modules/'))
mut skipped := 0
mut errs := 0
for file in v_files {
	fname := file.trim_prefix(root_dir)
	if fname in files_to_skip {
		println('Skipping $fname')
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
