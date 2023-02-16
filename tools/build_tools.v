module tools

import ui
import os

const (
	build_blocks               = ['import', 'callback', 'main_pre', 'main_post', 'window_init',
		'layout'] // in the right order
	build_comment_block_delims = set_build_comment_block_delims()
)

pub fn set_build_comment_block_delims() map[string]string {
	mut delims_ := map[string]string{}
	for block_name in tools.build_blocks {
		delims_['begin_${block_name}'] = '// <<BEGIN_${block_name.to_upper()}>>'
		delims_['end_${block_name}'] = '// <<END_${block_name.to_upper()}>>'
	}
	return delims_
}

pub fn parse_build_blocks(code string) map[string]string {
	mut blocks := map[string]string{}
	for i, block_name in tools.build_blocks[0..(tools.build_blocks.len - 1)] {
		start := '[[${block_name}]]'
		stop := '[[${tools.build_blocks[i + 1]}]]'
		blocks[block_name] = if code.contains(start) && code.contains(stop) {
			code.find_between(start, stop)
		} else {
			''
		}
	}
	block_name := tools.build_blocks[tools.build_blocks.len - 1]
	start := '[[${block_name}]]'
	blocks[block_name] = if code.contains(start) {
		code.all_after(start)
	} else {
		''
	}
	return blocks
}

pub fn update_build_toolbar_edit(code string, mut tbs map[string]&ui.TextBox) {
	blocks := parse_build_blocks(code)
	for block_name in ['layout', 'callback'] {
		unsafe { tbs[block_name].set_text(blocks[block_name]) }
	}
}

// pub fn () map[string]string {

// }

pub fn update_build(file string, src string, mut tbs map[string]&ui.TextBox) {
	mut start, mut stop := '', tools.build_comment_block_delims['begin_${tools.build_blocks[0]}']
	mut code := src.all_before(stop) + stop + unsafe { tbs[tools.build_blocks[0]].get_text() }
	for i in 0 .. (tools.build_blocks.len - 1) {
		start = tools.build_comment_block_delims['end_${tools.build_blocks[i]}']
		stop = tools.build_comment_block_delims['begin_${tools.build_blocks[i + 1]}']
		code += start + src.find_between(start, stop) + stop + unsafe {
			tbs[tools.build_blocks[i + 1]].get_text()
		}
	}
	start = tools.build_comment_block_delims['end_${tools.build_blocks[tools.build_blocks.len - 1]}']
	code += src.all_after(start)

	os.write_file('tmp_vui_build.vv', code) or { panic(err) }
}
