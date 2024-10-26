module component

import ui
import gx

@[heap]
pub struct HideableComponent {
pub mut:
	id              string
	layout          &ui.Stack = unsafe { nil }
	child_layout_id string
	window          &ui.Window = &ui.Window(unsafe { nil })
	z_index         map[string]int
	children        map[string]ui.Widget
	shortcut        string
	open            bool
}

@[params]
pub struct HideableParams {
pub:
	id       string
	bg_color gx.Color
	layout   &ui.Stack = unsafe { nil }
	hidden   bool      = true
	shortcut string
	open     bool = true
}

// TODO: documentation
pub fn hideable_stack(p HideableParams) &ui.Stack {
	mut layout := ui.row(
		widths:   ui.stretch
		heights:  ui.stretch
		id:       ui.component_id(p.id, 'layout')
		children: [p.layout]
	)

	mut h := &HideableComponent{
		id:              p.id
		layout:          layout
		child_layout_id: p.layout.id
		shortcut:        p.shortcut
		open:            p.open
	}

	h.save_children_depth(layout.children)
	if p.hidden {
		h.hide_children()
	}
	ui.component_connect(h, layout)
	layout.on_init = hideable_init
	return layout
}

// TODO: documentation
pub fn hideable_component(w ui.ComponentChild) &HideableComponent {
	return unsafe { &HideableComponent(w.component) }
}

// TODO: documentation
pub fn hideable_component_from_id(w ui.Window, id string) &HideableComponent {
	return hideable_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

fn hideable_init(layout &ui.Stack) {
	mut h := hideable_component(layout)
	h.window = layout.ui.window
	if h.layout.z_index == ui.z_index_hidden {
		h.hide()
	}
}

// TODO: documentation
pub fn hideable_add_shortcut(w &ui.Window, shortcut string, shortcut_fn ui.ShortcutFn) {
	mut sc := ui.Shortcutable(w)
	sc.add_shortcut(shortcut, shortcut_fn)
}

// TODO: documentation
pub fn hideable_toggle(w &ui.Window, id string) {
	mut h := hideable_component_from_id(w, id)
	h.toggle()
}

// TODO: documentation
pub fn hideable_show(w &ui.Window, id string) {
	mut h := hideable_component_from_id(w, id)
	h.show()
}

// TODO: documentation
pub fn hideable_hide(w &ui.Window, id string) {
	mut h := hideable_component_from_id(w, id)
	h.hide()
}

// TODO: documentation
pub fn (mut h HideableComponent) show() {
	// mut layout := h.window.stack(h.child_layout_id)
	// restore z_index
	h.show_children()
	h.layout.set_drawing_children()
	h.window.update_layout()
}

// TODO: documentation
pub fn (mut h HideableComponent) hide() {
	mut layout := h.layout
	h.hide_children()
	layout.set_drawing_children()
	h.window.update_layout()
}

// TODO: documentation
pub fn (h HideableComponent) is_active() bool {
	return h.layout.z_index != ui.z_index_hidden
}

// TODO: documentation
pub fn (mut h HideableComponent) toggle() {
	if h.layout.z_index == ui.z_index_hidden {
		h.show()
	} else {
		h.hide()
	}
}

// TODO: documentation
pub fn (mut h HideableComponent) show_children() {
	// restore z_index
	for id, _ in h.children {
		mut child := h.children[id]
		child.z_index = h.z_index[id]
	}
}

// TODO: documentation
pub fn (mut h HideableComponent) hide_children() {
	for id, _ in h.children {
		mut child := h.children[id]
		child.z_index = ui.z_index_hidden
	}
	h.layout.z_index = ui.z_index_hidden
}

// TODO: documentation
pub fn (mut h HideableComponent) set_children_depth() {
	for child in h.layout.children {
		h.z_index[child.id] = child.z_index
	}
	h.layout.z_index = h.z_index[h.layout.id]
}

// TODO: documentation
pub fn (mut h HideableComponent) save_children_depth(children []ui.Widget) {
	for child in children {
		if child is ui.Layout {
			l := child as ui.Layout
			h.save_children_depth(l.get_children())
		}
		h.children[child.id] = child
		h.z_index[child.id] = child.z_index
	}
	h.z_index[h.layout.id] = h.layout.z_index
}
