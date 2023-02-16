module tools

import ui
import os

const (
	demo_blocks               = ['layout', 'main_pre', 'main_post', 'window_init'] // in the right order
	demo_comment_block_delims = set_demo_comment_block_delims()
)

[heap]
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
		tb: tb
	}
	dt.set_template()
	return dt
}

pub fn set_demo_comment_block_delims() map[string]string {
	mut delims_ := map[string]string{}
	for block_name in tools.demo_blocks {
		delims_['begin_${block_name}'] = '// <<BEGIN_${block_name.to_upper()}>>'
		delims_['end_${block_name}'] = '// <<END_${block_name.to_upper()}>>'
	}
	return delims_
}

pub fn (mut dt DemoTemplate) update_blocks() {
	code := dt.tb.get_text()
	for i, block_name in tools.demo_blocks[0..(tools.demo_blocks.len - 1)] {
		start := '[[${block_name}]]'
		stop := '[[${tools.demo_blocks[i + 1]}]]'
		dt.blocks[block_name] = if code.contains(start) && code.contains(stop) {
			code.find_between(start, stop)
		} else {
			''
		}
	}
	block_name := tools.demo_blocks[tools.demo_blocks.len - 1]
	start := '[[${block_name}]]'
	dt.blocks[block_name] = if code.contains(start) {
		code.all_after(start)
	} else {
		''
	}
}

// pub fn update_demo_toolbar_edit(code string, mut tbs map[string]&ui.TextBox) {
// 	blocks := parse_demo_blocks(code)
// 	for block_name in ["layout", "callback"] {
// 		unsafe{tbs[block_name].set_text(blocks[block_name])}
// 	}
// }

pub fn (mut dt DemoTemplate) set_template() {
	src := dt.code
	mut start, mut stop := '', tools.demo_comment_block_delims['begin_${tools.demo_blocks[0]}']
	dt.template['pre_${tools.demo_blocks[0]}'] = src.all_before(stop) + stop
	for i in 0 .. (tools.demo_blocks.len - 1) {
		start = tools.demo_comment_block_delims['end_${tools.demo_blocks[i]}']
		stop = tools.demo_comment_block_delims['begin_${tools.demo_blocks[i + 1]}']
		dt.template['pre_${tools.demo_blocks[i + 1]}'] = start + src.find_between(start, stop) +
			stop
	}
	start = tools.demo_comment_block_delims['end_${tools.demo_blocks[tools.demo_blocks.len - 1]}']
	dt.template['post'] = start + src.all_after(start)
}

pub fn (mut dt DemoTemplate) write_file() {
	dt.update_blocks()
	mut code := ''
	for i in 0 .. tools.demo_blocks.len {
		code += dt.template['pre_${tools.demo_blocks[i]}'] + dt.blocks[tools.demo_blocks[i]]
	}
	code += '\n' + dt.template['post']
	os.write_file(dt.file, code) or { panic(err) }
}
