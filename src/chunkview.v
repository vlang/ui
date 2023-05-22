module ui

import gg
import gx

/*
Goal: propose a viewer of chunk sequence
*/

const text_chunk_wrap = 10

const para_style_delim = '|'

interface ChunkContent {
mut:
	bb Rect
	init(cv &ChunkView)
	draw_device(d DrawDevice, cv &ChunkView)
	update_bounding_box(cv &ChunkView)
}

fn (cc ChunkContent) draw_bb(cv &ChunkView) {
	col := gx.black
	println('bb: ${cc.type_name()} (${cc.bb.x}, ${cc.bb.y} ,${cc.bb.w}, ${cc.bb.h})')
	cv.ui.dd.draw_rect_empty(cv.x + cc.bb.x, cv.y + cc.bb.y, cc.bb.w, cc.bb.h, col)
}

struct TextChunk {
mut:
	x     int
	y     int
	bb    Rect
	text  string
	style string // related to ChunkView text_styles
}

pub fn textchunk(x int, y int, text string, style string) TextChunk {
	return TextChunk{
		x: x
		y: y
		text: text
		style: style
	}
}

fn (mut c TextChunk) init(cv &ChunkView) {
	c.update_bounding_box(cv)
}

fn (mut c TextChunk) draw_device(d DrawDevice, cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	dtw.draw_device_styled_text(d, cv.x + c.x, cv.y + c.y, c.text, id: c.style)
}

fn (mut c TextChunk) update_bounding_box(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	cv.load_style(c.style)
	c.bb.w, c.bb.h = dtw.text_size(c.text)
	// println("style: ${c.style} bb: ${c.bb} text_bounds ${dtw.text_bounds(c.x, c.y, c.text)}")
	bb := dtw.text_bounds(c.x, c.y, c.text)
	c.bb.x, c.bb.y, c.bb.w, c.bb.h = int(bb[0]), int(bb[1]) + int(bb[4]), int(bb[2]), int(bb[3])
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
	content     []string // format ["|style1|text1", "|style2|text2", ....]
	chunks      []TextChunk
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

fn (mut c ParaChunk) init(cv &ChunkView) {
	c.update_line_height(cv)
}

fn (mut c ParaChunk) update_line_height(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	mut lh := 0
	for content in c.content {
		if content.index_after(ui.para_style_delim, 0) == 0 {
			content_start := content.index_after(ui.para_style_delim, 1)
			style := content[1..content_start]
			cv.load_style(style)
			left := content[(content_start + 1)..]
			lh = dtw.text_height(left)
			if lh > c.line_height {
				c.line_height = lh
			}
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
	mut left, mut right := '', ''
	mut chunk := TextChunk{}
	mut x, mut y := c.x + c.indent + c.margin, c.y
	mut line, mut line_width := '', f64(x)
	mut lw := 0.0
	mut ind := 0
	mut add_chunk := false

	for content in c.content {
		if content.index_after(ui.para_style_delim, 0) == 0 {
			content_start := content.index_after(ui.para_style_delim, 1)
			style = content[1..content_start]
			cv.load_style(style)
			left = content[(content_start + 1)..]
			right = ''
			for left.len > 0 {
				// println('left: <${left}>, right: <${right}>, ind: ${ind}')
				ind = -1
				for ind >= -1 {
					lw = dtw.text_width_additive(left)
					// println('left2: <${left}>, right: <${right}>, ind: ${ind}')
					// println(line_width + lw < max_line_width - c.margin * 2 - ui.text_chunk_wrap)
					if add_chunk
						|| line_width + lw < max_line_width - c.margin * 2 - ui.text_chunk_wrap {
						// println('left3: <${left}>, right: <${right}>, ind: ${ind}')
						line = line + left
						line_width += lw
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
	}
	c.chunks = chunks
	// update boundig boxes of all chunks
	c.update_bounding_box(cv)
	$if parachunk ? {
		println('chunks=${c.chunks}')
	}
}

fn (mut c ParaChunk) draw_device(d DrawDevice, cv &ChunkView) {
	for mut chunk in c.chunks {
		chunk.draw_device(d, cv)
	}
	$if c_bb ? {
		ChunkContent(c).draw_bb(cv)
	}
}

fn (mut c ParaChunk) update_bounding_box(cv &ChunkView) {
	mut bb := Rect{cv.x, cv.y, 0, 0}
	for mut chunk in c.chunks {
		chunk.update_bounding_box(cv)
		bb = bb.combine(chunk.bb)
	}
	c.bb = bb
}

struct GroupChunk {
mut:
	x      int
	y      int
	bb     Rect
	chunks []ChunkContent
	// style
	bg_radius    int
	bg_color     gx.Color
	border_color gx.Color
}

[params]
struct GroupChunkParams {
	x      int
	y      int
	chunks []ChunkContent
	// style
	bg_radius    int
	bg_color     gx.Color
	border_color gx.Color
}

pub fn groupchunk(p GroupChunkParams) GroupChunk {
	return GroupChunk{
		x: p.x
		y: p.y
		chunks: p.chunks
		bg_radius: p.bg_radius
		bg_color: p.bg_color
		border_color: p.border_color
	}
}

fn (mut gc GroupChunk) init(cv &ChunkView) {
	for mut chunk in gc.chunks {
		chunk.init(cv)
	}
}

fn (mut gc GroupChunk) draw_device(d DrawDevice, cv &ChunkView) {
	if gc.bg_color != no_color {
		if gc.bg_radius > 0 {
			radius := relative_size(gc.bg_radius, cv.width, cv.height)
			d.draw_rounded_rect_filled(gc.x, gc.y, gc.bb.w, gc.bb.h, radius, gc.bg_color)
		} else {
			// println("$s.id ($s.real_x, $s.real_y, $s.real_width, $s.real_height), $s.bg_color")
			d.draw_rect_filled(gc.x, gc.y, gc.bb.w, gc.bb.h, gc.bg_color)
		}
	}
	for mut chunk in gc.chunks {
		chunk.draw_device(d, cv)
	}
}

fn (mut gc GroupChunk) update_bounding_box(cv &ChunkView) {
	mut bb := Rect{cv.x, cv.y, 0, 0}
	for mut chunk in gc.chunks {
		chunk.update_bounding_box(cv)
		bb = bb.combine(chunk.bb)
	}
	gc.bb = bb
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

fn (cv &ChunkView) load_style(style string) {
	mut dtw := DrawTextWidget(cv)
	dtw.set_current_style(id: style) // to update style for text_width_additive
	dtw.load_style()
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
	for mut chunk in cv.chunks {
		chunk.update_bounding_box(cv)
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
	$if bb ? {
		debug_draw_bb_widget(mut cv, cv.ui)
	}
}

fn (mut cv ChunkView) cleanup() {}
