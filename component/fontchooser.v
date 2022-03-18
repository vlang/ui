module component

import ui
import os

const (
	fontchooser_row_id = '_row_sw_font'
	fontchooser_lb_id  = '_lb_sw_font'
)

[heap]
struct FontChooser {
pub mut:
	layout &ui.Stack // required
	dtw    ui.DrawTextWidget
}

[params]
pub struct FontChooserParams {
	id         string = component.fontchooser_lb_id
	draw_lines bool   = true
	dtw        ui.DrawTextWidget = ui.canvas_plus() // since it requires an intialisation
}

pub fn fontchooser(c FontChooserParams) &ui.Stack {
	mut lb := ui.listbox(
		id: c.id
		scrollview: true
		draw_lines: c.draw_lines
		on_change: fontchooser_lb_change
	)
	fontchooser_add_fonts_items(mut lb)
	layout := ui.row(
		id: component.fontchooser_row_id
		widths: 300.0
		heights: 200.0
		children: [lb]
	)
	mut fc := &FontChooser{
		layout: layout
		dtw: c.dtw
	}
	ui.component_connect(fc, layout, lb)
	return layout
}

pub fn component_fontchooser(w ui.ComponentChild) &FontChooser {
	return &FontChooser(w.component)
}

fn fontchooser_add_fonts_items(mut lb ui.ListBox) {
	font_paths := ui.font_path_list()

	for fp in font_paths {
		lb.append_item(fp, os.file_name(fp), 0)
	}
}

pub fn fontchooser_connect(w &ui.Window, dtw ui.DrawTextWidget) {
	fc_layout := w.stack(component.fontchooser_row_id)
	mut fc := component_fontchooser(fc_layout)
	fc.dtw = dtw
}

fn fontchooser_lb_change(a voidptr, lb &ui.ListBox) {
	mut w := lb.ui.window
	fc := component_fontchooser(lb)
	// println('fc_lb_change: $lb.id')
	mut dtw := ui.DrawTextWidget(fc.dtw)
	fp, id := lb.selected() or { 'classic', '' }
	// println("$id, $fp")
	w.add_font(id, fp)

	dtw.update_style(font_name: id)
}
