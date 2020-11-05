const (
	files_to_skip = [
		'pngs.v', // bin2v file
		// visual problems:
		'examples/rectangles.v', // misplaced comment in a struct
		'examples/users.v', // misplaced comment in a struct
		'listbox.v', // fn type decl: misplaced comment, extra space; struct: some comments are moved to new lines
		'radio.v', // struct: misplaced comment
		'window.v', // lots of misplaced comment
		'picture.v', // fn type decl: misplaced comment
		'checkbox.v', // fn type decl: extra spaces
		'button.v', // fn type decl: extra spaces, misplaced comment
		'ui.v', // struct, interface: misplaced comment
		// cannot compile afterwards:
		'textbox.v', // invalid module prefixing; extra spaces in fn type decl; misformatted unsafe
		// vfmt fails on those:
		'examples/webview.v', // unexpected `stretch: true`, expecting struct key
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
