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
	layout    &ui.CanvasLayout
	vars      []GridVar
	types     []GridType
	headers   []string
	widths    []int
	heights   []int
	nrow      int
	ncol      int
	tb_string &ui.TextBox  = 0
	cb_bool   &ui.CheckBox = 0
	dd_factor map[string]&ui.Dropdown
	tb_colbar &ui.TextBox = 0
	tb_rowbar &ui.TextBox = 0
	// selectors
	selectors []ui.Widget
	// sizes
	rowbar_width  int = 80
	colbar_height int = 30
	// index for swap of rows
	index []int
	// current
	pos_x int
	pos_y int
	// selection
	sel_i int = -1
	sel_j int = -1
	// from
	from_x int
	from_y int
	from_i int
	to_i   int
	from_j int
	to_j   int
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct GridParams {
	id         string
	vars       map[string]GridData
	width      int = 100
	height     int = 30
	scrollview bool
}

pub fn grid(p GridParams) &ui.CanvasLayout {
	mut layout := ui.canvas_layout(
		id: p.id + '_layout'
		scrollview: p.scrollview
		on_draw: grid_draw
		on_click: grid_click
		on_mouse_down: grid_mouse_down
		on_mouse_up: grid_mouse_up
		on_scroll: grid_scroll
		on_mouse_move: grid_mouse_move
		on_key_down: grid_key_down
		on_char: grid_char
		full_size_fn: grid_full_size
		on_scroll_change: grid_scroll_change
	)
	mut dd := map[string]&ui.Dropdown{}
	mut g := &Grid{
		id: p.id
		layout: layout
		headers: p.vars.keys()
		tb_string: ui.textbox(id: 'tb_ro_' + p.id)
	}
	ui.component_connect(g, layout)
	// check vars same length
	g.nrow = -1
	g.ncol = p.vars.len
	for name, var in p.vars {
		match var {
			[]bool {
				g.types << .cb_bool
			}
			[]int {
				g.types << .tb_int
			}
			[]string {
				g.types << .tb_string
				g.set_check_nrow(var.len)
				g.vars << grid_textbox(id: p.id + '_' + name, grid: g, var: var)
			}
			Factor {
				g.types << .dd_factor
				g.set_check_nrow(var.values.len)
				dd[name] = ui.dropdown(id: 'dd_ro_' + p.id + '_' + name, texts: var.levels)
				g.vars << grid_dropdown(id: p.id + '_' + name, grid: g, name: name, var: var)
				mut dd_sel := ui.dropdown(
					id: 'dd_sel_' + p.id + '_' + name
					texts: var.levels
					on_selection_changed: grid_dd_changed
				)
				dd_sel.set_visible(false)
				layout.children << dd_sel
				g.selectors << dd_sel
				ui.component_connect(g, dd_sel)
			}
		}
	}
	mut tb_sel := ui.textbox(
		id: 'tb_sel_' + p.id
		on_entered: grid_tb_entered
	)
	tb_sel.set_visible(false)
	layout.children << tb_sel
	g.selectors << tb_sel
	ui.component_connect(g, tb_sel)

	g.tb_colbar = ui.textbox(id: 'tb_colbar_' + p.id, bg_color: gx.light_blue, read_only: true)
	g.tb_colbar.set_visible(false)

	g.tb_rowbar = ui.textbox(id: 'tb_rowbar_' + p.id, bg_color: gx.light_gray, read_only: true)
	g.tb_rowbar.set_visible(false)

	g.widths = [p.width].repeat(p.vars.keys().len)
	g.heights = [p.height].repeat(g.nrow)
	g.dd_factor = dd.clone()
	layout.component_init = grid_init
	return layout
}

// component access
pub fn component_grid(w ui.ComponentChild) &Grid {
	return &Grid(w.component)
}

fn grid_init(mut layout ui.CanvasLayout) {
	mut g := component_grid(layout)
	g.tb_string.init(layout)
	for _, mut dd in g.dd_factor {
		dd.init(layout)
	}
	g.tb_colbar.init(layout)
	g.tb_rowbar.init(layout)
	g.visible_cells()
}

fn grid_draw(c &ui.CanvasLayout, app voidptr) {
	// println("draw begin")
	// println("grid size: $w, $h ${ui.has_scrollview(c)}")
	mut g := component_grid(c)
	// g.visible_cells()
	g.pos_x = g.from_x + c.x + c.offset_x
	// println("$g.rowbar_width == $g.pos_x")

	for j in g.from_j .. g.to_j {
		g.vars[j].draw(j, mut g)
		g.pos_x += g.widths[j]
		// println("draw $j")
	}

	g.draw_rowbar()
	g.draw_colbar()
	ui.scrollview_update(c)
	// println("draw end")
}

