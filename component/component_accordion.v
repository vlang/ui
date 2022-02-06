module component

import ui
import gx

const (
	accordion_layout_id = '_cvl_accordion'
)

[heap]
struct Accordion {
pub mut:
	layout     &ui.Stack // required
	titles     map[string]string
	selected   map[string]bool
	views      map[string]int
	text_color gx.Color
	text_size  int
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct AccordionParams {
	id         string
	titles     []string
	children   []ui.Widget
	text_color gx.Color = gx.black
	text_size  int      = 24
}

pub fn accordion(c AccordionParams) &ui.Stack {
	if c.children.len != c.titles.len {
	}
	mut layout := ui.column(
		id: c.id + component.accordion_layout_id
		widths: [ui.stretch].repeat(c.children.len * 2)
		heights: [30.0, ui.compact].repeat(c.children.len)
	)
	mut acc := &Accordion{
		layout: layout
		text_color: c.text_color
		text_size: c.text_size
	}
	ui.component_connect(acc, layout)
	mut children := []ui.Widget{}
	mut title_id := ''
	for i, title in c.titles {
		title_id = c.id + '_$i'
		title_cp := ui.canvas_plus(
			id: title_id
			on_draw: accordion_draw
			on_click: accordion_click
		)
		ui.component_connect(acc, title_cp)
		children << title_cp
		children << c.children[i]
		acc.titles[title_id] = title
		println('$i $title_id ${acc.titles[title_id]}')
		acc.selected[title_id] = true
		acc.views[title_id] = i * 2 + 1
	}
	layout.children = children
	layout.spacings = [f32(5)].repeat(children.len - 1)
	println('here $layout.children.len $acc.titles.len')
	return layout
}

// component access
pub fn component_accordion(w ui.ComponentChild) &Accordion {
	return &Accordion(w.component)
}

fn accordion_draw(c &ui.CanvasLayout, state voidptr) {
	acc := component_accordion(c)
	if acc.selected[c.id] {
		c.draw_triangle_filled(5, 8, 12, 8, 8, 14, gx.black)
	} else {
		c.draw_triangle_filled(7, 6, 12, 11, 7, 16, gx.black)
	}

	c.draw_styled_text(16, 4, acc.titles[c.id], color: acc.text_color, size: acc.text_size)
}

fn accordion_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut acc := component_accordion(c)
	acc.selected[c.id] = !acc.selected[c.id]
	if acc.selected[c.id] {
		acc.layout.set_children_depth(0, acc.views[c.id])
	} else {
		acc.layout.set_children_depth(ui.z_index_hidden, acc.views[c.id])
	}
	c.ui.window.update_layout()
}
