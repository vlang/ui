module ui

import gg

/*
Goal: propose a viewer of chunk sequence
*/

interface ChunkContent {
mut:
	bb Rect
	draw_device(d DrawDevice, cv &ChunkView)
	update_bounding_box(cv &ChunkView)
}

struct TextChunk {
mut:
	bb    Rect
	text  string
	style string // related to ChunkView text_styles
}

pub fn textchunk(x int, y int, text string, style string) TextChunk {
	return TextChunk{
		bb: Rect{x, y, 0, 0}
		text: text
		style: style
	}
}

fn (mut c TextChunk) draw_device(d DrawDevice, cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	dtw.draw_device_styled_text(d, cv.x + c.bb.x, cv.y + c.bb.y, c.text, id: c.style)
}

fn (mut c TextChunk) update_bounding_box(cv &ChunkView) {
}

struct ImageChunk {
mut:
	bb  Rect
	img string
}

pub fn imgchunk(img string) ImageChunk {
	return ImageChunk{
		img: img
	}
}

fn (mut c ImageChunk) draw_device(d DrawDevice, cv &ChunkView) {
}

fn (mut c ImageChunk) update_bounding_box(cv &ChunkView) {
}

type DrawChunkFn = fn (&DrawChunk)

struct DrawChunk {
mut:
	bb     Rect
	state  voidptr = unsafe { nil }
	drawfn DrawChunkFn
}

pub fn drawchunk(drawfn DrawChunkFn, state voidptr) DrawChunk {
	return DrawChunk{
		drawfn: drawfn
		state: state
	}
}

fn (mut c DrawChunk) draw_device(d DrawDevice, cv &ChunkView) {
}

fn (mut c DrawChunk) update_bounding_box(cv &ChunkView) {
}

// Arrange chunk as a paragraph
struct ParaChunk {
mut:
	x       int
	y       int
	margin  int
	indent  int
	spacing int
	bb      Rect
	content []string // format ["<style1>", "text1", "<style2>", "text2", ....]
	chunks  []TextChunk
}

[params]
pub struct ParaChunkParams {
	x       int
	y       int
	margin  int = 20
	indent  int
	spacing int = 10
	content []string
}

pub fn parachunk(c ParaChunkParams) ParaChunk {
	return ParaChunk{
		x: c.x
		y: c.y
		margin: c.margin
		indent: c.indent
		content: c.content
	}
}

fn (mut c ParaChunk) update_chunks(cv &ChunkView) {
	max_line_width := cv.width
	// println("max_line_width=${max_line_width}")
	mut dtw := DrawTextWidget(cv)
	// convert content to chunks
	mut chunks := []TextChunk{}
	mut style := ''
	mut ustr := ''.runes()
	mut chunk := TextChunk{}
	mut x, mut y := c.x + c.indent + c.margin, c.y
	mut line, mut line_width, mut line_height := '', f64(x), 0
	mut ww := dtw.text_width_additive(' ')
	mut lw := 0.0
	mut lh := 0
	for mut blck in c.content {
		ustr = blck.trim_space().runes()
		if ustr.first() == `<` && ustr.last() == `>` {
			next_style := ustr#[1..-1].string()
			if style != next_style {
				if line_width > 0 && style != '' {
					chunk = textchunk(x, y, line, style)
					chunks << chunk
					x = int(line_width + ww)
					line = ''
				}
				style = next_style
			}
			dtw.set_current_style(id: style) // to update style for text_width_additive
			dtw.load_style()
			ww = dtw.text_width_additive(' ')
		} else {
			words := blck.split(' ').filter(!(it.len == 0))
			for word in words {
				// println("lw = $blck ${dtw.text_width_additive(blck)}")
				word_width := dtw.text_width_additive(word)
				lh = dtw.text_height(word)
				if lh > line_height {
					line_height = lh
				}
				lw = line_width + word_width + if line.len > 0 { ww } else { 0.0 }
				if line.len == 0 || lw < max_line_width - c.margin * 2 - 10 {
					line += ' ' + word
					line_width = lw
				} else {
					// newline
					chunk = textchunk(x, y, line, style)
					x = c.margin //
					y += line_height + c.spacing
					chunks << chunk
					line, line_width, line_height = word, word_width, dtw.text_height(word)
				}
			}
		}
	}
	if line_width > 0 {
		chunk = textchunk(x, y, line, style)
		chunks << chunk
	}
	println('chunks=${chunks}')
	c.chunks = chunks
}

