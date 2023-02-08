module ui

// workaround for :
// s.drawing_children.sort(a.z_index < b.z_index)

struct SortedWidget {
	i int
	w Widget
}

fn compare_sorted_widget(a &SortedWidget, b &SortedWidget) int {
	// z_index_focus added only if a is not the parent of b
	az := a.w.z_index +
		if !b.w.is_in_parent_tree(a.w) && a.w.has_focus() { z_index_focus } else { 0 }
	// z_index_focus added only if b is not the parent of a
	bz := b.w.z_index +
		if !a.w.is_in_parent_tree(b.w) && b.w.has_focus() { z_index_focus } else { 0 }
	if az < bz {
		return -1
	} else if az > bz {
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
		println('(Z_INDEX) drawing_children[${s.id}]: ')
		for i, ch in s.drawing_children {
			id := ch.id()
			print('(${i})[${id} -> ${ch.z_index}] ')
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
		println('(SORTED) drawing_children[${s.id}]: ')
		for i, ch in s.drawing_children {
			id := ch.id()
			print('(${i})[${id} -> ${ch.z_index}] ')
		}
		println('\n')
	}
}

fn (mut c CanvasLayout) sorted_drawing_children() {
	mut dc := []SortedWidget{}
	mut sorted := []Widget{}

	$if sdc ? {
		println('(Z_INDEX) drawing_children[${c.id}]: ')
		for i, ch in c.drawing_children {
			id := ch.id()
			print('(${i})[${id} -> ${ch.z_index}] ')
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
		println('(SORTED) drawing_children[${c.id}]: ')
		for i, ch in c.drawing_children {
			id := ch.id()
			print('(${i})[${id}-> ${ch.z_index}] ')
		}
		println('\n')
	}
}

fn (mut b BoxLayout) sorted_drawing_children() {
	mut dc := []SortedWidget{}
	mut sorted := []Widget{}

	$if sdc ? {
		println('(Z_INDEX) drawing_children[${b.id}]: ')
		for i, ch in b.drawing_children {
			id := ch.id()
			print('(${i})[${id} -> ${ch.z_index}] ')
		}
		println('\n')
	}
	for i, child in b.drawing_children {
		dc << SortedWidget{i, child}
	}
	dc.sort_with_compare(compare_sorted_widget)
	for child in dc {
		sorted << child.w
	}
	b.drawing_children = sorted
	$if sdc ? {
		println('(SORTED) drawing_children[${b.id}]: ')
		for i, ch in b.drawing_children {
			id := ch.id()
			print('(${i})[${id}-> ${ch.z_index}] ')
		}
		println('\n')
	}
}
