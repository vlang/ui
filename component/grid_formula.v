module component

import ui
import gx
import math
import regex

const (
	no_cell = GridCell{-1, -1}
)

// Spreadsheet-like (ex: A1, B4, ...)
type AlphaCell = string

// Spreadsheet-like (ex: A1:B4, Z12:AB13, ...)
type AlphaCellBlock = string

type ActiveCells = AlphaCell | AlphaCellBlock

// Matrix-like (zero indexed)
pub struct GridCell {
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

pub fn (mut gfm GridFormulaMngr) init() {
	for cell, mut formula in gfm.formulas {
		active_cells := extract_alphacellblock_from_formula(formula.formula)
		gfm.active_cell_to_formula[active_cells] = cell
		if active_cells.contains(':') {
			ac := ActiveCells(AlphaCellBlock(active_cells))
			gfm.active_cells << ac
			formula.active_cells << ac
		} else {
			ac := ActiveCells(AlphaCell(active_cells))
			gfm.active_cells << ac
			formula.active_cells << ac
		}
		// println(extract_alphacells_from_formula(gfm.formulas[gfm.sel_formula].formula))
	}
	// extract_alphacellblock_from_formula("A1")
	// println(gfm)
}

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

pub fn (mut g GridComponent) propagate_cell(c AlphaCell) {
	// only if c is an active cell (i.e. contained in some formula)
	mut gfm := g.formula_mngr
	active, active_cell := gfm.active_cells.which_contains(c)
	if active {
		formula := gfm.formulas[gfm.active_cell_to_formula[active_cell]]
		g.update_formula(formula)
	}
}

pub fn (mut g GridComponent) update_formulas() {
	for _, formula in g.formula_mngr.formulas {
		g.update_formula(formula)
	}
}

pub fn (mut g GridComponent) update_formula(formula GridFormula) {
	// println(c)
	// println(gfm.active_cell_to_formula[active_cell])
	// println(formula)
	// println(formula.active_cells[0])
	vals := g.values_at(formula.active_cells[0]).map(it.f64())
	// SUM FROM NOW
	g.set_value(formula.cell.i, formula.cell.j, sum(...vals).str())
	g.formula_mngr.cells_to_activate << formula.cell.alphacell()
}

fn sum(a ...f64) f64 {
	mut total := 0.0
	for x in a {
		total += x
	}
	return total
}

pub fn grid_formulas(formulas map[string]string) map[string]GridFormula {
	mut res := map[string]GridFormula{}
	for k, v in formulas {
		res[k] = GridFormula{
			cell: AlphaCell(k).gridcell()
			formula: v
		}
	}
	return res
}

// TODO alphacell and alphacellblock
fn extract_alphacellblock_from_formula(formula string) string {
	query := r'.*(?P<colfrom>[A-Z]+)(?P<rowfrom>\d+)\:?(?P<colto>[A-Z]+)?(?P<rowto>\d+)?.*'
	mut re := regex.regex_opt(query) or { panic(err) }
	if re.matches_string(formula) {
		re.match_string(formula)
		if re.get_group_by_name(formula, 'colto') + re.get_group_by_name(formula, 'rowto') == '' {
			return AlphaCell(re.get_group_by_name(formula, 'colfrom') +
				re.get_group_by_name(formula, 'rowfrom'))
		} else {
			return AlphaCellBlock(re.get_group_by_name(formula, 'colfrom') +
				re.get_group_by_name(formula, 'rowfrom') + ':' +
				re.get_group_by_name(formula, 'colto') + re.get_group_by_name(formula, 'rowto'))
		}
	}
	return ''
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
	// println("is_formula sel = ($g.sel_i, $g.sel_j) <$ac> in ${g.formulas.keys()}")
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
	mut tb := g.layout.ui.window.textbox(id)
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
fn grid_tb_formula_entered(mut tb ui.TextBox, a voidptr) {
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
	g.update_formula(g.formula_mngr.formulas[GridCell{g.sel_i, g.sel_j}.alphacell()])
	g.layout.update_layout()
	// println("tb_entered: ${g.layout.get_children().map(it.id)}")
}

// methods

pub fn (ac AlphaCell) gridcell() GridCell {
	query := r'(?P<column>[A-Z]+)(?P<row>\d+)'
	mut re := regex.regex_opt(query) or { panic(err) }
	if re.matches_string(ac) {
		re.match_string(ac)
		acj := re.get_group_by_name(ac, 'column')
		aci := re.get_group_by_name(ac, 'row').int() - 1
		return GridCell{aci, base26_to_int(acj)}
	} else {
		return component.no_cell
	}
}

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

fn (aacb []ActiveCells) which_contains(ac AlphaCell) (bool, string) {
	for acb in aacb {
		match acb {
			AlphaCell {
				if acb == ac {
					return true, acb
				}
			}
			AlphaCellBlock {
				if acb.contains(ac) {
					return true, acb
				}
			}
		}
	}
	return false, ''
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
