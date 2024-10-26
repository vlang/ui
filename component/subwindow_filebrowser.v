module component

import ui

const filebrowser_subwindow_id = '_sw_filebrowser'
const newfilebrowser_subwindow_id = '_sw_newfilebrowser'

// Subwindow
@[params]
pub struct FileBrowserSubWindowParams {
	FileBrowserParams
pub:
	x int
	y int
}

// TODO: documentation
pub fn filebrowser_subwindow_add(mut w ui.Window, p FileBrowserSubWindowParams) { //}, fontchooser_lb_change ui.ListBoxSelectionChangedFn) {
	id := p.FileBrowserParams.id
	// only once
	if !ui.Layout(w).has_child_id(ui.component_id(id, filebrowser_subwindow_id)) {
		w.subwindows << ui.subwindow(
			id:     ui.component_id(id, filebrowser_subwindow_id)
			x:      p.x
			y:      p.y
			layout: filebrowser_stack(p.FileBrowserParams)
		)
	}
}

// TODO: documentation
pub fn filebrowser_subwindow_visible(w &ui.Window, id string) {
	mut s := w.get_or_panic[ui.SubWindow](ui.component_id(id, filebrowser_subwindow_id))
	s.set_visible(s.hidden)
	s.update_layout()
}

// TODO: documentation
pub fn filebrowser_subwindow_close(w &ui.Window, id string) {
	mut s := w.get_or_panic[ui.SubWindow](ui.component_id(id, filebrowser_subwindow_id))
	s.set_visible(false)
	s.update_layout()
}

// NewFile Browser

// TODO: documentation
pub fn newfilebrowser_subwindow_add(mut w ui.Window, p FileBrowserSubWindowParams) { //}, fontchooser_lb_change ui.ListBoxSelectionChangedFn) {
	// only once
	if !ui.Layout(w).has_child_id(ui.component_id(p.id, newfilebrowser_subwindow_id)) {
		p2 := FileBrowserParams{
			...p.FileBrowserParams
			with_fpath: true
			text_ok:    'New'
		}
		w.subwindows << ui.subwindow(
			id:     ui.component_id(p.id, newfilebrowser_subwindow_id)
			x:      p.x
			y:      p.y
			layout: filebrowser_stack(p2)
		)
	}
}

// TODO: documentation
pub fn newfilebrowser_subwindow_visible(w &ui.Window, id string) {
	mut s := w.get_or_panic[ui.SubWindow](ui.component_id(id, newfilebrowser_subwindow_id))
	s.set_visible(s.hidden)
	s.update_layout()
}

// TODO: documentation
pub fn newfilebrowser_subwindow_close(w &ui.Window, id string) {
	mut s := w.get_or_panic[ui.SubWindow](ui.component_id(id, newfilebrowser_subwindow_id))
	s.set_visible(false)
	s.update_layout()
}
