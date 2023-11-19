module ui

import gx
import os

// TODO: documentation
pub fn env(var string) string {
	return os.getenv(var)
}

// Draw bounding box for Stack
fn debug_draw_bb_stack(s &Stack) {
	mut col := gx.red
	if s.direction == .row {
		col = gx.green
	}
	w, h := s.size()
	println('debug_draw_bb_stack [${s.direction}] w, h = s.size()')
	println('  in: (s.x(${s.x}) - s.margin(.left)(${s.margin(.left)}), s.y(${s.y}) - s.margin(.top)(${s.margin(.top)}), w(${w}), h(${h}))')
	println(' out: (s.x(${s.x}), s.y(${s.y}), w(${w}) - s.margin(.left)(${s.margin(.left)}) - s.margin(.right)(${s.margin(.right)}), h(${h}) - s.margin(.top)(${s.margin(.top)}) - s.margin(.bottom)(${s.margin(.bottom)})')
	s.ui.dd.draw_rect_empty(s.x - s.margin(.left), s.y - s.margin(.top), w, h, col)
	s.ui.dd.draw_rect_empty(s.x, s.y, w - s.margin(.left) - s.margin(.right), h - s.margin(.top) - s.margin(.bottom),
		col)
}

fn debug_draw_bb_widget(mut wi Widget, u &UI) {
	col := gx.black
	w, h := wi.size()
	println('bb: ${wi.type_name()} (${wi.x}, ${wi.y} ,${w}, ${h})')
	u.dd.draw_rect_empty(wi.x, wi.y, w, h, col)
}

fn debug_draw_bb_text(x int, y int, w int, h int, u &UI) {
	col := gx.gray
	u.dd.draw_rect_empty(x, y, w, h, col)
}

// Debug function
fn debug_show_cache(mut s Stack, depth int, txt string) {
	if depth == 0 {
		println('Show cache ${s.id} =>')
	}
	$if bbd ? {
		w, h := s.size()
		println('BB ${typeof(s).name}: ')
		println('  (s.x:${s.x} - s.margin.left:${s.margin(.left)}, s.y:${s.y} - s.margin.top:${s.margin(.top)}, w:${w}, h:${h})')
		println('  (s.x:${s.x}, s.y:${s.y}, w:${w} - s.margin.left:${s.margin(.left)} - s.margin.right:${s.margin(.right)}, h:${h} - s.margin.top:${s.margin(.top)} - s.margin.ttom:${s.margin(.bottom)})')
	}
	tab := '  '.repeat(depth)
	println('${tab} (${depth}) Stack ${s.id} with ${s.children.len} children: (${s.cache.fixed_widths.len}, ${s.cache.fixed_heights.len})')
	free_width, free_height := s.free_size()
	adj_width, adj_height := s.adj_size()
	real_width, real_height := s.size()
	println('${tab}   free size: (${free_width}, ${free_height}) adj_size: (${adj_width}, ${adj_height}) real_size: (${real_width}, ${real_height})')
	println('${tab}   types: (widths: ${s.cache.width_type}, heights: ${s.cache.height_type})')
	println('${tab}   margins: (${s.margin(.top)}, ${s.margin(.bottom)}, ${s.margin(.left)}, ${s.margin(.right)}) total_spacing: ${s.total_spacing()}')
	println('${tab}   margin')
	widths, heights := s.children_sizes()
	println(txt)
	for i, mut child in s.children {
		name := child.type_name()
		if mut child is Stack {
			mut tmp := '${tab}      (${depth}-${i}) Stack ${child.id} :'
			tmp += '\n${tab}      fixed(${s.cache.fixed_widths[i]},${s.cache.fixed_heights[i]}) weight: (${s.cache.weight_widths[i]},${s.cache.weight_heights[i]})'
			tmp += '\n${tab}      size: (${widths[i]},${heights[i]})'
			debug_show_cache(mut child, depth + 1, tmp)
		} else {
			w, h := child.size()
			println('${tab}      (${depth}-${i}) Widget ${name} size(${w}, ${h}) fixed(${s.cache.fixed_widths[i]},${s.cache.fixed_heights[i]}) weight(${s.cache.weight_widths[i]},${s.cache.weight_heights[i]})')
		}
	}
}

