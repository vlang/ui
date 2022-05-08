module component

import ui

const (
	filebrowser_subwindow_id    = '_sw_filebrowser'
	newfilebrowser_subwindow_id = '_sw_newfilebrowser'
)

// Subwindow
[params]
pub struct FileBrowserSubWindowParams {
	FileBrowserParams
	x int
	y int
}

pub fn filebrowser_subwindow_add(mut w ui.Window, p FileBrowserSubWindowParams) { //}, fontchooser_lb_change ui.ListBoxSelectionChangedFn) {
	id := p.FileBrowserParams.id
	// only once
	if !ui.Layout(w).has_child_id(ui.component_id(id, component.filebrowser_subwindow_id)) {
		w.subwindows << ui.subwindow(
			id: ui.component_id(id, component.filebrowser_subwindow_id)
			x: p.x
			y: p.y
			layout: filebrowser_stack(p.FileBrowserParams)
		)
	}
}

pub fn filebrowser_subwindow_visible(w &ui.Window, id string) {
	mut s := w.subwindow(ui.component_id(id, component.filebrowser_subwindow_id))
	s.set_visible(s.hidden)
	s.update_layout()
}

pub fn filebrowser_subwindow_close(w &ui.Window, id string) {
	mut s := w.subwindow(ui.component_id(id, component.filebrowser_subwindow_id))
	s.set_visible(false)
	s.update_layout()
}

// NewFile Browser

pub fn newfilebrowser_subwindow_add(mut w ui.Window, p FileBrowserSubWindowParams) { //}, fontchooser_lb_change ui.ListBoxSelectionChangedFn) {
	// only once
	if !ui.Layout(w).has_child_id(ui.component_id(p.id, component.newfilebrowser_subwindow_id)) {
		p2 := FileBrowserParams{
			...p.FileBrowserParams
			with_fpath: true
			text_ok: 'New'
		}
		w.subwindows << ui.subwindow(
			id: ui.component_id(p.id, component.newfilebrowser_subwindow_id)
			x: p.x
			y: p.y
			layout: filebrowser_stack(p2)
		)
	}
}

pub fn newfilebrowser_subwindow_visible(w &ui.Window, id string) {
	mut s := w.subwindow(ui.component_id(id, component.newfilebrowser_subwindow_id))
	s.set_visible(s.hidden)
	s.update_layout()
}

pub fn newfilebrowser_subwindow_close(w &ui.Window, id string) {
	mut s := w.subwindow(ui.component_id(id, component.newfilebrowser_subwindow_id))
	s.set_visible(false)
	s.update_layout()
}
