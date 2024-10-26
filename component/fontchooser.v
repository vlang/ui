module component

import ui
import os

const fontchooser_row_id = '_row_sw_font'
const fontchooser_lb_id = '_lb_sw_font'

@[heap]
pub struct FontChooserComponent {
pub mut:
	layout &ui.Stack = unsafe { nil } // required
	dtw    ui.DrawTextWidget
}

@[params]
pub struct FontChooserParams {
pub:
	id         string             = fontchooser_lb_id
	draw_lines bool               = true
	dtw        &ui.DrawTextWidget = ui.canvas_plus() // since it requires an intialisation
}

// TODO: documentation
pub fn fontchooser_stack(c FontChooserParams) &ui.Stack {
	mut lb := ui.listbox(
		id:         c.id
		scrollview: true
		draw_lines: c.draw_lines
		on_change:  fontchooser_lb_change
	)
	fontchooser_add_fonts_items(mut lb)
	mut layout := ui.row(
		id:       fontchooser_row_id
		widths:   ui.stretch
		heights:  200.0
		children: [lb]
	)
	mut fc := &FontChooserComponent{
		layout: layout
		dtw:    c.dtw
	}
	ui.component_connect(fc, layout, lb)
	layout.on_init = fontchooser_init
	return layout
}

// TODO: documentation
pub fn fontchooser_component(w ui.ComponentChild) &FontChooserComponent {
	return unsafe { &FontChooserComponent(w.component) }
}

// TODO: documentation
pub fn fontchooser_component_from_id(w ui.Window, id string) &FontChooserComponent {
	return fontchooser_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

// TODO: documentation
pub fn fontchooser_listbox(w &ui.Window) &ui.ListBox {
	return w.get_or_panic[ui.ListBox](fontchooser_lb_id)
}

fn fontchooser_init(mut layout ui.Stack) {
	// println("${layout.size()}")
	layout.update_layout()
}

fn fontchooser_add_fonts_items(mut lb ui.ListBox) {
	font_paths := ui.font_path_list()

	for fp in font_paths {
		lb.append_item(fp, os.file_name(fp), 0)
	}
}

// TODO: documentation
pub fn fontchooser_connect(w &ui.Window, dtw ui.DrawTextWidget) {
	fc_layout := w.get_or_panic[ui.Stack](fontchooser_row_id)
	mut fc := fontchooser_component(fc_layout)
	fc.dtw = dtw
}

fn fontchooser_lb_change(lb &ui.ListBox) {
	mut w := lb.ui.window
	fc := fontchooser_component(lb)
	// println('fc_lb_change: $lb.id')
	mut dtw := ui.DrawTextWidget(fc.dtw)
	fp, id := lb.selected() or { 'classic', '' }
	// println("$id, $fp")
	w.add_font(id, fp)

	dtw.update_style(font_name: id)
}