/*
fn (mut c ParaChunk) update_chunks_old(cv &ChunkView) {
	max_line_width := cv.width
	// println("max_line_width=${max_line_width}")
	mut dtw := DrawTextWidget(cv)
	// convert content to chunks
	mut chunks := []TextChunk{}
	mut style := "system"
	mut ustr := ''.runes()
	mut line, mut line_width := '', 0.0
	mut chunk := TextChunk{}
	mut x, mut y := f32(c.x + c.indent), f32(c.y)
	for mut blck in c.content {
		ustr = blck.trim_space().runes()
		if ustr.first() == `<` && ustr.last() == `>` {
			style = ustr#[1..-1].string()
		} else {
			words := blck.split(' ').filter(!(it.len == 0))
			for i, word in words {
				if i == 0 { // at least the first
					line = word
					line_width = dtw.text_width_additive(word)
					// x += f32(line_width)
				} else {
					word_width := dtw.text_width_additive(' ' + word)
					if x + word_width < max_line_width - c.margin * 2 {
						line += ' ' + word
						line_width += word_width
						x += f32(word_width)
					} else {
						// newline
						chunk = textchunk(int(x), int(y), line, style)
						x = 0.0 //
						y += dtw.text_height(line) + c.spacing
						chunks << chunk
						line = word
						line_width = word_width
					}
				}
			}
			// println('line_Width = ${line_width} (${s})')
			if line_width > 0 {
				chunk = textchunk(int(x), int(y), line, style)
				chunks << chunk
			}
			line, line_width = '', 0.0
		}
	}
	c.chunks = chunks
}
*/

fn (mut c ParaChunk) draw_device(d DrawDevice, cv &ChunkView) {
	for mut chunk in c.chunks {
		chunk.draw_device(d, cv)
	}
}

fn (mut c ParaChunk) update_bounding_box(cv &ChunkView) {
}

[heap]
struct ChunkView {
mut:
	ui       &UI = unsafe { nil }
	id       string
	x        int
	y        int
	z_index  int
	offset_x int
	offset_y int
	hidden   bool
	parent   Layout = empty_stack
	// ChunkView specific field
	bb     Rect
	chunks []ChunkContent // sorted with respect of ChunkList bounding box
	// text styles
	text_styles TextStyles
	// images
	cache map[string]gg.Image
pub mut:
	width  int
	height int
}

[params]
pub struct ChunkViewParams {
	id     string
	chunks []ChunkContent
}

pub fn chunkview(c ChunkViewParams) &ChunkView {
	mut cv := &ChunkView{
		id: c.id
		chunks: c.chunks
	}
	return cv
}

fn (mut cv ChunkView) init(parent Layout) {
	cv.parent = parent
	ui := parent.get_ui()
	cv.ui = ui
}

fn (mut cv ChunkView) set_pos(x int, y int) {
	cv.x, cv.y = x, y
}

fn (mut cv ChunkView) propose_size(w int, h int) (int, int) {
	cv.width, cv.height = w, h
	for mut chunk in cv.chunks {
		if mut chunk is ParaChunk {
			chunk.update_chunks(cv)
		}
	}
	return cv.size()
}

fn (mut cv ChunkView) update_bounding_box() {
	mut bb := Rect{}
	for chunk in cv.chunks {
		bb = bb.combine(chunk.bb)
	}
	cv.bb = bb
}

fn (mut cv ChunkView) adj_size() (int, int) {
	cv.update_bounding_box()
	return cv.bb.w, cv.bb.h
}

fn (mut cv ChunkView) size() (int, int) {
	return cv.width, cv.height
}

fn (mut cv ChunkView) point_inside(x f64, y f64) bool {
	return point_inside(cv, x, y)
}

fn (mut cv ChunkView) set_visible(state bool) {
	cv.hidden = !state
}

fn (mut cv ChunkView) draw() {
	cv.draw_device(mut cv.ui.dd)
}

fn (mut cv ChunkView) draw_device(mut d DrawDevice) {
	offset_start(mut cv)
	defer {
		offset_end(mut cv)
	}
	for mut chunk in cv.chunks {
		chunk.draw_device(d, cv)
	}
}

fn (mut cv ChunkView) cleanup() {}
