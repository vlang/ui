module component

import ui

const (
	fontchooser_id = '_sw_font'
)

// Append fontchooser to window
pub fn fontchooser_add(mut w ui.Window) { //}, fontchooser_lb_change ui.ListBoxSelectionChangedFn) {
	// only once
	if !ui.Layout(w).has_child_id(component.fontchooser_id) {
		w.subwindows << ui.subwindow(
			id: component.fontchooser_id
			layout: fontchooser()
		)
	}
}

pub fn fontchooser_visible(w &ui.Window) {
	mut s := w.subwindow(component.fontchooser_id)
	s.set_visible(s.hidden)
	s.update_layout()
}

pub fn fontchooser_subwindow(w &ui.Window) &ui.SubWindow {
	return w.subwindow(component.fontchooser_id)
}

pub fn fontchooser_listbox(w &ui.Window) &ui.ListBox {
	return w.listbox(fontchooser_lb_id)
}
