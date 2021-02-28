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
