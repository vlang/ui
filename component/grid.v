module component

import ui

pub struct Factor {
	levels []string
	values []int
}

type GridData = Factor | []bool | []int | []string

[heap]
struct Grid {
mut:
	id      string
	layout  &ui.CanvasLayout // In fact a CanvasPlus since no children
	vars    []GridVar
	headers []string
	widths  []int
	heights []int
	tb      &ui.TextBox  = 0
	cb      &ui.CheckBox = 0
	dd      map[string]&ui.Dropdown
	// current
	pos_x int
	pos_y int
	// selection
	sel_x int = -1
	sel_y int = -1
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct GridParams {
	id     string
	vars   map[string]GridData
	width  int = 100
	height int = 30
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
	mut dd := map[string]&ui.Dropdown{}
	mut g := &Grid{
		id: p.id
		layout: layout
		headers: p.vars.keys()
		tb: ui.textbox()
	}
	ui.component_connect(g, layout)
	// mut widgets := []GridVar{}
	// check vars same length
	mut n := -1
	for name, var in p.vars {
		match var {
			[]bool {}
			[]int {}
			[]string {
				if n < 0 {
					n = var.len
				} else {
					if n != var.len {
						panic('vars need to be of same length')
					}
				}
				g.vars << grid_textbox(id: p.id + '_' + name, grid: g, var: var)
				// ui.component_connect(g, var)
			}
			Factor {
				if n < 0 {
					n = var.values.len
				} else {
					if n != var.values.len {
						panic('vars need to be of same length')
					}
				}
				dd[name] = ui.dropdown(id: 'dd_' + p.id + '_' + name, texts: var.levels)
				g.vars << grid_dropdown(id: p.id + '_' + name, grid: g, name: name, var: var)
			}
		}
	}
	g.widths = [p.width].repeat(p.vars.keys().len)
	g.heights = [p.height].repeat(n)
	g.dd = dd.clone()
	// init component
	layout.component_init = grid_init
	return layout
}

// component access
pub fn component_grid(w ui.ComponentChild) &Grid {
	return &Grid(w.component)
}

fn grid_init(layout &ui.CanvasLayout) {
	mut g := component_grid(layout)
	g.tb.init(layout)
	for _, mut dd in g.dd {
		dd.init(layout)
	}
}

fn grid_layout_draw(c &ui.CanvasLayout, app voidptr) {
	mut g := component_grid(c)
	g.pos_x = 0
	for j, var in g.vars {
		var.draw_var(j, mut g)
		g.pos_x += g.widths[j]
	}
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

interface GridVar {
	id string
	grid &Grid
	draw_var(j int, mut g Grid)
	// component voidptr
}

// TextBox GridVar
[heap]
struct GridTextBox {
	grid &Grid
mut:
	id  string
	var []string
}

pub struct GridTextBoxParams {
	id   string
	grid &Grid
	var  []string
}

pub fn grid_textbox(p GridTextBoxParams) &GridTextBox {
	return &GridTextBox{
		grid: p.grid
		var: p.var
	}
}

fn (gtb &GridTextBox) draw_var(j int, mut g Grid) {
	mut tb := g.tb
	g.pos_y = 0
	// println("dv $j $gtb.var.len")
	for i in 0 .. gtb.var.len {
		// println("$i) $g.pos_x, $g.pos_y")
		tb.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]}")
		tb.propose_size(g.widths[j], g.heights[i])
		tb.read_only = i != g.sel_x || j != g.sel_y
		tb.text = &gtb.var[i]
		tb.draw()
		g.pos_y += g.heights[i]
	}
}

// Dropdown GridVar
[heap]
struct GridDropdown {
	grid &Grid
mut:
	id   string
	name string
	var  Factor
	// component voidptr
}

pub struct GridDropdownParams {
	id   string
	grid &Grid
	name string
	var  Factor
}

pub fn grid_dropdown(p GridDropdownParams) &GridDropdown {
	return &GridDropdown{
		grid: p.grid
		var: p.var
		name: p.name
	}
}

fn (gdd &GridDropdown) draw_var(j int, mut g Grid) {
	mut dd := g.dd[gdd.name]
	g.pos_y = 0
	// println("ddd $j $gdd.var.values.len")
	for i in 0 .. gdd.var.values.len {
		// println("$i) $g.pos_x, $g.pos_y")
		dd.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]}")
		dd.propose_size(g.widths[j], g.heights[i])
		dd.selected_index = gdd.var.values[i]
		dd.open = false
		dd.z_index = if i == g.sel_x && j == g.sel_y { 10 } else { 0 }
		dd.draw()
		g.pos_y += g.heights[i]
	}
}

// CheckBox GridVar
[heap]
struct GridCheckBox {
	grid &Grid
mut:
	id  string
	cb  &ui.CheckBox
	var []bool
	// component voidptr
}

pub fn grid_checkbox() { //&GridCheckBox {
}

fn (gtb &GridCheckBox) draw_var(j int, mut g Grid) {
}
