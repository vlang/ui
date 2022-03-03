module component

import ui
import arrays
import gx

pub struct Factor {
mut:
	levels []string
	values []int
}

enum GridType {
	tb_string
	tb_int
	cb_bool
	dd_factor
}

type GridData = Factor | []bool | []int | []string

[heap]
struct Grid {
mut:
	id        string
	layout    &ui.CanvasLayout // In fact a CanvasPlus since no children
	vars      []GridVar
	types     []GridType
	headers   []string
	widths    []int
	heights   []int
	lb_header map[string]&ui.Label
	tb_string &ui.TextBox  = 0
	cb_bool   &ui.CheckBox = 0
	dd_factor map[string]&ui.Dropdown
	// current
	pos_x int
	pos_y int
	// selection
	sel_i int = -1
	sel_j int = -1
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
	mut layout := ui.canvas_layout(
		on_draw: grid_draw
		on_click: grid_click
		on_mouse_down: grid_mouse_down
		on_mouse_up: grid_mouse_up
		on_scroll: grid_scroll
		on_mouse_move: grid_mouse_move
		on_key_down: grid_key_down
		on_char: grid_char
		full_size_fn: grid_full_size
	)
	mut dd := map[string]&ui.Dropdown{}
	mut lb := map[string]&ui.Label{}
	mut g := &Grid{
		id: p.id
		layout: layout
		headers: p.vars.keys()
		tb_string: ui.textbox()
	}
	ui.component_connect(g, layout)
	// mut widgets := []GridVar{}
	// check vars same length
	mut n := -1
	for name, var in p.vars {
		lb[name] = ui.label(id: 'lb_' + p.id + '_' + name, text: name)
		match var {
			[]bool {
				g.types << .cb_bool
			}
			[]int {
				g.types << .tb_int
			}
			[]string {
				g.types << .tb_string
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
				g.types << .dd_factor
				if n < 0 {
					n = var.values.len
				} else {
					if n != var.values.len {
						panic('vars need to be of same length')
					}
				}
				dd[name] = ui.dropdown(id: 'dd_ro_' + p.id + '_' + name, texts: var.levels)
				g.vars << grid_dropdown(id: p.id + '_' + name, grid: g, name: name, var: var)
				dd_sel := ui.dropdown(
					id: 'dd_sel_' + p.id + '_' + name
					texts: var.levels
					z_index: ui.z_index_hidden
					on_selection_changed: grid_dd_changed
				)
				layout.children << dd_sel
				ui.component_connect(g, dd_sel)
			}
		}
	}
	g.widths = [p.width].repeat(p.vars.keys().len)
	g.heights = [p.height].repeat(n)
	w, h := g.size()
	layout.propose_size(w, h)
	g.dd_factor = dd.clone()
	g.lb_header = lb.clone()
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
	g.tb_string.init(layout)
	for _, mut dd in g.dd_factor {
		dd.init(layout)
	}
}

fn grid_draw(c &ui.CanvasLayout, app voidptr) {
	mut g := component_grid(c)
	g.pos_x = 0
	for j, var in g.vars {
		var.draw_var(j, mut g)
		g.pos_x += g.widths[j]
	}
}

fn grid_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	//
	println('grid_click')
	mut g := component_grid(c)
	g.sel_i, g.sel_j = g.get_index_pos(e.x, e.y)
	println('selected: $g.sel_i, $g.sel_j')
	g.show_selected()
	println('${g.layout.get_children().map(it.id)}')
	// selected := i == g.sel_y && j == g.sel_x
	// dd.open = selected
	// dd.is_focused = selected
	// dd.z_index = if selected { 100 } else { 0 }
}

fn grid_mouse_down(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_mouse_up(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_scroll(e ui.ScrollEvent, c &ui.CanvasLayout) {}

fn grid_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {}

fn grid_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {}

fn grid_char(e ui.KeyEvent, c &ui.CanvasLayout) {}

fn grid_full_size(c &ui.CanvasLayout) (int, int) {
	return component_grid(c).size()
}

fn grid_dd_changed(a voidptr, dd &ui.Dropdown) {
	println('$dd.id selection changed $dd.selected_index')
	mut g := component_grid(dd)
	mut gdd := g.vars[g.sel_j]
	if mut gdd is GridDropdown {
		gdd.var.values[g.sel_i] = dd.selected_index
	}
}

fn (g &Grid) size() (int, int) {
	return arrays.sum(g.widths) or { -1 }, arrays.sum(g.heights) or { -1 }
}

fn (mut g Grid) show_selected() {
	// type
	name := g.headers[g.sel_j]
	match g.types[g.sel_j] {
		.tb_string {}
		.dd_factor {
			id := 'dd_sel_' + g.id + '_' + name
			//
			println('dd_Sel $id selected')
			mut dd := g.layout.ui.window.dropdown(id)
			dd.z_index = 1000
			pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
			dd.set_pos(pos_x, pos_y)
			dd.propose_size(g.widths[g.sel_j], g.heights[g.sel_i])
			dd.focus()
			gdd := g.vars[g.sel_j]
			if gdd is GridDropdown {
				dd.selected_index = gdd.var.values[g.sel_i]
			}
			dd.bg_color = gx.orange
			g.layout.update_layout()
		}
		else {}
	}
}

fn (g &Grid) get_index_pos(x int, y int) (int, int) {
	mut cum := 0
	mut sel_i, mut sel_j := -1, -1
	for j, w in g.widths {
		cum += w
		if x < cum {
			sel_j = j
			break
		}
	}
	cum = 0
	for i, h in g.heights {
		cum += h
		if y < cum {
			sel_i = i
			break
		}
	}
	return sel_i, sel_j
}

fn (g &Grid) get_pos(i int, j int) (int, int) {
	mut x, mut y := 0, 0
	for k in 0 .. i {
		y += g.heights[k]
	}
	for k in 0 .. j {
		x += g.widths[k]
	}
	return x, y
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
	mut tb := g.tb_string
	g.pos_y = 0
	// println("dv $j $gtb.var.len")
	for i in 0 .. gtb.var.len {
		// println("$i) $g.pos_x, $g.pos_y")
		tb.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]}")
		tb.propose_size(g.widths[j], g.heights[i])
		tb.is_focused = false
		tb.read_only = true
		tb.set_visible(false)
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
	mut dd := g.dd_factor[gdd.name]
	g.pos_y = 0
	// println("ddd $j $gdd.var.values.len")
	for i in 0 .. gdd.var.values.len {
		// println("$i) $g.pos_x, $g.pos_y")
		dd.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]}")
		dd.propose_size(g.widths[j], g.heights[i])
		dd.selected_index = gdd.var.values[i]
		// dd.is_focused = false
		// dd.open = false
		dd.set_visible(false)
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
