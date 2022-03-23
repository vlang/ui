module component

import ui
import gx

const (
	colorbox_subwindow_id        = '_sw_cbox'
	colorbox_subwindow_layout_id = ui.component_part_id('_sw_cbox', 'layout')
)

// Append colorbox to window
pub fn colorbox_subwindow_add(mut w ui.Window) {
	// only once
	if !ui.Layout(w).has_child_id(component.colorbox_subwindow_id) {
		w.subwindows << ui.subwindow(
			id: component.colorbox_subwindow_id
			layout: colorbox_stack(id: component.colorbox_subwindow_id, light: true, hsl: false)
		)
	}
}

// to connect the colorbox to gx.Color reference
pub fn colorbox_subwindow_connect(w &ui.Window, col &gx.Color, colbtn &ColorButtonComponent, toogle bool) {
	mut s := w.subwindow(component.colorbox_subwindow_id)
	cb_layout := w.stack(component.colorbox_subwindow_layout_id)
	mut cb := colorbox_component(cb_layout)
	if col != 0 {
		cb.connect(col)
		cb.update_from_rgb(col.r, col.g, col.b)
		cb.update_cur_color(true)
	}
	// connect also the colbtn of cb
	if colbtn != 0 {
		// println("connect ${colbtn.widget.id} ${colbtn.on_changed != ColorButtonChangedFn(0)}")
		cb.connect_colorbutton(colbtn)
	}
	if toogle {
		s.set_visible(s.hidden)
	}
	s.update_layout()
}
