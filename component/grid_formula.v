module component

import math
import regex

const (
	no_cell = GridCell{-1, -1}
)

// Spreadsheet-like (ex: A1 B4 ...)
type AlphaCell = string

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
		// l := acj.len
		// mut j := 0
		// for k in 0 .. l {
		// 	j += (acj[k] - u8(65)) * int(math.pow(26, l - k - 1))
		// }
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
	react_cells []GridCells
}

struct GridCells {
	from GridCell
	to   GridCell
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

fn extract_cells_from_formula(formula string) (GridCell, GridCell) {
	query := r'.*(?P<col_from>[A-Z]+)(?P<row_from>\d+)\:?(?P<col_to>[A-Z]+)(?P<row_to>\d+).*'
	mut re := regex.regex_opt(query) or { panic(err) }
	if re.matches_string(formula) {
		re.match_string(formula)
		from_acj := re.get_group_by_name(formula, 'col_from')
		from_aci := re.get_group_by_name(formula, 'row_from').int() - 1
		to_acj := re.get_group_by_name(formula, 'col_to')
		to_aci := re.get_group_by_name(formula, 'row_to').int() - 1
		return GridCell{from_aci, base26_to_int(from_acj)}, GridCell{to_aci, base26_to_int(to_acj)}
	}
	return component.no_cell, component.no_cell
}
