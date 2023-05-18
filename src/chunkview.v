module ui

import gg

/*
Goal: propose a viewer of chunk sequence
*/

const text_chunk_wrap = 10

interface ChunkContent {
mut:
	bb Rect
	init(cv &ChunkView)
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

fn (mut c TextChunk) init(cv &ChunkView) {}

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

fn (mut c ImageChunk) init(cv &ChunkView) {}

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

fn (mut c DrawChunk) init(cv &ChunkView) {}

fn (mut c DrawChunk) draw_device(d DrawDevice, cv &ChunkView) {
}

fn (mut c DrawChunk) update_bounding_box(cv &ChunkView) {
}

// Arrange chunk as a paragraph
struct ParaChunk {
mut:
	x           int
	y           int
	margin      int
	indent      int
	spacing     int
	line_height int
	bb          Rect
	content     [][2]string // format [["<style1>", "text1"]!, ["<style2>", "text2"]!, ....]
	chunks      []TextChunk
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

fn (mut c ParaChunk) init(cv &ChunkView) {
	c.update_line_height(cv)
}

fn (mut c ParaChunk) update_line_height(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	mut lh := 0
	for content in c.content {
		style := content[0]
		left := content[1].clone()
		dtw.set_current_style(id: style) // to update style for text_width_additive
		dtw.load_style()
		lh = dtw.text_height(left)
		if lh > c.line_height {
			c.line_height = lh
		}
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
	mut line, mut line_width := '', f64(x)
	mut lw := 0.0
	mut ind := 0
	mut add_chunk := false

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
				lw = dtw.text_width_additive(left)
				// println('left2: <${left}>, right: <${right}>, ind: ${ind}')
				// println(line_width + lw < max_line_width - c.margin * 2 - ui.text_chunk_wrap)
				if add_chunk || line_width + lw < max_line_width - c.margin * 2 - ui.text_chunk_wrap {
					// println('left3: <${left}>, right: <${right}>, ind: ${ind}')
					line = line + left
					line_width += lw
					chunk.bb = Rect{x, y, int(line_width) - x, dtw.text_height(blck)}
					chunk = textchunk(x, y, line, style)
					if ind >= 0 { // newline
						x = c.x + c.margin
						y += c.line_height + c.spacing
						line_width = f32(x)
					} else {
						x = int(line_width)
					}
					line = ''
					chunks << chunk
					add_chunk = false
					ind = -2
				} else {
					// index of last whitespace except when at the end
					ind = left.trim_right(' ').last_index(' ') or { -2 }
					if ind >= 0 {
						if right.len == 0 {
							right = left[(ind + 1)..]
						} else {
							right = left[(ind + 1)..] + ' ' + right
						}
						left = left[0..ind]
					} else {
						// add a chunk
						add_chunk = true
						ind = 0
					}
				}
			}
			// right cobsidered as a blck to consider
			left = right
			right = ''
			ind = 0
		}
	}
	$if parachunk ? {
		println('chunks=${chunks}')
	}
	c.chunks = chunks
}

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
	for mut chunk in cv.chunks {
		chunk.init(cv)
	}
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
