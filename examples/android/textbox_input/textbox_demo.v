import ui
//import gx
import jni
import jni.auto

const (
	pkg = 'io.v.android.ui.VUIActivity'
)

struct App {
mut:
	tb        string
	soft_input_visible     bool
	soft_input_buffer      string
	soft_input_parsed_char string
}

fn init(window &ui.Window) {
	// Pass app reference off to Java so we
	// can get it back in the V callback "on_soft_input"
	app_ref := i64(window.state)
	auto.call_static_method(pkg+'.setVAppPointer(long) void',app_ref)

	mut app := &App(window.state)
	app.show_soft_input()
}

[export: 'JNI_OnLoad']
fn jni_on_load(vm &jni.JavaVM, reserved voidptr) int {
	jni.set_java_vm(vm)
	$if android {
		// V consts - can't be used since `JNI_OnLoad`
		// is called by the Java VM before the lib
		// with V's init code is loaded and called.
		jni.setup_android('io.v.android.ui.VUIActivity')
	}
	return C.JNI_VERSION_1_6 // TODO
}

// on_soft_keyboard_input is exported to the Java activity "VUIActivity".
// `app_ptr` is the pointer to the `struct App` instance it needs to be cast back to it's
// original type since Java has no concept of pointers.
// The method is called in Java to notify you that:
// within `jstr`, the `count` characters beginning at `start` have just replaced old text that had `length` before.
[export: 'JNICALL Java_io_v_android_ui_VUIActivity_onSoftInput']
fn on_soft_input(env &jni.Env, thiz jni.JavaObject, app_ptr i64, jstr jni.JavaString, start int, before int, count int) {
	if app_ptr == 0 {
		return
	}

	mut app := &App(app_ptr)

	buffer := jni.j2v_string(env, jstr)
	println(@MOD + '.' + @FN + ': "$buffer" ($start,$before,$count)')

	mut char_code := byte(0)
	mut char_literal := ''

	mut pos := start + before
	if pos >= 0 && pos <= buffer.len {
		char_code = byte(buffer[pos])
		char_literal = char_code.ascii_str()
	}
	println(@MOD + '.' + @FN + ': input "$char_literal"')

	app.soft_input_buffer = buffer
	app.soft_input_parsed_char = char_literal

	app.tb = app.soft_input_buffer
}

fn (mut a App) show_soft_input() {
	$if android {
		auto.call_static_method(pkg + '.showSoftInput()')
		auto.call_static_method(pkg + '.setSoftInputBuffer(string)', '')
		a.soft_input_visible = true
	}
}

fn (mut a App) hide_soft_input() {
	$if android {
		auto.call_static_method(pkg + '.hideSoftInput()')
		a.soft_input_visible = false
	}
}

fn main() {
	mut app := &App{
		tb: 'Textbox example'
	}

	c := ui.column(
		widths: ui.stretch
		heights: [ui.compact, ui.stretch]
		margin_: 5
		spacing: 10
		children: [
			ui.row(
				spacing: 5
				children: [
					ui.label(
						text: 'Text input' //&app.tb
					)
				]
			),
			ui.textbox(
				id: 'tb1'
				mode: .multiline | .word_wrap
				text: &app.tb
				//fitted_height: true
			)
		]
	)
	w := ui.window(
		state: app
		width: 500
		height: 300
		mode: .resizable
		on_init: init
		children: [c]
	)
	ui.run(w)
}
