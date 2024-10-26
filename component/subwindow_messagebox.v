module component

import ui

@[params]
pub struct MessageBoxSubWindowParams {
pub:
	id       string
	text     string
	shortcut string = 'ctrl + h'
	x        int    = 100
	y        int    = 100
	width    int    = 400
	height   int    = 400
}

// Append colorbox to window
pub fn messagebox_subwindow_add(mut w ui.Window, p MessageBoxSubWindowParams) {
	// only once
	if !ui.Layout(w).has_child_id(p.id) {
		subw := ui.subwindow(
			id:     p.id
			x:      p.x
			y:      p.y
			layout: messagebox_stack(
				id:       ui.component_id(p.id, 'msgbox')
				text:     p.text
				width:    p.width
				height:   p.height
				on_click: fn (hc &MessageBoxComponent) {
					mut sw := hc.layout.ui.window.get_or_panic[ui.SubWindow](ui.component_parent_id(hc.id))
					sw.set_visible(sw.hidden)
				}
			)
		)
		w.subwindows << subw
		mut sc := ui.Shortcutable(w)
		sc.add_shortcut(p.shortcut, fn (mut w ui.SubWindow) {
			w.set_visible(w.hidden)
		})
		sc.add_shortcut_context(p.shortcut, subw)
	}
}
