module ui

// workaround for :
// s.drawing_children.sort(a.z_index < b.z_index)

struct SortedWidget {
	i int
	w Widget
}

fn compare_sorted_widget(a &SortedWidget, b &SortedWidget) int {
	if a.w.z_index < b.w.z_index {
		return -1
	} else if a.w.z_index > b.w.z_index {
		return 1
	} else if a.i < b.i {
		return -1
	} else {
		return 1
	}
}

fn (mut s Stack) sorted_drawing_children() {
	mut dc := []SortedWidget{}
	mut sorted := []Widget{}
	$if sdc ? {
		println('(Z_INDEX) drawing_children[$s.id]: ')
		for i, ch in s.drawing_children {
			id := ch.id()
			print('($i)[$id -> $ch.z_index] ')
		}
		println('\n')
	}
	for i, child in s.drawing_children {
		dc << SortedWidget{i, child}
	}
	dc.sort_with_compare(compare_sorted_widget)
	for child in dc {
		sorted << child.w
	}
	s.drawing_children = sorted
	$if sdc ? {
		println('(SORTED) drawing_children[$s.id]: ')
		for i, ch in s.drawing_children {
			id := ch.id()
			print('($i)[$id -> $ch.z_index] ')
		}
		println('\n')
	}
}

fn (mut c CanvasLayout) sorted_drawing_children() {
	mut dc := []SortedWidget{}
	mut sorted := []Widget{}

	$if sdc ? {
		println('(Z_INDEX) drawing_children[$c.id]: ')
		for i, ch in c.drawing_children {
			id := ch.id()
			print('($i)[$id -> $ch.z_index] ')
		}
		println('\n')
	}
	for i, child in c.drawing_children {
		dc << SortedWidget{i, child}
	}
	dc.sort_with_compare(compare_sorted_widget)
	for child in dc {
		sorted << child.w
	}
	c.drawing_children = sorted
	$if sdc ? {
		println('(SORTED) drawing_children[$c.id]: ')
		for i, ch in c.drawing_children {
			id := ch.id()
			print('($i)[$id-> $ch.z_index] ')
		}
		println('\n')
	}
}
