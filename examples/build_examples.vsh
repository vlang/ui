import os

files := os.ls('.') or { return }
for file in files {
	if !file.ends_with('.v') {
		continue
	}
	println(file)
	ret := os.system('v -w $file')
	if ret != 0 {
		println('failed')
		exit(1)
	}
}
