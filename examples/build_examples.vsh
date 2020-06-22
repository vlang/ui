import os

examples_dir := os.resource_abs_path('.') + '/'
files := os.ls(examples_dir) or { return }
for file in files {
	if !file.ends_with('.v') {
		continue
	}
	println(file)
	ret := os.system('v -w ${examples_dir + file}')
	if ret != 0 {
		println('failed')
		exit(1)
	}
}
