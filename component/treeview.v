module component

import ui
import gx
import os

const (
	treeview_layout_id = '_cvl_treeview'
	tree_sep           = ':'
	root_sep           = '_|||_'
)

type TreeItem = Tree | string

pub struct Tree {
mut:
	title string
	items []TreeItem
}

fn (mut t Tree) create_root(mut tv TreeView, mut layout ui.Stack, id_root string, level int) &ui.Stack {
	root_id := tv.id + '_' + id_root
	tv.root_trees[root_id] = t
	tv.root_created[root_id] = false
	tv.id_root[root_id] = id_root
	tv.titles[root_id] = t.title
	tv.levels[root_id] = level
	tv.types[root_id] = 'root'
	tv.root_ids << root_id
	mut w := ui.canvas_plus(
		id: root_id
		on_draw: treeview_draw
		on_click: treeview_click
		height: 30
		width: 1000
	)
	layout.children << w
	ui.component_connect(tv, w)
	mut l := ui.column(
		id: root_id + '_layout'
		heights: ui.compact
	)
	tv.containers[root_id] = layout
	tv.views[root_id] = l.id
	tv.selected[root_id] = !tv.incr_mode
	tv.z_index[root_id] = layout.z_index
	return l
}

fn (mut t Tree) add_root_children(mut tv TreeView, mut l ui.Stack, id_root string, level int) {
	root_id := tv.id + '_' + id_root
	for i, item in t.items {
		treeitem_id := root_id + '$component.tree_sep$i'
		tv.parents[treeitem_id] = root_id
		mut to_expand := ''
		if item is string {
			tmp := item.split(component.tree_sep)
			if tmp[0].trim_space() == 'root' {
				to_expand = tmp[1..].join(component.tree_sep).trim_space()
			} else {
				tv.types[treeitem_id] = tmp[0].trim_space()
				if tv.filter_types.len == 0 && tv.types[treeitem_id] !in tv.filter_types {
					tv.titles[treeitem_id] = tmp[1..].join(component.tree_sep).trim_space()
					tv.levels[treeitem_id] = level + 1
					w := ui.canvas_plus(
						id: treeitem_id
						on_draw: treeview_draw
						on_click: treeview_click
						height: 30
						width: 1000
					)
					l.children << w
					ui.component_connect(tv, w)
				}
			}
		} else {
			to_expand = 'tree'
		}
		if to_expand != '' {
			if mut item is Tree {
				if tv.incr_mode {
					l.children << item.create_root(mut tv, mut l, id_root + ':$i', level + 1)
				} else {
					l.children << item.create_layout(mut tv, mut l, id_root + ':$i', level + 1)
				}
			} else {
				// finalize the incr_mode tree
				tmp := to_expand.split(component.root_sep)
				path := tmp[0].trim_space()
				fpath := tmp[1..].join(component.root_sep).trim_space()
				// update tree
				mut new_tree := treedir(path, fpath, true)
				t.items[i] = TreeItem(new_tree)
				l.children << new_tree.create_root(mut tv, mut l, id_root + ':$i', level + 1)
			}
		}
	}
	if l.children.len > 0 {
		l.spacings = [f32(5)].repeat(l.children.len - 1)
	}
}

fn (mut t Tree) create_layout(mut tv TreeView, mut layout ui.Stack, id_root string, level int) &ui.Stack {
	mut l := t.create_root(mut tv, mut layout, id_root, level)
	t.add_root_children(mut tv, mut l, id_root, level)
	return l
}

type TreeViewClickFn = fn (c &ui.CanvasLayout, mut tv TreeView)

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
	// selection
	sel_id       string
	old_sel_id   string
	bg_sel_color gx.Color
	// related to items
	titles   map[string]string
	parents  map[string]string
	types    map[string]string
	levels   map[string]int
	selected map[string]bool
	// related to roots
	root_trees   map[string]Tree
	root_created map[string]bool
	id_root      map[string]string
	containers   map[string]&ui.Stack
	views        map[string]string
	// others
	z_index      map[string]int
	root_ids     []string
	filter_types []string
	incr_mode    bool
	indent       int
	// event
	on_click TreeViewClickFn
	// To become a component of a parent component
	component voidptr
}

// constructors

[params]
pub struct TreeViewParams {
	id           string
	trees        []Tree
	icons        map[string]string
	text_color   gx.Color = gx.black
	text_size    int      = 24
	incr_mode    bool
	bg_color     gx.Color        = gx.white
	bg_sel_color gx.Color        = gx.light_gray
	on_click     TreeViewClickFn = TreeViewClickFn(0)
	indent       int = 10
	filter_types []string
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
		incr_mode: c.incr_mode
		indent: c.indent
		filter_types: c.filter_types
		on_click: c.on_click
		bg_color: c.bg_color
		bg_sel_color: c.bg_sel_color
	}
	for i, mut tree in tv.trees {
		if tv.incr_mode {
			layout.children << tree.create_root(mut tv, mut layout, 'root$i', 0)
		} else {
			layout.children << tree.create_layout(mut tv, mut layout, 'root$i', 0)
		}
	}
	layout.spacings = [f32(5)].repeat(layout.children.len - 1)
	ui.component_connect(tv, layout)
	layout.component_init = treeview_init
	return layout
}

