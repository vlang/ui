module ui

import gx

// Draw bounding box for Stack
fn (s &Stack) draw_bb() {
	mut col := gx.red
	if s.direction == .row {
		col = gx.green
	}
	w, h := s.size()
	println('draw_bb [$s.direction] w, h = s.size()')
	println('  in: (s.x($s.x) - s.margin(.left)(${s.margin(.left)}), s.y($s.y) - s.margin(.top)(${s.margin(.top)}), w($w), h($h))')
	println(' out: (s.x($s.x), s.y($s.y), w($w) - s.margin(.left)(${s.margin(.left)}) - s.margin(.right)(${s.margin(.right)}), h($h) - s.margin(.top)(${s.margin(.top)}) - s.margin(.bottom)(${s.margin(.bottom)})')
	s.ui.gg.draw_empty_rect(s.x - s.margin(.left), s.y - s.margin(.top), w, h, col)
	s.ui.gg.draw_empty_rect(s.x, s.y, w - s.margin(.left) - s.margin(.right), h - s.margin(.top) - s.margin(.bottom),
		col)
}

fn draw_bb(mut wi Widget, ui &UI) {
	col := gx.black
	w, h := wi.size()
	println('bb: $wi.type_name() ($wi.x, $wi.y ,$w, $h)')
	ui.gg.draw_empty_rect(wi.x, wi.y, w, h, col)
}

fn draw_text_bb(x int, y int, w int, h int, ui &UI) {
	col := gx.gray
	ui.gg.draw_empty_rect(x, y, w, h, col)
}

// Debug function
fn (s &Stack) debug_show_cache(depth int, txt string) {
	if depth == 0 {
		println('Show cache =>')
	}
	$if bbd ? {
		w, h := s.size()
		println('BB ${typeof(s).name}: ')
		println('  (s.x:$s.x - s.margin.left:${s.margin(.left)}, s.y:$s.y - s.margin.top:${s.margin(.top)}, w:$w, h:$h)')
		println('  (s.x:$s.x, s.y:$s.y, w:$w - s.margin.left:${s.margin(.left)} - s.margin.right:${s.margin(.right)}, h:$h - s.margin.top:${s.margin(.top)} - s.margin.ttom:${s.margin(.bottom)})')
	}
	tab := '  '.repeat(depth)
	println('$tab ($depth) Stack ${typeof(s).name} with $s.children.len children: ($s.cache.fixed_widths.len, $s.cache.fixed_heights.len)')
	free_width, free_height := s.free_size()
	println('$tab   free size: ($free_width, $free_height)')
	println('$tab   types: ($s.cache.width_type,$s.cache.height_type)')
	widths, heights := s.children_sizes()
	println(txt)
	for i, mut child in s.children {
		name := child.type_name()
		if mut child is Stack {
			mut tmp := '$tab      ($depth-$i) $name :'
			tmp += '\n$tab      fixed(${s.cache.fixed_widths[i]},${s.cache.fixed_heights[i]}) weight: (${s.cache.weight_widths[i]},${s.cache.weight_heights[i]})'
			tmp += '\n$tab      size: (${widths[i]},${heights[i]})'
			child.debug_show_cache(depth + 1, tmp)
		} else {
			w, h := child.size()
			println('$tab      ($depth-$i) Widget $name size($w, $h) fixed(${s.cache.fixed_widths[i]},${s.cache.fixed_heights[i]}) weight(${s.cache.weight_widths[i]},${s.cache.weight_heights[i]})')
		}
	}
}

fn (s &Stack) debug_show_size(t string) {
	print('${t}size of Stack ${typeof(s).name}')
	C.printf(' %p: ', s)
	println(' ($s.width, $s.height)')
}

fn (s &Stack) debug_show_sizes(t string) {
	parent := s.parent
	sw, sh := s.size()
	print('${t}Stack ${typeof(s).name}')
	C.printf(' %p', s)
	println(' => size ($sw, $sh), ($s.width, $s.height)  adj: ($s.adj_width, $s.adj_height) spacing: $s.spacings')
	if mut parent is Stack {
		// print('	parent: $${typeof(parent).name} ')
		C.printf(' %p', parent)
		println('=> size ($parent.width, $parent.height)  adj: ($parent.adj_width, $parent.adj_height) spacing: $parent.spacings')
	} else if parent is Window {
		println('	parent: Window => size ($parent.width, $parent.height)  orig: ($parent.orig_width, $parent.orig_height) ')
	}
	for i, mut child in s.children {
		w, h := child.size()
		print('		$i) $child.type_name()')
		C.printf(' %p', child)
		println(' size => $w, $h')
	}
}

fn (s &Stack) debug_set_children_sizes(widths []int, heights []int) {
	println('scs: pos: ($s.x, $s.y)')
	mut total := 0
	if s.direction == .row {
		println('  left: ${s.margin(.left)}')
		total += s.margin(.left)
		for i, _ in s.children {
			println('+ w[$i]: ${widths[i]}')
			total += widths[i]
			if i == s.children.len - 1 {
				println('+ right: ${s.margin(.right)}')
				total += s.margin(.right)
			} else {
				println('+ spacing[$i]: ${s.spacing(i)}')
				total += s.spacing(i)
			}
		}
		println('= $total == $s.real_width')
	} else {
		println('  top: ${s.margin(.top)}')
		total += s.margin(.top)
		for i, _ in s.children {
			println('+ w[$i]: ${heights[i]}')
			total += heights[i]
			if i == s.children.len - 1 {
				println('+ bottom: ${s.margin(.bottom)}')
				total += s.margin(.bottom)
			} else {
				println('+ spacing[$i]: ${s.spacing(i)}')
				total += s.spacing(i)
			}
		}
		println('= $total == $s.real_height')
	}
}