fn debug_show_size(s &Stack, t string) {
	print('${t}size of Stack ${typeof(s).name}')
	C.printf(c' %p: ', s)
	println(' (${s.width}, ${s.height})')
}

fn debug_show_sizes(mut s Stack, t string) {
	parent := s.parent
	sw, sh := s.size()
	print('${t}Stack ${typeof(s).name}')
	C.printf(c' %p', s)
	println(' => size (${sw}, ${sh}), (${s.width}, ${s.height})  adj: (${s.adj_width}, ${s.adj_height}) spacing: ${s.spacings}')
	if parent is Stack {
		// print('	parent: $${typeof(parent).name} ')
		C.printf(c' %p', parent)
		println('=> size (${parent.width}, ${parent.height})  adj: (${parent.adj_width}, ${parent.adj_height}) spacing: ${parent.spacings}')
	} else if parent is Window {
		println('	parent: Window => size (${parent.width}, ${parent.height})  orig: (${parent.orig_width}, ${parent.orig_height}) ')
	}
	for i, mut child in s.children {
		w, h := child.size()
		print('		${i}) ${child.type_name()}')
		C.printf(c' %p', child)
		println(' size => ${w}, ${h}')
	}
}

fn debug_set_children_sizes(s &Stack, widths []int, heights []int, c CachedSizes) {
	println('scs: pos: (${s.x}, ${s.y}) real: (${s.real_width}, ${s.real_height})')
	mut total := 0
	if s.direction == .row {
		// sum rule for widths
		println('SumRule(${s.id}) left: ${s.margin(.left)} = ${s.margins.left} * ${s.real_width}')
		total += s.margin(.left)
		for i, child in s.children {
			println('+ w[${i}]: ${widths[i]} ${c.weight_widths[i]} (${child.id})')
			total += widths[i]
			if i == s.children.len - 1 {
				println('+ right: ${s.margin(.right)} = ${s.margins.right} * ${s.real_width}')
				total += s.margin(.right)
			} else {
				println('+ spacing[${i}]: ${s.spacing(i)} ${s.spacings[i]}')
				total += s.spacing(i)
			}
		}
		println('= ${total} == ${s.real_width}')
		// max rule for heights
		println('MaxRule(${s.id})  top: ${s.margin(.top)} = ${s.margins.top} * ${s.real_height}')
		total = 0 // s.margin(.left)
		for i, _ in s.children {
			if heights[i] > total {
				total = heights[i]
			}
			println('max ${total} | current w[${i}]: ${heights[i]} ${c.weight_heights[i]}')
		}
		println(' bottom: ${s.margin(.bottom)} = ${s.margins.bottom} * ${s.real_height}')
		println(' ${s.real_height} == ${s.margin(.top) + total + s.margin(.bottom)} = ${s.margin(.top)} + ${total} + ${s.margin(.bottom)} ')
	} else {
		// sum rule
		println('SumRule(${s.id})  top: ${s.margin(.top)}')
		total += s.margin(.top)
		for i, child in s.children {
			println('+ w[${i}]: ${heights[i]} ${c.weight_heights[i]} (${child.id})')
			total += heights[i]
			if i == s.children.len - 1 {
				println('+ bottom: ${s.margin(.bottom)} ${s.margins.bottom}')
				total += s.margin(.bottom)
			} else {
				println('+ spacing[${i}]: ${s.spacing(i)} ${s.spacings[i]}')
				total += s.spacing(i)
			}
		}
		println('= ${total} == ${s.real_height}')
		// max rule for heights
		println('MaxRule(${s.id})  top: ${s.margin(.left)} = ${s.margins.left} * ${s.real_width}')
		total = 0 // s.margin(.left)
		for i, _ in s.children {
			if widths[i] > total {
				total = widths[i]
			}
			println('max ${total} | current w[${i}]: ${widths[i]} ${c.weight_widths[i]}')
		}
		println(' right: ${s.margin(.right)} = ${s.margins.right} * ${s.real_width}')
		println(' ${s.real_width} == ${s.margin(.left) + total + s.margin(.right)} = ${s.margin(.left)} + ${total} + ${s.margin(.right)} ')
	}
}
