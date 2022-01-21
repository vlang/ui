module ui

// Contains all the methods related to focus management
// that is to say:
// * Focusable interface and its methods
// * methods for Window
// * methods for Layout interface

interface Focusable {
	ui &UI
mut:
	id string
	hidden bool
	is_focused bool
	focus()
	unfocus()
}

pub fn (f Focusable) has_focusable() bool {
	mut focusable := true
	if f is TextBox {
		focusable = !f.read_only
	}
	$if focus ? {
		println('${f.id}.has_focusable(): $focusable && ${!f.hidden} && $f.ui.window.unlocked_focus() (locked_focus=<$f.ui.window.locked_focus>)')
	}
	return focusable && !f.hidden && f.ui.window.unlocked_focus()
}

// Only one widget can have the focus inside a Window
pub fn (mut f Focusable) set_focus() {
	w := f.ui.window
	if !w.unlocked_focus() {
		return
	}
	if f.is_focused {
		$if focus ? {
			println('$f.id already has focus at $w.ui.gg.frame')
		}
		return
	}
	Layout(w).unfocus_all()
	if f.has_focusable() {
		f.is_focused = true
		$if focus ? {
			println('$f.id has focus at $w.ui.gg.frame')
		}
	}
}

pub fn (f Focusable) lock_focus() {
	mut w := f.ui.window
	$if focus ? {
		println('$f.id lock focus')
	}
	w.locked_focus = f.id
}

pub fn (f Focusable) unlock_focus() {
	mut w := f.ui.window
	if w.locked_focus == f.id {
		$if focus ? {
			println('$f.id unlock focus')
		}
		w.locked_focus = ''
	}
}
