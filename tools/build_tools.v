module tools

import ui
import os

const build_blocks = ['import', 'const', 'app', 'callback', 'layout', 'main_pre', 'main_post',
	'window_init'] // in the right order

const build_comment_block_delims = set_build_comment_block_delims()

@[heap]
pub struct BuildTemplate {
	file string
	code string
pub mut:
	template map[string]string
	blocks   map[string]string
	tb       &ui.TextBox = unsafe { nil }
}

pub fn build_template(file string, mut tb ui.TextBox) &BuildTemplate {
	code := os.read_file(file) or { panic(err) }
	mut dt := &BuildTemplate{
		file: file
		code: code
		tb:   tb
	}
	dt.set_template()
	return dt
}

pub fn set_build_comment_block_delims() map[string]string {
	mut delims_ := map[string]string{}
	for block_name in build_blocks {
		delims_['begin_${block_name}'] = '// <<BEGIN_${block_name.to_upper()}>>'
		delims_['end_${block_name}'] = '// <<END_${block_name.to_upper()}>>'
	}
	return delims_
}

fn complete_build_ui_code(code string) string {
	mut new_code := code
	mut block_name := build_blocks[0]
	if !code.contains(block_format(block_name)) {
		new_code = block_format(block_name) + '\n' + new_code
	}
	for i in 1 .. build_blocks.len {
		block_name = build_blocks[i]
		if !code.contains(block_format(block_name)) {
			new_code += '\n' + block_format(block_name)
		}
	}
	new_code += '\n' + block_format('end')
	println(new_code)
	return new_code
}

pub fn (mut dt BuildTemplate) update_blocks() {
	code := complete_build_ui_code(dt.tb.get_text())
	for _, block_name in build_blocks[0..build_blocks.len] {
		start := block_format(block_name)
		stop := block_format_delim['start'] // '[[${tools.build_blocks[i + 1]}]]'
		dt.blocks[block_name] = if code.contains(start) && code.contains(stop) {
			code.find_between(start, stop)
		} else {
			''
		}
	}
	println(dt.blocks)
	// block_name := tools.build_blocks[tools.build_blocks.len - 1]
	// start := block_format(block_name)
	// dt.blocks[block_name] = if code.contains(start) {
	// 	code.all_after(start)
	// } else {
	// 	''
	// }
}

// pub fn update_build_toolbar_edit(code string, mut tbs map[string]&ui.TextBox) {
// 	blocks := parse_build_blocks(code)
// 	for block_name in ["layout", "callback"] {
// 		unsafe{tbs[block_name].set_text(blocks[block_name])}
// 	}
// }

pub fn (mut dt BuildTemplate) set_template() {
	src := dt.code
	mut start, mut stop := '', build_comment_block_delims['begin_${build_blocks[0]}']
	dt.template['pre_${build_blocks[0]}'] = src.all_before(stop) + stop
	for i in 0 .. (build_blocks.len - 1) {
		start = build_comment_block_delims['end_${build_blocks[i]}']
		stop = build_comment_block_delims['begin_${build_blocks[i + 1]}']
		dt.template['pre_${build_blocks[i + 1]}'] = start + src.find_between(start, stop) + stop
	}
	start = build_comment_block_delims['end_${build_blocks[build_blocks.len - 1]}']
	dt.template['post'] = start + src.all_after(start)
}

pub fn (mut dt BuildTemplate) write_file() {
	dt.update_blocks()
	mut code := ''
	for i in 0 .. build_blocks.len {
		code += dt.template['pre_${build_blocks[i]}'] + dt.blocks[build_blocks[i]]
	}
	code += '\n' + dt.template['post']
	os.write_file(dt.file, code) or { panic(err) }
}
