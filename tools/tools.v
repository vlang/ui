module tools

import ui
import ui.component as uic
import os

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
pub fn treechildren(layout ui.Layout) uic.Tree {
	children := layout.get_children()
	// println("treechildren $layout.id")
	t := uic.Tree{
		title: layout.id
		items: children.map(if it is ui.Layout {
			uic.TreeItem(treechildren(it))
		} else {
			uic.TreeItem('child: ${it.id}')
		})
	}
	return t
}
