module component

import ui
import gx

@[heap]
pub struct AccordionComponent {
pub mut:
	layout     &ui.Stack = unsafe { nil } // required
	titles     map[string]string
	selected   map[string]bool
	views      map[string]int
	z_index    map[string]int
	text_color gx.Color
	text_size  int
	bg_color   gx.Color
}

@[params]
pub struct AccordionParams {
pub:
	id         string
	titles     []string
	children   []ui.Widget
	text_color gx.Color = gx.black
	text_size  int      = 24
	bg_color   gx.Color = gx.white
	heights    []f64    = [30.0, ui.compact]
	scrollview bool
}

// TODO: documentation
pub fn accordion_stack(c AccordionParams) &ui.Stack {
	// if c.children.len != c.titles.len {
	// }
	mut heights := [0.0]
	if c.heights.len == 2 {
		heights = c.heights.repeat(c.children.len)
	} else {
		heights = c.heights.clone()
	}
	mut layout := ui.column(
		id:         ui.component_id(c.id, 'layout')
		widths:     [ui.stretch].repeat(c.children.len * 2)
		heights:    heights
		bg_color:   c.bg_color
		scrollview: c.scrollview
	)
	mut acc := &AccordionComponent{
		layout:     layout
		text_color: c.text_color
		text_size:  c.text_size
	}
	ui.component_connect(acc, layout)
	mut title_id := ''
	for i, title in c.titles {
		title_id = c.id + '_${i}'
		title_cp := ui.canvas_plus(
			id:       title_id
			on_draw:  accordion_draw
			on_click: accordion_click
		)
		ui.component_connect(acc, title_cp)
		layout.children << title_cp
		layout.children << c.children[i]
		acc.titles[title_id] = title
		// println('$i $title_id ${acc.titles[title_id]}')
		acc.selected[title_id] = false
		acc.views[title_id] = i * 2 + 1
		acc.z_index[title_id] = c.children[i].z_index // save original z_index of child
	}
	layout.spacings = [f32(5)].repeat(layout.children.len - 1)
	// println('here $layout.children.len $acc.titles.len')
	// init component
	layout.on_init = accordion_init
	return layout
}

// component access
pub fn accordion_component(w ui.ComponentChild) &AccordionComponent {
	return unsafe { &AccordionComponent(w.component) }
}

// TODO: documentation
pub fn accordion_component_from_id(w ui.Window, id string) &AccordionComponent {
	return accordion_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

fn accordion_draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	acc := accordion_component(c)
	if acc.selected[c.id] {
		c.draw_device_triangle_filled(d, 5, 8, 12, 8, 8, 14, gx.black)
	} else {
		c.draw_device_triangle_filled(d, 7, 6, 12, 11, 7, 16, gx.black)
	}

	c.draw_device_styled_text(d, 16, 4, acc.titles[c.id], color: acc.text_color, size: acc.text_size)
}

fn accordion_click(c &ui.CanvasLayout, e ui.MouseEvent) {
	mut acc := accordion_component(c)
	// println("accordion clicked $c.id")
	acc.selected[c.id] = !acc.selected[c.id]
	if acc.selected[c.id] {
		acc.activate(c.id)
	} else {
		acc.deactivate(c.id)
	}
	// To update scrollview
	acc.layout.update_layout_without_pos()
	ui.scrollview_update(acc.layout)
	// c.ui.window.update_layout_without_pos()
	// ui.Layout(acc.layout).debug_show_children_tree(0)
}

fn (mut acc AccordionComponent) activate(id string) {
	acc.layout.set_children_depth(acc.z_index[id], acc.views[id])
}

fn (mut acc AccordionComponent) deactivate(id string) {
	acc.layout.set_children_depth(ui.z_index_hidden, acc.views[id])
}

fn accordion_init(layout &ui.Stack) {
	mut acc := accordion_component(layout)
	for id in acc.titles.keys() {
		acc.selected[id] = false
		acc.deactivate(id)
	}
	layout.ui.window.update_layout()
}
