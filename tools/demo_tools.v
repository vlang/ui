module tools

import ui
import os

const demo_blocks = ['layout', 'main_pre', 'main_post', 'window_init'] // in the right order

const demo_comment_block_delims = set_demo_comment_block_delims()

@[heap]
pub struct DemoTemplate {
	file string
	code string
pub mut:
	template map[string]string
	blocks   map[string]string
	tb       &ui.TextBox = unsafe { nil }
}

pub fn demo_template(file string, mut tb ui.TextBox) &DemoTemplate {
	code := os.read_file(file) or { panic(err) }
	mut dt := &DemoTemplate{
		file: file
		code: code
		tb:   tb
	}
	dt.set_template()
	return dt
}

pub fn set_demo_comment_block_delims() map[string]string {
	mut delims_ := map[string]string{}
	for block_name in demo_blocks {
		delims_['begin_${block_name}'] = '// <<BEGIN_${block_name.to_upper()}>>'
		delims_['end_${block_name}'] = '// <<END_${block_name.to_upper()}>>'
	}
	return delims_
}

fn complete_demo_ui_code(code string) string {
	mut new_code := code
	mut block_name := demo_blocks[0]
	if !code.contains(block_format(block_name)) {
		new_code = block_format(block_name) + '\n' + new_code
	}
	for i in 1 .. demo_blocks.len {
		block_name = demo_blocks[i]
		if !code.contains(block_format(block_name)) {
			new_code += '\n' + block_format(block_name)
		}
	}
	new_code += '\n' + block_format('end')
	println(new_code)
	return new_code
}

pub fn (mut dt DemoTemplate) update_blocks() {
	code := complete_demo_ui_code(dt.tb.get_text())
	for _, block_name in demo_blocks[0..demo_blocks.len] {
		start := block_format(block_name)
		stop := block_format_delim['start'] // '[[${tools.demo_blocks[i + 1]}]]'
		dt.blocks[block_name] = if code.contains(start) && code.contains(stop) {
			code.find_between(start, stop)
		} else {
			''
		}
	}
}

pub fn (mut dt DemoTemplate) set_template() {
	src := dt.code
	mut start, mut stop := '', demo_comment_block_delims['begin_${demo_blocks[0]}']
	dt.template['pre_${demo_blocks[0]}'] = src.all_before(stop) + stop
	for i in 0 .. (demo_blocks.len - 1) {
		start = demo_comment_block_delims['end_${demo_blocks[i]}']
		stop = demo_comment_block_delims['begin_${demo_blocks[i + 1]}']
		dt.template['pre_${demo_blocks[i + 1]}'] = start + src.find_between(start, stop) + stop
	}
	start = demo_comment_block_delims['end_${demo_blocks[demo_blocks.len - 1]}']
	dt.template['post'] = start + src.all_after(start)
}

pub fn (mut dt DemoTemplate) write_file() {
	dt.update_blocks()
	mut code := ''
	for i in 0 .. demo_blocks.len {
		code += dt.template['pre_${demo_blocks[i]}'] + dt.blocks[demo_blocks[i]]
	}
	code += '\n' + dt.template['post']
	os.write_file(dt.file, code) or { panic(err) }
}
