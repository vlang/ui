module component

import ui
import gx
import math
import regex

const no_cell = GridCell{-1, -1}

// Spreadsheet-like (ex: A1, B4, ...)
pub type AlphaCell = string

// Spreadsheet-like (ex: A1:B4, Z12:AB13, ...)
pub type AlphaCellBlock = string

pub type ActiveCells = AlphaCell | AlphaCellBlock

// Matrix-like (zero indexed)
pub struct GridCell {
pub:
	i int
	j int
}

struct GridFormula {
	cell GridCell
mut:
	formula      string
	active_cells []ActiveCells
}

struct GridCellBlock {
	from GridCell
	to   GridCell
}

struct GridFormulaMngr {
mut:
	formulas               map[string]GridFormula // list of formula: key string is the alphacell of the formula
	active_cell_to_formula map[string]string      // key string is "Block cells" or a "Cell" and the value string is the formula cell (AlphaCell)
	active_cells           []ActiveCells
	cells_to_activate      []AlphaCell
	sel_formula            string
}

// constructor
pub fn grid_formula_mngr(formulas map[string]string) GridFormulaMngr {
	mut gfm := GridFormulaMngr{
		formulas: grid_formulas(formulas)
	}
	gfm.init()
	return gfm
}

// TODO: documentation
pub fn (mut gfm GridFormulaMngr) init() {
	// gfm.active_cells.clear()
	for cell, mut formula in gfm.formulas {
		gfm.init_formula(cell, mut formula)
	}
	gfm.init_active_cells()
}

// TODO: documentation
pub fn (mut gfm GridFormulaMngr) init_active_cells() {
	gfm.active_cells.clear()
	for _, formula in gfm.formulas {
		gfm.active_cells << formula.active_cells
	}
}

fn (mut gfm GridFormulaMngr) init_formula(cell string, mut formula GridFormula) {
	_, active_cells_set := parse_formula(formula.formula)
	formula.active_cells.clear()
	// println("init formula: $cell $active_cells_set $formula.formula")
	for active_cells in active_cells_set {
		gfm.active_cell_to_formula[active_cells] = cell
		if active_cells.contains(':') {
			ac := ActiveCells(AlphaCellBlock(active_cells))
			formula.active_cells << ac
		} else {
			ac := ActiveCells(AlphaCell(active_cells))
			formula.active_cells << ac
		}
	}
}

// new formula

// TODO: documentation
pub fn (mut g GridComponent) new_formula(gc GridCell, formula string) {
	ac := gc.alphacell()
	g.formula_mngr.formulas[ac] = GridFormula{
		cell:    gc
		formula: formula
	}
	g.formula_mngr.init_formula(ac, mut g.formula_mngr.formulas[ac])
	// println(gfm)
	g.update_formula(g.formula_mngr.formulas[ac], true)
	g.formula_mngr.init_active_cells()
}

// init

// TODO: documentation
pub fn (mut g GridComponent) init_formulas() {
	g.update_formulas()
	g.activate_formula_cells()
}

// TODO: documentation
pub fn (mut g GridComponent) activate_formula_cells() {
	for cell, _ in g.formula_mngr.formulas {
		g.activate_cell(cell)
	}
}

// TODO: documentation
pub fn (mut g GridComponent) update_formulas() {
	for _, formula in g.formula_mngr.formulas {
		g.update_formula(formula, false)
	}
}

// TODO: documentation
pub fn (mut g GridComponent) activate_cell(c AlphaCell) {
	g.formula_mngr.cells_to_activate.clear()
	g.formula_mngr.cells_to_activate << c
	for {
		if g.formula_mngr.cells_to_activate.len > 0 {
			ac := g.formula_mngr.cells_to_activate.pop()
			g.propagate_cell(ac)
		} else {
			break
		}
	}
}

// TODO: documentation
pub fn (mut g GridComponent) propagate_cell(c AlphaCell) {
	// only if c is an active cell (i.e. contained in some formula)
	gfm := g.formula_mngr
	active_cell_set := gfm.active_cells.which_contains(c)
	if active_cell_set.len > 0 {
		for active_cell in active_cell_set {
			formula := gfm.formulas[gfm.active_cell_to_formula[active_cell]]
			g.update_formula(formula, false)
		}
	}
}

