module ui

type Size = []f64 | f64

fn (size Size) as_f32_array(len int) []f32 {
	mut res := []f32{}
	if size is []f64 {
		for _, v in size {
			res << f32(v)
		}
	} else if size is f64 {
		res = [f32(size)].repeat(len)
	}
	return res
}

// Tool to convert width and height from f32 to int
pub fn size_f32_to_int(size f32) int {
	// Convert c.width and c.height from f32 to int used as a trick to deal with relative size with respect to parent 
	mut s := int(size)
	// println("f32_int: start $size  -> $s")
	if 0 < size && size <= 1 {
		s = -int(size * 100) // to be converted in percentage of parent size inside init call
		// println("f32_int: size $size $w ${typeof(size).name} ${typeof(s).name}")
	}
	return s
}

pub fn sizes_f32_to_int(width f32, height f32) (int, int) {
	return size_f32_to_int(width), size_f32_to_int(height)
}

// if size is negative, it is relative in percentage of the parent 
pub fn relative_size_from_parent(size int, parent_free_size int) int {
	return if size == -100 {
		parent_free_size
	} else if size < 0 {
		percent := f32(-size) / 100
		new_size := int(percent * parent_free_size)
		println('relative size: $size $new_size -> $percent * $parent_free_size) ')
		new_size
	} else {
		size
	}
}
