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
		l := acj.len
		mut j := 0
		for k in 0 .. l {
			j += (acj[k] - u8(64)) * int(math.pow(26, l - k - 1))
		}
		return GridCell{aci, j}
	} else {
		return component.no_cell
	}
}

pub fn (gc GridCell) alphacell() AlphaCell {
	mut acj, mut z, mut r := []u8{}, gc.j, 0
	for {
		r = int(math.mod(z, 26))
		z /= 26
		println('$z, $r')
		acj << u8(64 + r)
		if z < 26 {
			acj << u8(64 + z)
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

type Formulas = map[AlphaCell]GridFormula