[params]
pub struct TreeViewDirParams {
	id           string = 'tvd'
	trees        []string
	icons        map[string]string
	text_color   gx.Color = gx.black
	text_size    int      = 24
	incr_mode    bool     = true
	indent       int      = 10
	folder_only  bool
	filter_types []string
	bg_color     gx.Color        = gx.hex(0xfcf4e4ff)
	on_click     TreeViewClickFn = TreeViewClickFn(0)
}

pub fn treeview_dir(p TreeViewDirParams) &ui.Stack {
	return treeview(
		id: p.id
		incr_mode: p.incr_mode
		trees: p.trees.map(treedir(it, it, p.incr_mode))
		icons: {
			'root': 'tata' // later
			'file': 'toto' // later
		}
		text_color: p.text_color
		bg_color: p.bg_color
		on_click: p.on_click
		indent: p.indent
		filter_types: if p.folder_only { ['root'] } else { p.filter_types }
	)
}

// component access
pub fn component_treeview(w ui.ComponentChild) &TreeView {
	return &TreeView(w.component)
}

// callbacks

fn treeview_init(layout &ui.Stack) {
	mut tv := component_treeview(layout)
	if !tv.incr_mode {
		tv.deactivate_all()
	}
}

fn treeview_draw(c &ui.CanvasLayout, state voidptr) {
	tv := component_treeview(c)
	dx := tv.indent * tv.levels[c.id]
	if tv.types[c.id] == 'root' {
		if tv.selected[c.id] {
			c.draw_triangle_filled(5 + dx, 8, 12 + dx, 8, 8 + dx, 14, gx.black)
		} else {
			c.draw_triangle_filled(7 + dx, 6, 12 + dx, 11, 7 + dx, 16, gx.black)
		}
	}

	c.draw_styled_text(16 + dx, 4, tv.titles[c.id], color: tv.text_color, size: tv.text_size)
}

fn treeview_click(e ui.MouseEvent, mut c ui.CanvasLayout) {
	mut tv := component_treeview(c)
	tv.old_sel_id = tv.sel_id
	tv.sel_id = c.id
	// println("${c.id} clicked")
	if tv.types[c.id] == 'root' {
		tv.selected[c.id] = !tv.selected[c.id]
		if tv.incr_mode && !tv.root_created[c.id] {
			tv.root_created[c.id] = true // no more need to recreate it once created
			mut t := tv.root_trees[c.id]
			mut l := c.ui.window.stack(tv.views[c.id])
			t.add_root_children(mut tv, mut l, tv.id_root[c.id], tv.levels[c.id] + 1)
			// needs init for children
			for mut child in l.children {
				// println("add child $child.id to $l.id")
				c.ui.window.register_child(*child)
				child.init(l)
			}
			tv.layout.update_layout()
		}
		if tv.selected[c.id] {
			tv.activate(c.id)
		} else {
			tv.deactivate(c.id)
		}
		tv.layout.update_layout_but_pos()
	}
	if tv.sel_id != '' {
		c.bg_color = tv.bg_sel_color
		if tv.old_sel_id != '' {
			mut old_sel_c := c.ui.window.canvas_layout(tv.old_sel_id)
			old_sel_c.bg_color = tv.bg_color
		}
	}
	if tv.on_click != TreeViewClickFn(0) {
		tv.on_click(c, mut tv)
	}

	// To update scrollview
	mut tvcol := tv.layout.parent
	if mut tvcol is ui.Stack {
		tvcol.update_layout_but_pos()
		ui.scrollview_update(tvcol)
	}

	$if tree_debug ? {
		ui.Layout(tv.layout).show_children_tree(0)
	}
}

// methods

pub fn (mut tv TreeView) cleanup_layout() {
	tv.layout.cleanup()
}

pub fn (tv &TreeView) full_title(id string) string {
	mut res := []string{}
	mut cid := id
	for {
		if cid in tv.parents {
			pid := tv.parents[cid]
			res << tv.titles[cid]
			cid = pid
		} else {
			res << tv.titles[cid]
			break
		}
	}
	// println(res)
	return res.reverse().join('/')
}

fn (mut tv TreeView) activate(id string) {
	if id in tv.containers {
		mut l := tv.containers[id]
		l.set_children_depth(tv.z_index[id], l.child_index_by_id(tv.views[id]))
	}
}

fn (mut tv TreeView) deactivate(id string) {
	if id in tv.containers {
		mut l := tv.containers[id]
		l.set_children_depth(ui.z_index_hidden, l.child_index_by_id(tv.views[id]))
	}
}

fn (mut tv TreeView) deactivate_all() {
	for id in tv.root_ids.reverse() {
		if tv.types[id] == 'root' {
			// println("dea all $id ${tv.titles[id]}")
			tv.selected[id] = false
			tv.deactivate(id)
			tv.layout.update_layout_but_pos()
		}
	}
}

pub fn (tv &TreeView) selected_full_title() string {
	return tv.full_title(tv.sel_id)
}

// tools

pub fn treedir(path string, fpath string, incr_mode bool) Tree {
	mut files := os.ls(fpath) or { [] }
	files.sort()
	files = files.filter(it !in ['.git', '.github'])
	// println(fpath)
	// println(files)
	t := Tree{
		title: path
		items: files.map(if os.is_dir(os.join_path(fpath, it)) {
			if incr_mode {
				TreeItem('root: $it$component.root_sep${os.join_path(fpath, it)}')
			} else {
				TreeItem(treedir(it, os.join_path(fpath, it), false))
			}
		} else {
			TreeItem('file: $it')
		})
	}
	return t
}
