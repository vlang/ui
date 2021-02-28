module ui

enum MarginSide {
	top
	left
	right
	bottom
}

// for Stacks
pub struct Margin {
	top    f32
	right  f32
	bottom f32
	left   f32
}

// for Config 
pub struct Margins {
	top    f64
	right  f64
	bottom f64
	left   f64
}

fn margins(m f64, ms Margins) Margin {
	mut margin := Margin{f32(m), f32(m), f32(m), f32(m)}
	if ms.left != 0 || ms.right != 0 || ms.top != 0 || ms.bottom != 0 {
		margin = Margin{f32(ms.top), f32(ms.right), f32(ms.bottom), f32(ms.left)}
	}
	return margin
}

fn spacings(sp f64, sps []f64, len int) []f32 {
	mut spacing := [f32(sp)].repeat(len)
	if sps.len == len {
		spacing = sps.map(f32(it))
	}
	return spacing
}
