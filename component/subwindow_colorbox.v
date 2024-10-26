module component

import ui
import gx

const colorbox_subwindow_id = '_sw_cbox'
const colorbox_subwindow_layout_id = ui.component_id('_sw_cbox', 'layout')

// Append colorbox to window
pub fn colorbox_subwindow_add(mut w ui.Window) {
	// only once
	if !ui.Layout(w).has_child_id(colorbox_subwindow_id) {
		w.subwindows << ui.subwindow(
			id:     colorbox_subwindow_id
			layout: colorbox_stack(id: colorbox_subwindow_id, light: false, hsl: false)
		)
	}
}

pub enum ShowMode {
	show
	hide
	toggle
}

// to connect the colorbox to gx.Color reference
pub fn colorbox_subwindow_connect(w &ui.Window, col &gx.Color, colbtn &ColorButtonComponent, show ShowMode) {
	mut s := w.get_or_panic[ui.SubWindow](colorbox_subwindow_id)
	cb_layout := w.get_or_panic[ui.Stack](colorbox_subwindow_layout_id)
	mut cb := colorbox_component(cb_layout)
	if unsafe { col != 0 } {
		cb.connect(col)
		cb.update_from_rgb(col.r, col.g, col.b)
		cb.update_cur_color(true)
	}
	// connect also the colbtn of cb
	if unsafe { colbtn != 0 } {
		// println("connect ${colbtn.widget.id} ${colbtn.on_changed != ColorButtonChangedFn(0)}")
		cb.connect_colorbutton(colbtn)
	}
	s.set_visible(match show {
		.toggle { s.hidden }
		.show { true }
		.hide { false }
	})
	s.update_layout()
}
