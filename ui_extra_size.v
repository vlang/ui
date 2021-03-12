module ui

pub const (
	stretch = -100.
	compact = 0. // from parent
)

enum WindowSizeType {
	normal_size
	resizable
	max_size
	fullscreen
}

pub type Size = []f64 | f64

fn (size Size) as_f32_array(len int) []f32 {
	mut res := []f32{}
	match size {
		[]f64 {
			for _, v in size {
				res << f32(v)
			}
		}
		f64 {
			res = [f32(size)].repeat(len)
		}
	}
	return res
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

fn is_children_have_widget(children []Widget) bool {
	tmp := children.filter(!(it is Stack || it is Group))
	return tmp.len > 0
}

//***********  cache **********

pub enum ChildSize {
	fixed
	weighted
	weighted_minsize
	stretch
	compact
	propose
}

struct CachedSizes {
mut:
	width_type     []ChildSize
	height_type    []ChildSize
	fixed_widths   []int
	fixed_heights  []int
	fixed_width    int
	fixed_height   int
	min_width      int
	min_height     int
	weight_widths  []f64
	width_mass     f64
	weight_heights []f64
	height_mass    f64
}

//********** Margin *********

enum MarginSide {
	top
	left
	right
	bottom
}

// for Stacks
pub struct Margins {
	top    f32
	right  f32
	bottom f32
	left   f32
}

// for Config 
pub struct Margin {
	top    f64
	right  f64
	bottom f64
	left   f64
}

fn margins(m f64, ms Margin) Margins {
	mut margin := Margins{f32(m), f32(m), f32(m), f32(m)}
	if ms.left != 0 || ms.right != 0 || ms.top != 0 || ms.bottom != 0 {
		margin = Margins{f32(ms.top), f32(ms.right), f32(ms.bottom), f32(ms.left)}
	}
	return margin
}

//******** spacings ***********

fn spacings(sp f64, sps []f64, len int) []f32 {
	mut spacing := [f32(sp)].repeat(len)
	if sps.len == len {
		spacing = sps.map(f32(it))
	}
	return spacing
}

/***** Stack sizes ******/

pub struct StackSizesConfig {
mut:
	widths    Size = Size(-1.)
	heights   Size = Size(-1.)
	spacing   f64 = -1.
	spacings  []f64 = []f64{} 
}

pub fn (mut s Stack) update_sizes(cfg StackSizesConfig) {
	if cfg.widths is f64 {
		if cfg.widths == -1. {
			// TODO: guess how to update
		} else {
			s.widths = [f32(cfg.widths)].repeat(s.children.len)
		}
	} else {
		s.widths = cfg.widths.as_f32_array(s.children.len)
	}
	if cfg.heights is f64 {
		if cfg.heights == -1. {
			// TODO: guess how to update automatically
		} else {
			s.heights = [f32(cfg.heights)].repeat(s.children.len)
		}
	} else {
		s.heights = cfg.heights.as_f32_array(s.children.len)
	}
	if cfg.spacing != -1. || cfg.spacings.len != 0 {
		s.spacings = spacings(cfg.spacing, cfg.spacings, s.children.len - 1)
	} else {
		// TODO: guess how to update automatically
	}
} 
