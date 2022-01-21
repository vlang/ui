module component

import ui

[heap]
struct GridLayout {
	layout  &ui.CanvasLayout
	widgets []GridColumn
	// To become a component of a parent component
	component voidptr
}

pub fn grid_layout() { // &GridLayout {
	// return
}

fn (gl GridLayout) draw() {

}

interface GridColumn {
	grid_layout &GridLayout
	draw()
}

// TextBox GridColumn
[heap]
struct GridTextBox {
	grid_layout &GridLayout
mut:
	tb 			&ui.TextBox
	data		[]string
}

pub fn grid_textbox() {//&GridTextBox {
}

// Dropdown GridColumn
[heap]
struct GridDropDown {
	grid_layout &GridLayout
mut:
	dd 			&ui.Dropdown
	data		[]int
}

pub fn grid_dropdown() {// &GridDropDown {

}

// CheckBox GridColumn
[heap]
struct GridCheckBox {
	grid_layout &GridLayout
mut:
	cb 			&ui.CheckBox
	data 		[]bool
}

pub fn grid_checkbox() {//&GridCheckBox {
}
