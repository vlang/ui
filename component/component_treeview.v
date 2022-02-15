module component

import ui
import gx
import os

const (
	treeview_layout_id = '_cvl_treeview'
)

type TreeItem = Tree | string

pub struct Tree {
	title string
	items []TreeItem
}

fn (mut t Tree) create_layout(mut tv TreeView, mut layout ui.Stack, id_root string, level int) &ui.Stack {
	root_id := tv.id + '_' + id_root
	tv.titles[root_id] = t.title
	tv.levels[root_id] = level
	tv.types[root_id] = 'root'
	mut w := ui.canvas_plus(
		id: root_id
		on_draw: treeview_draw
		on_click: treeview_click
		height: 30
	)
	layout.children << w
	ui.component_connect(tv, w)
	mut l := ui.column(
		id: root_id + '_layout'
		heights: ui.compact
	)
	tv.containers[root_id] = layout
	tv.views[root_id] = l.id
	tv.selected[root_id] = true
	tv.z_index[root_id] = layout.z_index
	for i, item in t.items {
		treeitem_id := root_id + ':$i'
		if item is string {
			tmp := item.split(':')
			tv.titles[treeitem_id] = tmp[1..].join(':').trim_space()
			tv.types[treeitem_id] = tmp[0].trim_space()
			tv.levels[treeitem_id] = level + 1
			w = ui.canvas_plus(
				id: treeitem_id
				on_draw: treeview_draw
				on_click: treeview_click
				height: 30
			)
			l.children << w
			ui.component_connect(tv, w)
		} else if mut item is Tree {
			l.children << item.create_layout(mut tv, mut l, id_root + ':$i', level + 1)
		}
	}
	l.spacings = [f32(5)].repeat(l.children.len - 1)
	return l
}

type TreeViewClickFn = fn (selected string, mut tv TreeView)

[heap]
struct TreeView {
pub mut:
	id         string
	layout     &ui.Stack // required
	trees      []Tree
	icon_paths map[string]string
	text_color gx.Color
	text_size  int
	bg_color   gx.Color
	// related to items
	titles     map[string]string
	types      map[string]string
	levels     map[string]int
	selected   map[string]bool
	containers map[string]&ui.Stack
	views      map[string]string
	z_index    map[string]int
	// event
	on_click TreeViewClickFn
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct TreeViewParams {
	id         string
	trees      []Tree
	icons      map[string]string
	text_color gx.Color        = gx.black
	text_size  int             = 24
	bg_color   gx.Color        = gx.white
	on_click   TreeViewClickFn = TreeViewClickFn(0)
}

pub fn treeview(c TreeViewParams) &ui.Stack {
	mut layout := ui.column(
		id: c.id + component.treeview_layout_id
		widths: [ui.stretch]
		heights: [ui.compact]
		bg_color: c.bg_color
	)
	mut tv := &TreeView{
		id: c.id
		layout: layout
		trees: c.trees
		text_color: c.text_color
		text_size: c.text_size
		on_click: c.on_click
	}
	for i, mut tree in tv.trees {
		layout.children << tree.create_layout(mut tv, mut layout, 'root$i', 0)
	}
	layout.spacings = [f32(5)].repeat(layout.children.len - 1)
	ui.component_connect(tv, layout)
	layout.component_init = treeview_init
	return layout
}

// component access
pub fn component_treeview(w ui.ComponentChild) &TreeView {
	return &TreeView(w.component)
}

fn treeview_draw(c &ui.CanvasLayout, state voidptr) {
	tv := component_treeview(c)
	dx := 20 * tv.levels[c.id]
	if tv.types[c.id] == 'root' {
		if tv.selected[c.id] {
			c.draw_triangle_filled(5 + dx, 8, 12 + dx, 8, 8 + dx, 14, gx.black)
		} else {
			c.draw_triangle_filled(7 + dx, 6, 12 + dx, 11, 7 + dx, 16, gx.black)
		}
	}

	c.draw_styled_text(16 + dx, 4, tv.titles[c.id], color: tv.text_color, size: tv.text_size)
}

fn treeview_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut tv := component_treeview(c)
	// println("${c.id} clicked")
	if tv.types[c.id] == 'root' {
		tv.selected[c.id] = !tv.selected[c.id]
		if tv.selected[c.id] {
			tv.activate(c.id)
		} else {
			tv.deactivate(c.id)
		}
	}
	if tv.on_click != TreeViewClickFn(0) {
		tv.on_click(c.id, mut tv)
	}
	// Line below fails to work (because click with scrollview):
	// c.ui.window.update_layout()
	// Line below instead:
	tv.layout.update_drawing_children()
}

fn (mut tv TreeView) activate(id string) {
	mut l := tv.containers[id]
	l.set_children_depth(tv.z_index[id], l.child_index_by_id(tv.views[id]))
}

fn (mut tv TreeView) deactivate(id string) {
	mut l := tv.containers[id]
	l.set_children_depth(ui.z_index_hidden, l.child_index_by_id(tv.views[id]))
}

fn treeview_init(layout &ui.Stack) {
	// mut tv := component_treeview(layout)

	// layout.ui.window.update_layout()
}

pub fn treedir(path string) &Tree {
	mut files := os.ls(path) or { [] }
	files.sort()
	t := &Tree{
		title: path
		items: files.map(if os.is_dir(it) { TreeItem(treedir(it)) } else { TreeItem('file: $it') })
	}
	return t
}
