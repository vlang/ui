module component

import ui

type GridData = []bool | []int | []string

[heap]
struct Grid {
	layout  &ui.CanvasLayout // In fact a CanvasPlus since no children
	widgets []GridColumn
	headers []string
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct GridParams {
	data map[string]GridData
}

pub fn grid(p GridParams) &ui.CanvasLayout {
	mut layout := ui.canvas_plus(
		on_draw: grid_layout_draw
		on_click: grid_layout_click
		on_mouse_down: grid_layout_mouse_down
		on_mouse_up: grid_layout_mouse_up
		on_scroll: grid_layout_scroll
		on_mouse_move: grid_layout_mouse_move
		on_key_down: grid_layout_key_down
		on_char: grid_layout_char
		full_size_fn: grid_layout_full_size
	)
	gl := &Grid{
		layout: layout
		headers: p.data.keys()
	}
	ui.component_connect(gl, layout)
	return layout
}

// component access
pub fn component_grid_layout(w ui.ComponentChild) &Grid {
	return &Grid(w.component)
}

fn grid_layout_draw(c &ui.CanvasLayout, app voidptr) {
	gl := component_grid_layout(c)
}

fn grid_layout_click(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_layout_mouse_down(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_layout_mouse_up(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_layout_scroll(e ui.ScrollEvent, c &ui.CanvasLayout) {}

fn grid_layout_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {}

fn grid_layout_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {}

fn grid_layout_char(e ui.KeyEvent, c &ui.CanvasLayout) {}

fn grid_layout_full_size(c &ui.CanvasLayout) (int, int) {
	return 0, 0
}

interface GridColumn {
	grid_layout &Grid
	draw()
}

// TextBox GridColumn
[heap]
struct GridTextBox {
	grid_layout &Grid
mut:
	tb   &ui.TextBox
	data []string
}

pub fn grid_textbox() { //&GridTextBox {
}

// Dropdown GridColumn
[heap]
struct GridDropDown {
	grid_layout &Grid
mut:
	dd   &ui.Dropdown
	data []int
}

pub fn grid_dropdown() { // &GridDropDown {
}

// CheckBox GridColumn
[heap]
struct GridCheckBox {
	grid_layout &Grid
mut:
	cb   &ui.CheckBox
	data []bool
}

pub fn grid_checkbox() { //&GridCheckBox {
}
