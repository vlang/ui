module ui

import gg

/*
Goal: propose a viewer of chunk sequence
*/

const text_chunk_wrap = 10

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
	content [][2]string // format ["<style1>", "text1", "<style2>", "text2", ....]
	chunks  []TextChunk
}

[params]
pub struct ParaChunkParams {
	x       int
	y       int
	margin  int = 20
	indent  int
	spacing int = 10
	content [][2]string
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
	mut blck := ''
	mut left, mut right := '', ''
	mut chunk := TextChunk{}
	mut x, mut y := c.x + c.indent + c.margin, c.y
	mut line, mut line_width, mut line_height := '', f64(x), 0
	mut bw := 0.0
	mut lh := 0
	mut ind := 0
	mut force := false
	for content in c.content {
		style = content[0]
		left = content[1].clone()
		right = ''
		dtw.set_current_style(id: style) // to update style for text_width_additive
		dtw.load_style()
		for left.len > 0 {
			// println('left: <${left}>, right: <${right}>, ind: ${ind}')
			ind = -1
			for ind >= -1 {
				bw = dtw.text_width_additive(left)
				// println('left2: <${left}>, right: <${right}>, ind: ${ind}')
				// println(line_width + bw < max_line_width - c.margin * 2 - ui.text_chunk_wrap)
				if force || line_width + bw < max_line_width - c.margin * 2 - ui.text_chunk_wrap {
					// println('left3: <${left}>, right: <${right}>, ind: ${ind}')
					line = line + left
					line_width += bw
					chunk.bb = Rect{x, y, int(line_width) - x, dtw.text_height(blck)}
					chunk = textchunk(x, y, line, style)
					lh = dtw.text_height(left)
					if lh > line_height {
						line_height = lh
					}
					if ind >= 0 { // newline
						x = c.x + c.margin
						y += line_height + c.spacing
						line_width = f32(x)
						line_height = 0
					} else {
						x = int(line_width)
					}
					line = ''
					chunks << chunk
					force = false
					ind = -2
				} else {
					ind = left.last_index(' ') or { -2 }
					if ind >= 0 {
						if right.len == 0 {
							right = left[(ind + 1)..]
						} else {
							right = left[(ind + 1)..] + ' ' + right
						}
						left = left[0..ind]
					} else {
						// add a chunk
						force = true
						ind = 0
					}
				}
			}
			if right.len == 0 {
			}
			// right cobsidered as a blck to consider
			left = right
			right = ''
			ind = 0
		}
	}

	//  println('chunks=${chunks}')
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