// TODO: documentation
pub fn (mut g GridComponent) update_formula(formula GridFormula, activate bool) {
	// println(c)
	// println(gfm.active_cell_to_formula[active_cell])
	// println(formula)
	// println(formula.active_cells)

	// TODO: extend to compute a more sophisticated
	mut vals := []f64{}
	for active_cells in formula.active_cells {
		vals << g.values_at(active_cells).map(it.f64())
	}
	// SUM FROM NOW
	g.set_value(formula.cell.i, formula.cell.j, sum(...vals).str())
	if activate { // used to activate a formula cell
		g.activate_cell(formula.cell.alphacell())
	} else { // used for propagate_cell i.e. for reactive cell
		g.formula_mngr.cells_to_activate << formula.cell.alphacell()
	}
}

fn sum(a ...f64) f64 {
	mut total := 0.0
	for x in a {
		total += x
	}
	return total
}

// TODO: documentation
pub fn grid_formulas(formulas map[string]string) map[string]GridFormula {
	mut res := map[string]GridFormula{}
	for k, v in formulas {
		res[k] = GridFormula{
			cell:    AlphaCell(k).gridcell()
			formula: v
		}
	}
	return res
}

// TODO: documentation
pub fn parse_formula(formula string) (string, []string) {
	query := r'(?P<colfrom>[A-Z]+)(?P<rowfrom>\d+)\:?(?P<colto>[A-Z]+)?(?P<rowto>\d+)?.*'
	mut re := regex.regex_opt(query) or { panic(err) }
	mut pos := 0
	mut tmp := ''
	mut res := []string{}
	mut code := ''
	mut new_f := ''
	mut cpt, mut from, mut to := 0, 0, 0
	for {
		code = formula[pos..]
		if re.matches_string(code) {
			re.match_string(code)
			if re.get_group_by_name(code, 'colto') + re.get_group_by_name(code, 'rowto') == '' {
				tmp = re.get_group_by_name(code, 'colfrom') + re.get_group_by_name(code, 'rowfrom')
			} else {
				tmp = re.get_group_by_name(code, 'colfrom') +
					re.get_group_by_name(code, 'rowfrom') + ':' +
					re.get_group_by_name(code, 'colto') + re.get_group_by_name(code, 'rowto')
			}
			res << tmp
			pos += tmp.len
			new_f += formula[from..to] + 'x[${cpt}]'
			cpt += 1
			from, to = pos, pos
		} else {
			pos += 1
			to += 1
		}
		if pos >= formula.len {
			break
		}
	}
	new_f += formula[from..to]
	return new_f, res
}

// GridComponent methods

fn (mut g GridComponent) value_at(c AlphaCell) string {
	gc := c.gridcell()
	res, _ := g.value(gc.i, gc.j)
	return res
}

fn (mut g GridComponent) values_at(c ActiveCells) []string {
	match c {
		AlphaCell {
			return [g.value_at(c)]
		}
		AlphaCellBlock {
			mut res := []string{}
			gcb := c.gridcellblock().sorted()
			for i in gcb.from.i .. (gcb.to.i + 1) {
				for j in gcb.from.j .. (gcb.to.j + 1) {
					s, _ := g.value(i, j)
					res << s
				}
			}
			return res
		}
	}
}

fn (mut g GridComponent) is_formula() bool {
	ac := GridCell{g.sel_i, g.sel_j}.alphacell()
	// println("is_formula sel = ($g.sel_i, $g.sel_j) <$ac> in ${g.formula_mngr.formulas.keys()}")
	is_f := ac in g.formula_mngr.formulas.keys()
	if is_f {
		g.formula_mngr.sel_formula = ac
	} else {
		g.formula_mngr.sel_formula = ''
	}
	return is_f
}