fn (mut g Grid) draw_colbar() {
	mut tb := g.tb_colbar
	tb.is_focused = false
	tb.read_only = true
	tb.set_visible(false)
	g.pos_x = g.rowbar_width + g.layout.x + g.layout.offset_x
	g.pos_y = 0
	for j, var in g.headers {
		tb.set_pos(g.pos_x, 0)
		// println("$i) ${g.widths[j]}, ${g.heights[i]} ${gtb.var[i]}")
		tb.propose_size(g.widths[j], g.colbar_height)
		unsafe {
			*tb.text = var.clone()
		}
		tb.draw()
		g.pos_x += g.widths[j]
	}
	tb.set_pos(0, 0)
	tb.propose_size(g.rowbar_width, g.colbar_height)
	unsafe {
		*tb.text = ''
	}
	tb.draw()
}

fn (mut g Grid) draw_rowbar() {
	mut tb := g.tb_rowbar
	tb.is_focused = false
	tb.read_only = true
	tb.set_visible(false)
	g.pos_x = g.layout.x + g.layout.offset_x
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	for i in g.from_i .. g.to_i {
		tb.set_pos(0, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]} ${gtb.var[i]}")
		tb.propose_size(g.rowbar_width, g.heights[i])
		unsafe {
			*tb.text = '${i + 1}'
		}
		tb.draw()
		g.pos_y += g.heights[i]
	}
}

fn (mut g Grid) set_check_nrow(var_len int) {
	if g.nrow < 0 {
		g.nrow = var_len
	} else {
		if g.nrow != var_len {
			panic('All vars need to be of same length')
		}
	}
}

fn grid_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	// println('grid_click')
	mut g := component_grid(c)
	g.sel_i, g.sel_j = g.get_index_pos(e.x, e.y)
	// println('selected: $g.sel_i, $g.sel_j')
	g.show_selected()
	$if grid_click ? {
		println('${g.layout.get_children().map(it.id)}')
	}
}

