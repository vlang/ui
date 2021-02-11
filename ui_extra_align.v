module ui

pub struct HorizontalAlignments {
	left   []int
	center []int
	right  []int
}

pub struct VerticalAlignments {
	top    []int
	center []int
	bottom []int
}

// Anticipating replacement of VerticalAlignments
pub struct Alignments {
	left_top     []int
	top          []int
	right_top    []int
	right        []int
	right_bottom []int
	bottom       []int
	left_bottom  []int
	left         []int
}

