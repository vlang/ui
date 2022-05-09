module component

const (
	no_cell = GridCell{-1, -1}
)

// Spreadsheet-like (ex: A1 B4 ...)
type AlphaCell = string

// Matrix-like
struct GridCell {
	i int
	j int
}

pub fn (ac AlphaCell) gridcell() GridCell {
	return if ac.len == 2 { GridCell{ac[1] - u8(49), ac[0] - u8(65)} } else { component.no_cell }
}

pub fn (gc GridCell) alphacell() AlphaCell {
	return [u8(65 + gc.j), u8(49 + gc.i)].bytestr()
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