fn grid_mouse_down(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_mouse_up(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_scroll(e ui.ScrollEvent, c &ui.CanvasLayout) {}

fn grid_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {}

fn grid_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {}

fn grid_char(e ui.KeyEvent, c &ui.CanvasLayout) {}

fn grid_full_size(mut c ui.CanvasLayout) (int, int) {
	w, h := component_grid(c).size()
	c.adj_width, c.adj_height = w, h
	return w, h
}

fn grid_scroll_change(sw ui.ScrollableWidget) {
	if sw is ui.CanvasLayout {
		mut g := component_grid(sw)
		g.visible_cells()
	}
}

fn grid_tb_entered(mut tb ui.TextBox, a voidptr) {
	mut g := component_grid(tb)
	mut gtb := g.vars[g.sel_j]
	if mut gtb is GridTextBox {
		gtb.var[g.sel_i] = (*tb.text).clone()
		// println("gtb.var = ${gtb.var}")
	}
	unsafe {
		*tb.text = ''
	}
	tb.set_visible(false)
	tb.z_index = ui.z_index_hidden
	g.layout.update_layout()
	// println("tb_entered: ${g.layout.get_children().map(it.id)}")
}

fn grid_dd_changed(a voidptr, mut dd ui.Dropdown) {
	// println('$dd.id  selection changed $dd.selected_index')
	mut g := component_grid(dd)
	mut gdd := g.vars[g.sel_j]
	if mut gdd is GridDropdown {
		gdd.var.values[g.sel_i] = dd.selected_index
		// println('$dd.id  selection changed: gdd.var($g.sel_j).values[$g.sel_i] = dd.selected_index $dd.selected_index')
	}
	dd.set_visible(false)
	dd.z_index = ui.z_index_hidden
	g.layout.update_layout()
}

fn (g &Grid) size() (int, int) {
	return (arrays.sum(g.widths) or { -1 }) + g.rowbar_width, (arrays.sum(g.heights) or { -1 }) +
		g.colbar_height
}

fn (mut g Grid) show_selected() {
	if g.sel_i < 0 || g.sel_j < 0 {
		return
	}
	for mut sel in g.selectors {
		sel.set_visible(false)
		sel.set_depth(ui.z_index_hidden)
	}
	// type
	name := g.headers[g.sel_j]
	match g.types[g.sel_j] {
		.tb_string {
			id := 'tb_sel_' + g.id
			// println('tb_sel $id selected')
			mut tb := g.layout.ui.window.textbox(id)
			tb.set_visible(true)
			// println('tb $tb.id')
			tb.z_index = 1000
			pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
			g.layout.set_child_relative_pos(id, pos_x, pos_y)
			tb.propose_size(g.widths[g.sel_j], g.heights[g.sel_i])
			tb.focus()
			gtb := g.vars[g.sel_j]
			if gtb is GridTextBox {
				unsafe {
					*(tb.text) = gtb.var[g.sel_i]
				}
			}
			tb.bg_color = gx.orange
		}
		.dd_factor {
			id := 'dd_sel_' + g.id + '_' + name
			// println('dd_sel $id selected $g.sel_i, $g.sel_j')
			mut dd := g.layout.ui.window.dropdown(id)
			dd.set_visible(true)
			dd.z_index = 1000
			pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
			g.layout.set_child_relative_pos(id, pos_x, pos_y)
			dd.propose_size(g.widths[g.sel_j], g.heights[g.sel_i])
			dd.focus()
			gdd := g.vars[g.sel_j]
			if gdd is GridDropdown {
				dd.selected_index = gdd.var.values[g.sel_i]
			}
			dd.bg_color = gx.orange
		}
		else {}
	}
	g.layout.update_layout()
}

fn (g &Grid) get_index_pos(x int, y int) (int, int) {
	mut cum := g.rowbar_width
	mut sel_i, mut sel_j := -1, -1
	for j, w in g.widths {
		cum += w
		if x > g.rowbar_width && x < cum {
			sel_j = j
			break
		}
	}
	cum = g.colbar_height
	for i, h in g.heights {
		cum += h
		if y > g.colbar_height && y < cum {
			sel_i = i
			break
		}
	}
	return sel_i, sel_j
}

fn (g &Grid) get_pos(i int, j int) (int, int) {
	mut x, mut y := g.rowbar_width, g.colbar_height
	for k in 0 .. i {
		y += g.heights[k]
	}
	for k in 0 .. j {
		x += g.widths[k]
	}
	return x, y
}

fn (mut g Grid) visible_cells() {
	if g.layout.has_scrollview {
		g.from_i, g.to_i, g.from_y = -1, -1, 0
		mut cum := g.colbar_height // g.layout.x + g.layout.offset_x
		for i, h in g.heights {
			if g.from_i < 0 && cum > g.layout.scrollview.offset_y {
				g.from_i = i
				g.from_y = cum
			}
			if g.from_i >= 0 && g.to_i < 0 && cum > g.layout.scrollview.offset_y + g.layout.height {
				g.to_i = i + 1
				if g.to_i > g.nrow {
					g.to_i = g.nrow
				}
				break
			}
			cum += h
		}
		if g.to_i < 0 {
			g.to_i = g.nrow
		}
	} else {
		g.from_i, g.to_i, g.from_y = 0, g.nrow, 0
	}
	// println("vc $g.from_i, $g.to_i, $g.from_y")

	if g.layout.has_scrollview {
		g.from_j, g.to_j, g.from_x = -1, -1, 0
		mut cum := g.rowbar_width
		for j, w in g.widths {
			if g.from_j < 0 && cum > g.layout.scrollview.offset_x {
				g.from_j = j
				g.from_x = cum
			}
			if g.from_j >= 0 && g.to_j < 0 && cum > g.layout.scrollview.offset_x + g.layout.width {
				g.to_j = j + 1
				if g.to_j > g.ncol {
					g.to_j = g.ncol
				}
				break
			}
			cum += w
		}
		if g.to_j < 0 {
			g.to_j = g.ncol
		}
	} else {
		g.from_j, g.to_j, g.from_x = 0, g.ncol, 0
	}
}

interface GridVar {
	id string
	grid &Grid
	draw(j int, mut g Grid)
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

fn (gtb &GridTextBox) draw(j int, mut g Grid) {
	mut tb := g.tb_string
	tb.is_focused = false
	tb.read_only = true
	tb.set_visible(false)
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	// println("dv $j $gtb.var.len")
	for i in g.from_i .. g.to_i {
		// println("$i) $g.pos_x, $g.pos_y")
		tb.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]} ${gtb.var[i]}")
		tb.propose_size(g.widths[j], g.heights[i])
		unsafe {
			*tb.text = gtb.var[i].clone()
		}
		// g.layout.update_layout()
		// println("draw var tb $j: ${g.layout.get_children().map(it.id)}")
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

fn (gdd &GridDropdown) draw(j int, mut g Grid) {
	mut dd := g.dd_factor[gdd.name]
	dd.set_visible(false)
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	// println("ddd $j $gdd.var.values.len")
	for i in g.from_i .. g.to_i {
		// println("$i) $g.pos_x, $g.pos_y")
		dd.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.heights[i]}")
		dd.propose_size(g.widths[j], g.heights[i])
		dd.selected_index = gdd.var.values[i]
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
}

pub fn grid_checkbox() { //&GridCheckBox {
}

fn (gtb &GridCheckBox) draw(j int, mut g Grid) {
}
