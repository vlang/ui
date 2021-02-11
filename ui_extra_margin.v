module ui

pub struct Margin {
	top    int
	left   int
	right  int
	bottom int
}

type MarginConfig = Margin | int

fn (m MarginConfig) as_margin() Margin {
	if m is Margin {
		return m
	} else if m is int {
		return Margin{m, m, m, m}
	} else {
		return Margin{}
	}
}
