module component

import ui

const (
	fontchooser_subwindow_id = '_sw_font'
)

// Append fontchooser to window
pub fn fontchooser_subwindow_add(mut w ui.Window) { //}, fontchooser_lb_change ui.ListBoxSelectionChangedFn) {
	// only once
	if !ui.Layout(w).has_child_id(component.fontchooser_subwindow_id) {
		w.subwindows << ui.subwindow(
			id: component.fontchooser_subwindow_id
			layout: fontchooser_stack()
		)
	}
}

// TODO: documentation
pub fn fontchooser_subwindow_visible(w &ui.Window) {
	mut s := w.get_or_panic[ui.SubWindow](component.fontchooser_subwindow_id)
	s.set_visible(s.hidden)
	s.update_layout()
}

// TODO: documentation
pub fn fontchooser_subwindow(w &ui.Window) &ui.SubWindow {
	return w.get_or_panic[ui.SubWindow](component.fontchooser_subwindow_id)
}
