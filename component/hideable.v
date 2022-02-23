module component

import ui
import gx

[heap]
struct Hideable {
pub mut:
	id       string
	layout   &ui.Stack
	window   &ui.Window = &ui.Window(0)
	z_index  map[string]int
	children map[string]ui.Widget
}

[params]
pub struct HideableParams {
	id       string
	bg_color gx.Color
	layout   &ui.Stack
	hidden   bool = true
}

pub fn hideable(p HideableParams) &ui.Stack {
	mut h := &Hideable{
		id: p.id
		layout: p.layout
	}
	h.save_children_depth(h.layout.children)
	if p.hidden {
		h.hide_children()
	}
	ui.component_connect(h, h.layout)
	h.layout.component_init = hideable_init
	return h.layout
}

pub fn component_hideable(w ui.ComponentChild) &Hideable {
	return &Hideable(w.component)
}

fn hideable_init(layout &ui.Stack) {
	mut h := component_hideable(layout)
	h.window = layout.ui.window
	if h.layout.z_index == ui.z_index_hidden {
		h.hide()
	}
}

pub fn (mut h Hideable) show() {
	mut layout := h.layout
	// restore z_index
	h.show_children()
	layout.set_drawing_children()
	h.window.update_layout()
}

pub fn (mut h Hideable) hide() {
	mut layout := h.layout
	h.hide_children()
	layout.set_drawing_children()
	h.window.update_layout()
}

pub fn (mut h Hideable) toggle() {
	if h.layout.z_index == ui.z_index_hidden {
		h.show()
	} else {
		h.hide()
	}
}

pub fn (mut h Hideable) show_children() {
	// restore z_index
	for id, _ in h.children {
		mut child := h.children[id]
		child.z_index = h.z_index[id]
	}
}

pub fn (mut h Hideable) hide_children() {
	for id, _ in h.children {
		mut child := h.children[id]
		child.z_index = ui.z_index_hidden
	}
	h.layout.z_index = ui.z_index_hidden
}

pub fn (mut h Hideable) set_children_depth() {
	for child in h.layout.children {
		h.z_index[child.id] = child.z_index
	}
	h.layout.z_index = h.z_index[h.layout.id]
}

pub fn (mut h Hideable) save_children_depth(children []ui.Widget) {
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
