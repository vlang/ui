import ui
import jni
import jni.auto

const (
	pkg = 'io.v.android.ui.VUIActivity'
)

fn (mut app App) init(window &ui.Window) {
	// Pass app reference off to Java so we
	// can get it back in the V callback "on_soft_input"

	// TODO: test if this is still valid
	app_ref := i64(&app) // OLD: i64(window.state)
	auto.call_static_method(pkg + '.setVAppPointer(long) void', app_ref)

	app.show_soft_input()
	// show_soft_input(mut app)
}

@[export: 'JNI_OnLoad']
fn jni_on_load(vm &jni.JavaVM, reserved voidptr) int {
	jni.set_java_vm(vm)
	$if android {
		// V consts - can't be used since `JNI_OnLoad`
		// is called by the Java VM before the lib
		// with V's init code is loaded and called.
		jni.setup_android('io.v.android.ui.VUIActivity')
	}
	return int(jni.Version.v1_6)
}

// on_soft_input is exported to match the name for the native Java activity VUIActivity's method:
// "public native void onSoftInput(long app, String s, int start, int before, int count);".
// `app_ptr` is the pointer to the `struct App` instance pointer store in an `i64` (long in Java)
// it needs to be cast back to it's original type since Java has no concept of pointers.
// The method is called in Java to notify you that:
// within `jstr`, the `count` characters beginning at `start` have just replaced old text that had `length` before.
@[export: 'JNICALL Java_io_v_android_ui_VUIActivity_onSoftInput']
fn on_soft_input(env &jni.Env, thiz jni.JavaObject, app_ptr i64, jstr jni.JavaString, start int, before int, count int) {
	if app_ptr == 0 {
		return
	}

	mut app := &App(app_ptr)

	buffer := jni.j2v_string(env, jstr)
	println(@MOD + '.' + @FN + ': "${buffer}" (${start},${before},${count})')

	mut char_code := u8(0)
	mut char_literal := ''

	mut pos := start + before
	if pos >= 0 && pos <= buffer.len {
		char_code = u8(buffer[pos])
		char_literal = char_code.ascii_str()
	}
	println(@MOD + '.' + @FN + ': input "${char_literal}"')

	app.soft_input_buffer = buffer
	app.soft_input_parsed_char = char_literal

	app.tb = app.soft_input_buffer
	app.window.refresh()
}

fn (mut a App) show_soft_input() {
	auto.call_static_method(pkg + '.showSoftInput()')
	auto.call_static_method(pkg + '.setSoftInputBuffer(string)', a.soft_input_buffer)
	a.soft_input_visible = true
}

fn (mut a App) hide_soft_input() {
	auto.call_static_method(pkg + '.hideSoftInput()')
	a.soft_input_visible = false
}
