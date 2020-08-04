import sync

fn launch_exe(name string, mut ret []int, mut wg sync.WaitGroup) {
	ret << system('timeout 2s ./$name')
	wg.done()
}

examples_dir := resource_abs_path('.')
chdir(examples_dir)
files := ls('.') or { return }
executables := files.filter(is_executable(it) && exists('${file_name(it)}.v'))
mut ret := []int{}
mut wg := sync.new_waitgroup()
wg.add(executables.len)
for exe in executables {
	go launch_exe(exe, mut &ret, mut wg)
}
wg.wait()
err := ret.filter(it != 0).len
if err > 0 {
	success := executables.len - err
	println('\nFailed with $err errors and $success successful')
	exit(1)
}
