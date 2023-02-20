module tools

import ui
import ui.component as uic
import os
import gx

const (
	block_format_delim = {
		'start': '[<'
		'stop':  '>]'
	}
)

fn block_format(block_name string) string {
	return tools.block_format_delim['start'] + block_name + tools.block_format_delim['stop']
}

// treedir to determine menu of _ui.vv files
pub fn treedir(path string, fpath string) uic.Tree {
	mut files := os.ls(fpath) or { [] }
	files.sort()
	files = files.filter(!it.ends_with('.v'))
	// println(fpath)
	// println(files)
	t := uic.Tree{
		title: path
		items: files.map(if os.is_dir(os.join_path(fpath, it)) {
			uic.TreeItem(treedir(it, os.join_path(fpath, it)))
		} else {
			uic.TreeItem('file: ${it#[0..-6]}') // ends by _ui.vv
		})
	}
	return t
}

// treechildren
pub fn tree_layout(layout ui.Layout) uic.Tree {
	children := layout.get_children()
	// println('tree_layout ${layout.id} ${children.map(it.id)}')
	t := uic.Tree{
		title: layout.id
		items: children.map(if it is ui.Layout {
			uic.TreeItem(tree_layout(it))
		} else {
			uic.TreeItem('child: ${it.id}')
		})
	}
	return t
}

[params]
pub struct TreeViewLayoutParams {
	id     string    = 'tvlc'
	layout ui.Layout = ui.empty_stack
	widget ui.Widget = ui.empty_stack
	// icons        map[string]string
	// text_color   gx.Color = gx.black
	// text_size    int      = 24
	// incr_mode    bool     = false
	// indent       int      = 10
	// folder_only  bool
	// filter_types []string
	// hidden_files bool
	bg_color gx.Color = gx.white // gx.hex(0xfcf4e4ff)
	on_click uic.TreeViewClickFn = uic.TreeViewClickFn(0)
}

pub fn layouttree_stack(p TreeViewLayoutParams) &ui.Stack {
	layout := if p.widget.id != ui.empty_stack.id && p.layout.id == ui.empty_stack.id {
		if p.widget is ui.Layout {
			p.widget as ui.Layout
		} else {
			p.layout
		}
	} else {
		p.layout
	}
	return uic.treeview_stack(
		id: p.id
		trees: [tree_layout(layout)]
		on_click: p.on_click
		mode: 'tools.layout'
	)
}

pub fn layouttree_reopen(mut tv uic.TreeViewComponent, layout_widget ui.Widget) {
	if tv.mode == 'tools.layout' {
		// tv.deactivate_all()
		l := tv.layout
		// println("layouttree_reopen $tv.id $l.id $layout_widget.id")
		mut lp := l.parent
		if mut lp is ui.Stack {
			lp.remove(at: 0)
			lp.add(
				at: 0
				child: layouttree_stack(
					id: tv.id
					widget: layout_widget
					on_click: tv.on_click
				)
			)
		} else if mut lp is ui.BoxLayout {
			mut lts := layouttree_stack(widget: layout_widget)
			lp.update_child('treelayout', mut lts)
		}
	}
}
