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

// Matrix-like (zero indexed)
pub struct GridCell {
	i int
	j int
}

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

pub fn base26_to_int(ac string) int {
	l := ac.len
	mut j := 0
	for k in 0 .. l {
		j += (ac[k] - u8(65)) * int(math.pow(26, l - k - 1))
	}
	return j
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

struct GridFormula {
	cell GridCell
mut:
	formula     string
	react_cells []GridCellBlock
}

struct GridCellBlock {
	from GridCell
	to   GridCell
}

struct GridFormulaMngr {
mut:
	formulas     map[string]GridFormula // list of formula: key string is the alphacell of the formula
	active_cells map[string]string      // key string is "Block cells" or a "Cell" and the value string is the formula cell (AlphaCell)
	cells_stack  []string
	sel_formula  string
}

pub fn (mut gfm GridFormulaMngr) init() {
	for cell, mut formula in gfm.formulas {
		active_cells := extract_alphacellblock_from_formula(formula.formula)
		gfm.active_cells[active_cells] = cell
		// println(extract_alphacells_from_formula(gfm.formulas[gfm.sel_formula].formula))
	}
	println(gfm)
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
	query := r'.*(?P<col_from>[A-Z]+)(?P<row_from>\d+)\:?(?P<col_to>[A-Z]+)(?P<row_to>\d+).*'
	mut re := regex.regex_opt(query) or { panic(err) }
	if re.matches_string(formula) {
		re.match_string(formula)
		return re.get_group_by_name(formula, 'col_from') +
			re.get_group_by_name(formula, 'row_from') + ':' +
			re.get_group_by_name(formula, 'col_to') + re.get_group_by_name(formula, 'row_to')
	}
	return ''
}

// GridComponent methods

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
	g.layout.update_layout()
	// println("tb_entered: ${g.layout.get_children().map(it.id)}")
}

fn (gcb GridCellBlock) contains(gc GridCell) bool {
	from_i, to_i := math.min(gcb.from.i, gcb.to.i), math.max(gcb.from.i, gcb.to.i)
	from_j, to_j := math.min(gcb.from.j, gcb.to.j), math.max(gcb.from.j, gcb.to.j)
	return gc.i >= from_i && gc.i <= to_i && gc.j >= from_j && gc.j <= to_j
}

fn (acb AlphaCellBlock) contains(ac AlphaCell) bool {
	a := acb.split(':')
	return GridCellBlock{AlphaCell(a[0]).gridcell(), AlphaCell(a[1]).gridcell()}.contains(ac.gridcell())
}

fn (aacb []AlphaCellBlock) contains(ac AlphaCell) bool {
	for acb in aacb {
		if acb.contains(ac) {
			return true
		}
	}
	return false
}
