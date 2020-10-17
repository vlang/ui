const (
	files_to_skip = [
		'pngs.v', // bin2v file
		// misplaced comments:
		'examples/rectangles.v',
		'examples/users.v',
		'listbox.v',
		'radio.v',
		'window.v',
		// cannot compile afterwards:
		'dropdown.v', // invalid module prefixing
		'menu.v', // ^^
		'slider.v', // ^^
		'switch.v', // ^^
		'webview/webview.v', // ^^
		'checkbox.v', // ^^
		'picture.v', // ^^; misplaced comments
		'textbox.v', // ^^; removed args in type decl
		'button.v', // ^^; ^^; misplaced comments
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
