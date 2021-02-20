module ui

pub struct Margin {
	top    int
	left   int
	right  int
	bottom int
}

pub type MarginConfig = Margin | int

// BUG: don't put the return outside the match here
fn (m MarginConfig) as_margin() Margin {
	match m {
		Margin {
			return m
		}
		int {
			return Margin{m, m, m, m}
		}
	}
}
