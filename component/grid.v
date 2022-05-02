module component

import ui
import arrays
import gx
import math

pub struct Factor {
mut:
	levels []string
	values []int
}

enum GridType {
	tb_string
	tb_int
	tb_float
	cb_bool
	dd_factor
}

type GridData = Factor | []bool | []int | []string

[heap]
struct GridComponent {
pub mut:
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
	colbar_height int = 25
	header_size   int = 3
	// height
	cell_height int // when > 0 all cells have same height to speed up visible_cells
	min_height  int
	// index for swap of rows
	index []int
	// current
	cur_i int
	cur_j int
	// position
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
	// shortcuts
	shortcuts ui.Shortcuts
}

[params]
pub struct GridParams {
	vars         map[string]GridData
	width        int = 100
	height       int = 25
	scrollview   bool
	is_focused   bool
	fixed_height bool = true
mut:
	id string
}

pub fn grid_canvaslayout(p GridParams) &ui.CanvasLayout {
	mut layout := ui.canvas_layout(
		id: ui.component_id(p.id, 'layout')
		scrollview: p.scrollview
		is_focused: p.is_focused
		on_draw: grid_draw
		on_post_draw: grid_post_draw
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
	mut g := &GridComponent{
		id: p.id
		layout: layout
		headers: p.vars.keys()
		tb_string: ui.textbox(id: ui.component_id(p.id, 'tb_ro'))
		cb_bool: ui.checkbox(id: ui.component_id(p.id, 'cb_ro'), justify: [0.5, 0.5])
	}
	ui.component_connect(g, layout)
	// check vars same length
	g.nrow = -1
	g.ncol = p.vars.len
	for name, var in p.vars {
		match var {
			[]bool {
				g.types << .cb_bool
				g.set_check_nrow(var.len)
				g.vars << grid_checkbox(
					id: ui.component_id(p.id, 'cb_' + name)
					grid: g
					var: var
				)
			}
			[]int {
				g.types << .tb_int
			}
			[]string {
				g.types << .tb_string
				g.set_check_nrow(var.len)
				g.vars << grid_textbox(
					id: ui.component_id(p.id, 'tb_' + name)
					grid: g
					var: var
				)
			}
			Factor {
				g.types << .dd_factor
				g.set_check_nrow(var.values.len)
				dd[name] = ui.dropdown(
					id: ui.component_id(p.id, 'dd_ro_' + name)
					texts: var.levels
				)
				g.vars << grid_dropdown(
					id: ui.component_id(p.id, 'dd_' + name)
					grid: g
					name: name
					var: var
				)
				mut dd_sel := ui.dropdown(
					id: ui.component_id(p.id, 'dd_sel_' + name)
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
	// textbox selector
	mut tb_sel := ui.textbox(
		id: ui.component_id(p.id, 'tb_sel')
		on_entered: grid_tb_entered
	)
	// println("tb_sel $tb_sel.id created inside $p.id")
	tb_sel.set_visible(false)
	layout.children << tb_sel
	g.selectors << tb_sel
	ui.component_connect(g, tb_sel)

	// checkbox selector
	mut cb_sel := ui.checkbox(
		id: ui.component_id(p.id, 'cb_sel')
		on_click: grid_cb_clicked
	)
	// println("cb_sel $cb_sel.id created inside $p.id")
	cb_sel.set_visible(false)
	layout.children << cb_sel
	g.selectors << cb_sel
	ui.component_connect(g, cb_sel)

	// column bar textbox
	g.tb_colbar = ui.textbox(
		id: ui.component_id(p.id, 'tb_colbar')
		bg_color: gx.light_blue
		read_only: true
	)
	g.tb_colbar.set_visible(false)

	// row bar textbox
	g.tb_rowbar = ui.textbox(
		id: ui.component_id(p.id, 'tb_rowbar')
		bg_color: gx.light_gray
		read_only: true
	)
	g.tb_rowbar.set_visible(false)

	g.widths = [p.width].repeat(p.vars.keys().len)
	// g.index = []int{len: g.nrow, init: it}.reverse()
	if p.fixed_height {
		// g.heights.len == 0
		g.cell_height = p.height
	} else {
		// g.cell_height == 0
		g.heights = [p.height].repeat(g.nrow())
	}
	g.min_height = p.height
	g.dd_factor = dd.clone()
	layout.on_init = grid_init
	return layout
}

// component access
pub fn grid_component(w ui.ComponentChild) &GridComponent {
	return &GridComponent(w.component)
}

pub fn grid_component_from_id(w ui.Window, id string) &GridComponent {
	return grid_component(w.canvas_layout(ui.component_id(id, 'layout')))
}

fn grid_init(mut layout ui.CanvasLayout) {
	mut g := grid_component(layout)
	g.tb_string.init(layout)
	g.cb_bool.init(layout)

	for _, mut dd in g.dd_factor {
		dd.init(layout)
		dd.set_visible(false)
	}
	g.tb_colbar.init(layout)
	g.tb_rowbar.init(layout)
	g.visible_cells()
	ui.lock_scrollview_key(layout)
}

// callbacks

fn grid_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	//
	println('grid_click $e.x $e.y')
	mut g := grid_component(c)
	g.sel_i, g.sel_j = g.get_index_pos(e.x, e.y)
	rx, ry := g.layout.abs_pos(g.rowbar_width, g.colbar_height)
	ex, ey := g.layout.orig_pos(e.x, e.y)
	colbar := ey < ry
	rowbar := ex < rx
	if colbar && rowbar {
		println('both')
	} else if colbar {
		println('colbar $g.sel_j')
		g.colbar_selected()
	} else if rowbar {
		println('rowbar $g.sel_i')
	} else {
		//
		println('selected: $g.sel_i, $g.sel_j')
		g.show_selected()
		$if grid_click ? {
			println('${g.layout.get_children().map(it.id)}')
		}
	}
}

fn grid_mouse_down(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_mouse_up(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn grid_scroll(e ui.ScrollEvent, c &ui.CanvasLayout) {
}

fn grid_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	mut g := grid_component(c)
	colbar := e.y < g.colbar_height - c.y - c.offset_y
	rowbar := e.x < g.rowbar_width - c.x - c.offset_x
	if colbar {
		// println("move colbar ($e.x, $e.y)")
	} else if rowbar {
		// println("move rowbar ($e.x, $e.y)")
	}
}

fn grid_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {
	$if grid_key ? {
		println('key_down $e')
	}
	mut g := grid_component(c)
	if g.is_selected() {
		if e.key == .escape {
			println('here')
			g.unselect()
			g.layout.update_layout()
		}
		return
	}
	match e.key {
		.up {
			// println('up')
			if g.cur_i > 0 {
				g.cur_i -= 1
			}
		}
		.down {
			// println('down')
			if g.cur_i < g.nrow() - 1 {
				g.cur_i += 1
			}
		}
		.left {
			// println('left')
			g.cur_j -= 1
			if g.cur_j == -1 {
				if g.cur_i == 0 {
					g.cur_j += 1 // revert
				} else {
					g.cur_i -= 1
					g.cur_j = g.ncol - 1
				}
			}
		}
		.right {
			// println('right')
			g.cur_j += 1
			if g.cur_j == g.ncol {
				if g.cur_i == g.nrow() - 1 {
					g.cur_j -= 1 // revert
				} else {
					g.cur_i += 1
					g.cur_j = 0
				}
			}
		}
		.page_up {
			g.cur_i = math.max(g.cur_i - g.to_i + g.from_i + 2, 0)
			g.cur_allways_visible()
		}
		.page_down {
			g.cur_i = math.min(g.cur_i + g.to_i - g.from_i - 2, g.nrow() - 1)
			g.cur_allways_visible()
		}
		.home {
			g.cur_i, g.cur_j = 0, 0
			g.cur_allways_visible()
		}
		.end {
			g.cur_i, g.cur_j = g.nrow() - 1, g.ncol - 1
			g.cur_allways_visible()
		}
		else {
			ui.key_shortcut(e, g.shortcuts, g)
		}
	}
	g.cur_allways_visible()
}

fn grid_char(e ui.KeyEvent, c &ui.CanvasLayout) {
	mut g := grid_component(c)
	s := utf32_to_str(e.codepoint)
	$if grid_char ? {
		println('char $e <$s>')
	}
	if ui.ctrl_key(e.mods) {
		match e.codepoint {
			1 {
				g.cur_i, g.cur_j = 0, 0
				g.cur_allways_visible()
			}
			5 {
				g.cur_i, g.cur_j = g.nrow() - 1, g.ncol - 1
				g.cur_allways_visible()
			}
			else {
				ui.char_shortcut(e, g.shortcuts, g)
			}
		}
	}
}

fn grid_full_size(mut c ui.CanvasLayout) (int, int) {
	w, h := grid_component(c).size()
	c.adj_width, c.adj_height = w, h
	return w, h
}

fn grid_scroll_change(sw ui.ScrollableWidget) {
	if sw is ui.CanvasLayout {
		mut g := grid_component(sw)
		g.visible_cells()
	}
}

fn grid_tb_entered(mut tb ui.TextBox, a voidptr) {
	mut g := grid_component(tb)
	mut gtb := g.vars[g.sel_j]
	if mut gtb is GridTextBox {
		gtb.var[g.ind(g.sel_i)] = (*tb.text).clone()
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
	mut g := grid_component(dd)
	mut gdd := g.vars[g.sel_j]
	if mut gdd is GridDropdown {
		gdd.var.values[g.ind(g.sel_i)] = dd.selected_index
		// println('$dd.id  selection changed: gdd.var($g.sel_j).values[$g.sel_i] = dd.selected_index $dd.selected_index')
	}
	dd.set_visible(false)
	dd.z_index = ui.z_index_hidden
	g.layout.update_layout()
}

fn grid_cb_clicked(mut cb ui.CheckBox, state voidptr) {
	mut g := grid_component(cb)
	mut gcb := g.vars[g.sel_j]
	if mut gcb is GridCheckBox {
		gcb.var[g.ind(g.sel_i)] = cb.checked
		// println('$cb.id  selection changed: gcb.var($g.sel_j).values[$g.sel_i] = cb.checked')
	}
	cb.set_visible(false)
	cb.z_index = ui.z_index_hidden
	g.layout.update_layout()
}

// main actions

fn grid_draw(d ui.DrawDevice, c &ui.CanvasLayout, app voidptr) {
	// println("draw begin")
	mut g := grid_component(c)
	g.pos_x = g.from_x + c.x + c.offset_x
	// println("$g.rowbar_width == $g.pos_x")

	for j in g.from_j .. g.to_j {
		g.vars[j].draw_device(d, j, mut g)
		g.pos_x += g.widths[j]
		// println("draw $j")
	}

	// g.draw_rowbar()
	// g.draw_colbar()

	// g.draw_current()

	//
	ui.scrollview_update(c)
	// println("draw end")
}

fn grid_post_draw(d ui.DrawDevice, c &ui.CanvasLayout, app voidptr) {
	// println("post draw begin")
	mut g := grid_component(c)

	g.draw_device_current(d)

	g.draw_device_rowbar(d)
	g.draw_device_colbar(d)

	ui.scrollview_update(c)
	// println("post draw end")
}

// methods

fn (g &GridComponent) ind(i int) int {
	return if g.index.len > 0 { g.index[i] } else { i }
}

fn (g &GridComponent) nrow() int {
	return if g.index.len > 0 { g.index.len } else { g.nrow }
}

fn (mut g GridComponent) draw_device_current(d ui.DrawDevice) {
	pos_x, pos_y := g.get_pos(g.cur_i, g.cur_j)
	w, h := g.widths[g.cur_j], g.height(g.cur_i)
	sel_color := gx.red
	g.layout.draw_device_rect_surrounded(d, pos_x, pos_y, w, h, 3, sel_color)
}

fn (mut g GridComponent) draw_device_colbar(d ui.DrawDevice) {
	mut tb := g.tb_colbar
	tb.is_focused = false
	tb.read_only = true
	tb.justify = ui.top_center
	tb.set_visible(false)

	// Need absolute position because fixed position when scrolling
	g.pos_x, g.pos_y = g.layout.abs_pos(0, 0)

	// draw empty rectangles to clear top left corner preventing current selection drawn when  is scrolled
	d.draw_rect_filled(g.pos_x, g.pos_y, g.rowbar_width + g.header_size, g.colbar_height,
		gx.white)
	d.draw_rect_filled(g.pos_x, g.pos_y, g.rowbar_width, g.colbar_height + g.header_size,
		gx.white)
	mut pos_x := g.layout.x + g.layout.offset_x + g.rowbar_width + g.header_size
	for j, var in g.headers {
		tb.set_pos(pos_x, g.pos_y)
		// println("$j) $g.pos_x, $g.pos_y, ${g.widths[j]} ${var}")
		tb.propose_size(g.widths[j], g.colbar_height)
		unsafe {
			*tb.text = var
		}
		tb.draw_device(d)
		pos_x += g.widths[j]
	}
	tb.set_pos(g.pos_x, g.pos_y)
	tb.propose_size(g.rowbar_width, g.colbar_height)
	unsafe {
		*tb.text = ''
	}
	tb.draw_device(d)
}

fn (mut g GridComponent) draw_device_rowbar(d ui.DrawDevice) {
	mut tb := g.tb_rowbar
	tb.is_focused = false
	tb.read_only = true
	tb.justify = ui.top_right
	tb.set_visible(false)
	g.pos_x, _ = g.layout.abs_pos(0, 0)
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	for i in g.from_i .. g.to_i {
		tb.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.height(i]} ${gtb.var[i)}")
		tb.propose_size(g.rowbar_width, g.height(i))
		unsafe {
			*tb.text = '${g.ind(i) + 1}'
		}
		tb.draw_device(d)
		g.pos_y += g.height(i)
	}
}

fn (mut g GridComponent) set_check_nrow(var_len int) {
	if g.nrow < 0 {
		g.nrow = var_len
	} else {
		if g.nrow != var_len {
			panic('All vars need to be of same length')
		}
	}
}

fn (g &GridComponent) size() (int, int) {
	w := ui.scrollbar_size + g.rowbar_width + g.header_size + (arrays.sum(g.widths) or { -1 })
	h := g.colbar_height + 2 * g.header_size + if g.cell_height > 0 { g.cell_height * g.nrow() } else { arrays.sum(g.heights) or {
			-1} }
	return w, h
}

fn (g &GridComponent) is_selected() bool {
	return g.selectors.any(!it.hidden)
}

fn (mut g GridComponent) unselect() {
	for mut sel in g.selectors {
		sel.set_visible(false)
		sel.set_depth(ui.z_index_hidden)
	}
}

fn (mut g GridComponent) colbar_selected() {
}

fn (mut g GridComponent) show_selected() {
	if g.sel_i < 0 || g.sel_j < 0 {
		return
	}
	g.unselect()
	g.cur_i, g.cur_j = g.sel_i, g.sel_j
	// type
	name := g.headers[g.sel_j]
	match g.types[g.sel_j] {
		.tb_string {
			id := ui.component_id(g.id, 'tb_sel')
			// println('tb_sel $id selected')
			mut tb := g.layout.ui.window.textbox(id)
			tb.set_visible(true)
			// println('tb $tb.id')
			tb.z_index = 1000
			pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
			g.layout.set_child_relative_pos(id, pos_x, pos_y)
			tb.propose_size(g.widths[g.sel_j], g.height(g.sel_i))
			tb.focus()
			gtb := g.vars[g.sel_j]
			if gtb is GridTextBox {
				unsafe {
					*(tb.text) = gtb.var[g.ind(g.sel_i)]
				}
			}
			tb.style.bg_color = gx.orange
		}
		.dd_factor {
			id := ui.component_id(g.id, 'dd_sel' + '_' + name)
			// println('dd_sel $id selected $g.sel_i, $g.sel_j')
			mut dd := g.layout.ui.window.dropdown(id)
			dd.set_visible(true)
			dd.z_index = 1000
			pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
			g.layout.set_child_relative_pos(id, pos_x, pos_y)
			dd.propose_size(g.widths[g.sel_j], g.height(g.sel_i))
			dd.focus()
			gdd := g.vars[g.sel_j]
			if gdd is GridDropdown {
				dd.selected_index = gdd.var.values[g.ind(g.sel_i)]
			}
			dd.style.bg_color = gx.orange
		}
		.cb_bool {
			id := ui.component_id(g.id, 'cb_sel')
			// println('cb_sel $id selected')
			mut cb := g.layout.ui.window.checkbox(id)
			cb.set_visible(true)
			// println('cb $cb.id')
			cb.z_index = 1000
			pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
			cb.propose_size(g.widths[g.sel_j], g.height(g.sel_i))
			mut aw := ui.AdjustableWidget(cb)
			dx, dy := aw.get_align_offset(0.5, 0.5)
			g.layout.set_child_relative_pos(id, pos_x + dx, pos_y + dy)
			cb.focus()
			gcb := g.vars[g.sel_j]
			if gcb is GridCheckBox {
				cb.checked = gcb.var[g.ind(g.sel_i)]
			}
			cb.style.bg_color = gx.orange
		}
		else {}
	}
	g.layout.update_layout()
}

// depending on g.index

fn (g &GridComponent) get_index_pos(x int, y int) (int, int) {
	mut sel_i, mut sel_j := -1, -1
	$if gip_old ? {
		mut cum := g.rowbar_width
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
	} $else {
		mut cum := g.from_x
		// println("dv $y")
		for j in g.from_j .. g.to_j {
			cum += g.widths[j]
			// println("dv  $y > $g.colbar_height && $y < $cum ")
			if x > g.from_x && x < cum {
				sel_j = j
				break
			}
		}

		cum = g.from_y
		// println("dv $y")
		for i in g.from_i .. g.to_i {
			cum += g.height(i)
			// println("dv  $y > $g.colbar_height && $y < $cum ")
			if y > g.from_y && y < cum {
				sel_i = i
				break
			}
		}
	}

	return sel_i, sel_j
}

fn (g &GridComponent) get_pos(i int, j int) (int, int) {
	mut x, mut y := g.rowbar_width + g.header_size, g.colbar_height + g.header_size
	// TODO: when fixed it is easier
	for k in 0 .. i {
		y += g.height(k)
	}
	for k in 0 .. j {
		x += g.widths[k]
	}
	return x, y
}

fn (g &GridComponent) height(i int) int {
	return if g.cell_height > 0 { g.cell_height } else { g.heights[g.ind(i)] }
}

fn (mut g GridComponent) visible_cells() {
	if g.layout.has_scrollview {
		if g.cell_height > 0 {
			g.visible_fixed_cells()
		} else {
			g.from_i, g.to_i, g.from_y = -1, -1, 0
			mut cum := g.colbar_height + g.header_size
			heights := g.heights.map(g.ind(it))
			for i, h in heights {
				if g.from_i < 0 && cum > g.layout.scrollview.offset_y {
					g.from_i = i
					g.from_y = cum
				}
				if g.from_i >= 0 && g.to_i < 0
					&& cum > g.layout.scrollview.offset_y + g.layout.height {
					g.to_i = i + 1
					if g.to_i > g.nrow() {
						g.to_i = g.nrow()
					}
					break
				}
				cum += h
			}
			if g.to_i < 0 {
				g.to_i = g.nrow()
			}
		}
	} else {
		g.from_i, g.to_i, g.from_y = 0, g.nrow(), 0
	}
	// println("vc $g.from_i, $g.to_i, $g.from_y")

	if g.layout.has_scrollview {
		g.from_j, g.to_j, g.from_x = -1, -1, 0
		mut cum := g.rowbar_width + g.header_size
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

pub fn (mut g GridComponent) visible_fixed_cells() {
	g.from_i = math.min(math.max((g.layout.scrollview.offset_y - g.colbar_height - g.header_size) / g.cell_height,
		0), g.nrow() - 1)
	g.to_i = math.min((g.layout.scrollview.offset_y +
		g.layout.height - g.colbar_height - g.header_size) / g.cell_height, g.nrow() - 1) + 1
	g.from_y = g.from_i * g.cell_height + g.colbar_height + g.header_size
	// println("vfc $g.from_i, $g.to_i")
}

pub fn (mut g GridComponent) cur_allways_visible() {
	if !ui.has_scrollview(g.layout) {
		return
	}
	// vertically
	x, y := g.get_pos(g.cur_i, g.cur_j)
	if y < g.layout.scrollview.offset_y + g.height(g.cur_i) {
		// println("scroll y begin $g.cur_i")
		g.scroll_y_to_cur(false)
	} else if y > g.layout.scrollview.offset_y + g.layout.height - g.height(g.cur_i) {
		// println("scroll y end $g.cur_i")
		g.scroll_y_to_cur(true)
	}
	// horizontally
	if x < g.layout.scrollview.offset_x + g.widths[g.cur_j] {
		// println("scroll x begin $g.cur_j")
		g.scroll_x_to_cur(false)
	} else if x > g.layout.scrollview.offset_x + g.layout.width - g.widths[g.cur_j] {
		// println("scroll x end $g.cur_j")
		g.scroll_x_to_cur(true)
	}
}

pub fn (mut g GridComponent) scroll_x_to_cur(end bool) {
	if g.layout.scrollview.active_x {
		delta := if end {
			-g.layout.width + g.widths[math.min(g.cur_j - 1, g.ncol - 1)] + g.header_size
		} else {
			-g.widths[math.max(g.cur_j - 1, 0)] - g.header_size
		}
		x, _ := g.get_pos(g.cur_i, g.cur_j)
		g.layout.scrollview.set(x + delta, .btn_x)
	}
}

pub fn (mut g GridComponent) scroll_y_to_cur(end bool) {
	if g.layout.scrollview.active_y {
		delta := if end {
			-g.layout.height + g.height(math.min(g.cur_i - 1, g.nrow() - 1)) + g.header_size
		} else {
			-g.height(math.max(g.cur_i - 1, 0)) - g.header_size
		}
		_, y := g.get_pos(g.cur_i, g.cur_j)
		g.layout.scrollview.set(y + delta, .btn_y)
	}
}

pub fn (mut g GridComponent) scroll_y_to_end() {
	if g.layout.scrollview.active_y {
		_, y := g.get_pos(g.nrow - 1, g.ncol - 1)
		g.layout.scrollview.set(y + g.height(g.nrow() - 1) + g.header_size - g.layout.height,
			.btn_y)
	}
}

// GridVar interface and its "instances"

interface GridVar {
	id string
	grid &GridComponent
	compare(a int, b int) int
	draw_device(d ui.DrawDevice, j int, mut g GridComponent)
}

// TextBox GridVar
[heap]
struct GridTextBox {
	grid &GridComponent
mut:
	id  string
	var []string
}

pub struct GridTextBoxParams {
	id   string
	grid &GridComponent
	var  []string
}

pub fn grid_textbox(p GridTextBoxParams) &GridTextBox {
	return &GridTextBox{
		grid: p.grid
		var: p.var
	}
}

fn (gtb &GridTextBox) compare(a int, b int) int {
	if gtb.var[a] < gtb.var[b] {
		return -1
	} else if gtb.var[a] > gtb.var[b] {
		return 1
	} else {
		return 0
	}
}

fn (gtb &GridTextBox) draw_device(d ui.DrawDevice, j int, mut g GridComponent) {
	mut tb := g.tb_string
	tb.is_focused = false
	tb.read_only = true
	tb.set_visible(false)
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	// println("from_i=$g.from_i to_i=$g.to_i")
	for i in g.from_i .. g.to_i {
		// println("$i) $g.pos_x, $g.pos_y")
		tb.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}")
		// println("${g.height(i)}")
		// println("${g.ind(i)}")
		// println("${gtb.var[g.ind(i)]}")
		tb.propose_size(g.widths[j], g.height(i))
		unsafe {
			*tb.text = gtb.var[g.ind(i)].clone()
		}
		// g.layout.update_layout()
		// println("draw var tb $j: ${g.layout.get_children().map(it.id)}")
		tb.draw_device(d)
		g.pos_y += g.height(i)
	}
}

// Dropdown GridVar
[heap]
struct GridDropdown {
	grid &GridComponent
mut:
	id   string
	name string
	var  Factor
}

pub struct GridDropdownParams {
	id   string
	grid &GridComponent
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

fn (gdd &GridDropdown) compare(a int, b int) int {
	if gdd.var.values[a] < gdd.var.values[b] {
		return -1
	} else if gdd.var.values[a] > gdd.var.values[b] {
		return 1
	} else {
		return 0
	}
}

fn (gdd &GridDropdown) draw_device(d ui.DrawDevice, j int, mut g GridComponent) {
	mut dd := g.dd_factor[gdd.name]
	dd.set_visible(false)
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	// println("ddd $j $gdd.var.values.len")
	for i in g.from_i .. g.to_i {
		// println("$i) $g.pos_x, $g.pos_y")
		dd.set_pos(g.pos_x, g.pos_y)
		// println("$i) ${g.widths[j]}, ${g.height(i)}")
		dd.propose_size(g.widths[j], g.height(i))
		dd.selected_index = gdd.var.values[g.ind(i)]
		dd.draw_device(d)
		g.pos_y += g.height(i)
	}
}

// CheckBox GridVar
[heap]
struct GridCheckBox {
	grid &GridComponent
mut:
	id  string
	var []bool
}

pub struct GridCheckBoxParams {
	id   string
	grid &GridComponent
	var  []bool
}

pub fn grid_checkbox(p GridCheckBoxParams) &GridCheckBox {
	return &GridCheckBox{
		id: p.id
		grid: p.grid
		var: p.var
	}
}

fn (gcb &GridCheckBox) compare(a int, b int) int {
	if int(gcb.var[a]) < int(gcb.var[b]) {
		return -1
	} else if int(gcb.var[a]) > int(gcb.var[b]) {
		return 1
	} else {
		return 0
	}
}

fn (gcb &GridCheckBox) draw_device(d ui.DrawDevice, j int, mut g GridComponent) {
	mut cb := g.cb_bool
	cb.is_focused = false
	cb.set_visible(false)
	mut aw := ui.AdjustableWidget(cb)
	mut dx, mut dy := 0, 0
	g.pos_y = g.from_y + g.layout.y + g.layout.offset_y
	// println("from_i=$g.from_i to_i=$g.to_i")
	for i in g.from_i .. g.to_i {
		// println("$i) $g.pos_x, $g.pos_y")
		cb.propose_size(g.widths[j], g.height(i))
		dx, dy = aw.get_align_offset(0.5, 0.5)
		cb.set_pos(g.pos_x + dx, g.pos_y + dy)
		// unsafe {
		// 	*cb.text = gtb.var[g.ind(i)].clone()
		// }
		cb.checked = gcb.var[g.ind(i)]
		cb.draw_device(d)
		g.pos_y += g.height(i)
	}
}

// using closure

type RankedGridData = int

pub fn (mut g GridComponent) init_ranked_grid_data(vars []int, orders []int) {
	// create compare_grid_data closure
	compare_grid_data := fn [vars, orders, g] (a &RankedGridData, b &RankedGridData) int {
		mut comp := 0
		for i, j in vars {
			if j == -1 {
				comp = if f64(*a) < f64(*b) {
					-orders[i]
				} else if f64(*a) > f64(*b) {
					orders[i]
				} else {
					0
				}
			} else {
				comp = g.vars[j].compare(a, b) * orders[i]
			}
			if comp != 0 {
				return comp
			}
		}
		return 0
	}

	mut rgd := []int{len: g.nrow(), init: it}
	if vars.len > 0 {
		rgd.sort_with_compare(compare_grid_data)
	}
	g.index = rgd
}

// compare (TODO use sort_with_compare_context)

// __global (
// 	rgd_vars_   []int // all vars
// 	rgd_orders_ []int // all orders
// 	rgd_grid_   &GridComponent // the current grid
// )

// type RankedGridData = int

// pub fn (mut g GridComponent) init_ranked_grid_data(vars []int, orders []int) {
// 	rgd_vars_ = vars.clone()
// 	rgd_orders_ = orders.clone()
// 	rgd_grid_ = g
// 	mut rgd := []int{len: g.nrow(), init: it}
// 	if vars.len > 0 {
// 		rgd.sort_with_compare(compare_grid_data)
// 	}
// 	g.index = rgd
// }

// fn compare_grid_data(a &RankedGridData, b &RankedGridData) int {
// 	mut comp := 0
// 	for i, j in rgd_vars_ {
// 		if j == -1 {
// 			comp = if f64(*a) < f64(*b) {
// 				-rgd_orders_[i]
// 			} else if f64(*a) > f64(*b) {
// 				rgd_orders_[i]
// 			} else {
// 				0
// 			}
// 		} else {
// 			comp = rgd_grid_.vars[j].compare(a, b) * rgd_orders_[i]
// 		}
// 		if comp != 0 {
// 			return comp
// 		}
// 	}
// 	return 0
// }
