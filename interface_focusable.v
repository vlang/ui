module ui

// Contains all the methods related to focus management
// that is to say:
// * Focusable interface and its methods
// * methods for Window
// * methods for Layout interface

pub interface Focusable {
	ui &UI
mut:
	id         string
	hidden     bool
	is_focused bool
	focus()
	unfocus()
}

// is_disabled reports whether the concrete widget behind this Focusable has
// its interaction disabled. Widgets without a disabled state are always enabled.
pub fn (f Focusable) is_disabled() bool {
	if f is Button {
		return f.disabled
	}
	if f is CheckBox {
		return f.disabled
	}
	if f is Dropdown {
		return f.disabled
	}
	if f is Slider {
		return f.disabled
	}
	if f is Radio {
		return f.disabled
	}
	if f is TextBox {
		return f.disabled
	}
	if f is Switch {
		return f.disabled
	}
	return false
}

// is_focus_visible applies the same visibility rules as mouse hit-testing:
// a widget hidden by its own z-index, by an ancestor, or by a deactivated
// parent layout must not be reachable through keyboard focus navigation.
pub fn (f Focusable) is_focus_visible() bool {
	if f is Widget {
		w := f as Widget
		return w.is_visible() && w.is_parent_visible(true) && !w.has_parent_deactivated()
	}
	return !f.hidden
}

// TODO: documentation
pub fn (f Focusable) has_focusable() bool {
	mut focusable := true
	if f is TextBox {
		focusable = !f.read_only
	}
	$if focus ? {
		println('${f.id}.has_focusable(): ${focusable} && ${f.is_focus_visible()} && ${!f.is_disabled()} && ${f.ui.window.unlocked_focus()} (locked_focus=<${f.ui.window.locked_focus}>)')
	}
	return focusable && f.is_focus_visible() && !f.is_disabled() && f.ui.window.unlocked_focus()
}

// Only one widget can have the focus inside a Window
pub fn (mut f Focusable) set_focus() {
	mut w := f.ui.window
	if !w.unlocked_focus() || f.is_disabled() || !f.is_focus_visible() {
		return
	}
	if f.is_focused {
		if mut w.ui.dd is DrawDeviceContext {
			$if focus ? {
				println('${f.id} already has focus at ${w.ui.dd.frame}')
			}
		}
		return
	}
	Layout(w).unfocus_all()
	if f.has_focusable() {
		f.is_focused = true
		if mut w.ui.dd is DrawDeviceContext {
			$if focus ? {
				println('${f.id} has focus at ${w.ui.dd.frame}')
			}
		}
	}
	// update drawing_children when focus is taken
	f.update_parent_drawing_children()
}

// Only one widget can have the focus inside a Window
pub fn (mut f Focusable) force_focus() {
	mut w := f.ui.window
	if f.is_disabled() || !f.is_focus_visible() {
		return
	}
	if f.is_focused {
		if mut w.ui.dd is DrawDeviceContext {
			$if focus ? {
				println('${f.id} already has focus at ${w.ui.dd.frame}')
			}
		}
		return
	}
	Layout(w).unfocus_all()
	f.is_focused = true
	if mut w.ui.dd is DrawDeviceContext {
		$if focus ? {
			println('${f.id} has focus at ${w.ui.dd.frame}')
		}
	}
}

// TODO: documentation
pub fn (f Focusable) lock_focus() {
	mut w := f.ui.window
	$if focus ? {
		println('${f.id} lock focus')
	}
	w.locked_focus = f.id
}

// TODO: documentation
pub fn (f Focusable) unlock_focus() {
	mut w := f.ui.window
	if w.locked_focus == f.id {
		$if focus ? {
			println('${f.id} unlock focus')
		}
		w.locked_focus = ''
	}
}

// TODO: documentation
pub fn (f Focusable) update_parent_drawing_children() {
	if f is Widget {
		w := f as Widget
		mut p := w.parent
		if mut p is CanvasLayout {
			p.set_drawing_children()
		} else if mut p is CanvasLayout {
			p.set_drawing_children()
		}
	}
}