fn (mut g GridComponent) show_formula() {
	g.unselect()
	g.cur_i, g.cur_j = g.sel_i, g.sel_j
	id := ui.component_id(g.id, 'tb_formula')
	// println('tb_sel $id selected')
	mut tb := g.layout.ui.window.get_or_panic[ui.TextBox](id)
	tb.set_visible(true)
	// println('tb $tb.id')
	tb.z_index = 1000
	pos_x, pos_y := g.get_pos(g.sel_i, g.sel_j)
	g.layout.set_child_relative_pos(id, pos_x, pos_y)
	tb.propose_size(g.widths[g.sel_j], g.height(g.sel_i))
	tb.focus()
	unsafe {
		*(tb.text) = g.formula_mngr.formulas[g.formula_mngr.sel_formula].formula
	}
	tb.style.bg_color = gx.yellow
	g.layout.update_layout()
}

// formula textbox callback
fn grid_tb_formula_enter(mut tb ui.TextBox) {
	mut g := grid_component(tb)
	new_text := (*tb.text).clone()
	ac_sel := GridCell{g.sel_i, g.sel_j}.alphacell()
	if new_text.len > 0 && new_text[0..1] == '=' {
		g.formula_mngr.formulas[ac_sel].formula = new_text
		g.formula_mngr.init_formula(ac_sel, mut g.formula_mngr.formulas[ac_sel])
		g.formula_mngr.init_active_cells()
		g.update_formula(g.formula_mngr.formulas[ac_sel], true)
	} else {
		// remove formula
		g.formula_mngr.formulas.delete(ac_sel)
		g.formula_mngr.init_active_cells()
		g.init_formulas()
		g.set_value(g.sel_i, g.sel_j, new_text)
		g.activate_cell(ac_sel)
	}
	unsafe {
		*tb.text = ''
	}
	tb.set_visible(false)
	tb.z_index = ui.z_index_hidden
	g.layout.update_layout()
}

// methods

// TODO: documentation
pub fn (ac AlphaCell) gridcell() GridCell {
	query := r'(?P<column>[A-Z]+)(?P<row>\d+)'
	mut re := regex.regex_opt(query) or { panic(err) }
	if re.matches_string(ac) {
		re.match_string(ac)
		acj := re.get_group_by_name(ac, 'column')
		aci := re.get_group_by_name(ac, 'row').int() - 1
		return GridCell{aci, base26_to_int(acj)}
	} else {
		return no_cell
	}
}

// TODO: documentation
pub fn (gc GridCell) alphacell() string {
	mut acj, mut z, mut r := []u8{}, gc.j, 0
	for {
		r = int(math.mod(z, 26))
		z /= 26
		// println('$z, $r')
		acj << u8(65 + r)
		if z <= 26 {
			if z > 0 {
				acj << u8(65 + z)
			}
			break
		}
	}
	acj = acj.reverse()
	return acj.bytestr() + (gc.i + 1).str()
}

fn (gcb GridCellBlock) contains(gc GridCell) bool {
	gcbs := gcb.sorted()
	return gc.i >= gcbs.from.i && gc.i <= gcbs.to.i && gc.j >= gcbs.from.j && gc.j <= gcbs.to.j
}

fn (gcb GridCellBlock) sorted() GridCellBlock {
	from_i, to_i := math.min(gcb.from.i, gcb.to.i), math.max(gcb.from.i, gcb.to.i)
	from_j, to_j := math.min(gcb.from.j, gcb.to.j), math.max(gcb.from.j, gcb.to.j)
	return GridCellBlock{GridCell{from_i, from_j}, GridCell{to_i, to_j}}
}

fn (acb AlphaCellBlock) gridcellblock() GridCellBlock {
	a := acb.split(':')
	return GridCellBlock{AlphaCell(a[0]).gridcell(), AlphaCell(a[1]).gridcell()}
}

fn (acb AlphaCellBlock) contains(ac AlphaCell) bool {
	return acb.gridcellblock().contains(ac.gridcell())
}

fn (aacb []ActiveCells) which_contains(ac AlphaCell) []string {
	mut res := []string{}
	// println("which contains $ac => $aacb")
	for acb in aacb {
		match acb {
			AlphaCell {
				if acb == ac {
					res << acb
				}
			}
			AlphaCellBlock {
				if acb.contains(ac) {
					res << acb
				}
			}
		}
	}
	return res
}

// base26 to int conversion
pub fn base26_to_int(ac string) int {
	l := ac.len
	mut j := 0
	for k in 0 .. l {
		j += (ac[k] - u8(65)) * int(math.pow(26, l - k - 1))
	}
	return j
}
