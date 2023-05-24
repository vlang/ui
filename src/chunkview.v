module ui

import gg
import gx

/*
Goal: propose a viewer of chunk sequence
*/

const text_chunk_wrap = 10

const para_style_delim = '|'

// const empty_chunk_container = rowlayoutchunk()

[params]
pub struct Offset {
mut:
	x int
	y int
}

interface ChunkContent {
mut:
	bb Rect
	init(cv &ChunkView)
	draw_device(d DrawDevice, cv &ChunkView, offset Offset) // offset only used for groupchunk children
	update_bounding_box(cv &ChunkView, offset Offset)
}

fn (cc ChunkContent) draw_bb(cv &ChunkView) {
	col := gx.red
	println('bb: ${cc.type_name()} (${cc.bb.x}, ${cc.bb.y} ,${cc.bb.w}, ${cc.bb.h})')
	cv.ui.dd.draw_rect_empty(cc.bb.x, cc.bb.y, cc.bb.w, cc.bb.h, col)
}

// ChunkView, ParaChunk, RowChunk
interface ChunkContainer {
mut:
	x int
	y int
	bb Rect
	chunks []ChunkContent
	size() (int, int)
	inner_pos() (int, int)
	inner_size() (int, int)
	update_chunks(cv &ChunkView)
}

struct TextChunk {
mut:
	x     int
	y     int
	bb    Rect
	text  string
	style string // related to ChunkView text_styles
}

[params]
pub struct TextChunkParams {
	x     int
	y     int
	text  string
	style string // related to ChunkView text_styles
}

pub fn textchunk(p TextChunkParams) TextChunk {
	return TextChunk{
		x: p.x
		y: p.y
		text: p.text
		style: p.style
	}
}

fn (mut c TextChunk) init(cv &ChunkView) {
	c.update_bounding_box(cv)
}

fn (mut c TextChunk) draw_device(d DrawDevice, cv &ChunkView, offset Offset) {
	mut dtw := DrawTextWidget(cv)
	dtw.draw_device_styled_text(d, cv.x + offset.x + c.x, cv.y + offset.y + c.y, c.text,
		id: c.style)
}

fn (mut c TextChunk) update_bounding_box(cv &ChunkView, offset Offset) {
	mut dtw := DrawTextWidget(cv)
	cv.load_style(c.style)
	// c.bb.w, c.bb.h = dtw.text_size(c.text)
	// println("style: ${c.style} bb: ${c.bb} text_bounds ${dtw.text_bounds(c.x, c.y, c.text)}")
	bb := dtw.text_bounds(cv.x + offset.x + c.x, cv.y + offset.y + c.y, c.text)
	c.bb.x, c.bb.y, c.bb.w, c.bb.h = int(bb[0]), int(bb[1]) + int(bb[4]), int(bb[2]), int(bb[3])
}

struct ImageChunk {
mut:
	bb  Rect
	img string
}

pub struct ImageChunkParams {
	x      int
	y      int
	width  int
	height int
	img    string
}

pub fn imgchunk(p ImageChunkParams) ImageChunk {
	return ImageChunk{
		bb: Rect{p.x, p.y, p.width, p.height}
		img: p.img
	}
}

fn (mut c ImageChunk) init(cv &ChunkView) {}

fn (mut c ImageChunk) draw_device(d DrawDevice, cv &ChunkView, offset Offset) {
}

fn (mut c ImageChunk) update_bounding_box(cv &ChunkView, offset Offset) {
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

fn (mut c DrawChunk) draw_device(d DrawDevice, cv &ChunkView, offset Offset) {
}

fn (mut c DrawChunk) update_bounding_box(cv &ChunkView, offset Offset) {
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
	chunks      []ChunkContent
	parent      ?ChunkContainer
}

[params]
pub struct ParaChunkParams {
	x       int
	y       int
	margin  int
	indent  int
	spacing int = 10
	content []string
	parent  ?ChunkContainer
}

pub fn parachunk(c ParaChunkParams) ParaChunk {
	return ParaChunk{
		x: c.x
		y: c.y
		margin: c.margin
		indent: c.indent
		content: c.content
		parent: c.parent
	}
}

fn (mut c ParaChunk) init(cv &ChunkView) {
	if c.parent == none {
		c.parent = cv
	}
	c.update_line_height(cv)
	c.update_chunks(cv)
}

fn (mut c ParaChunk) update_line_height(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	mut lh := 0
	mut style, mut left := '', ''
	for content in c.content {
		if content.index_after(ui.para_style_delim, 0) == 0 {
			content_start := content.index_after(ui.para_style_delim, 1)
			if content_start > 1 { // empty style means same style
				style = content[1..content_start]
			}
			cv.load_style(style)
			left = content[(content_start + 1)..]
			lh = dtw.text_height(left)
			if lh > c.line_height {
				c.line_height = lh
			}
		}
	}
}

fn (mut c ParaChunk) update_chunks(cv &ChunkView) {
	max_line_width, _ := c.parent?.size()
	// println("max_line_width=${max_line_width}")
	mut dtw := DrawTextWidget(cv)
	// convert content to chunks
	mut chunks := []ChunkContent{}
	mut style := ''
	mut left, mut right := '', ''
	mut x, mut y := c.x + c.indent + c.margin, c.y
	mut line, mut line_width := '', f64(x)
	mut lw := 0.0
	mut ind := 0
	mut add_chunk := false

	for content in c.content {
		if content.index_after(ui.para_style_delim, 0) == 0 {
			content_start := content.index_after(ui.para_style_delim, 1)
			if content_start > 1 { // empty style means same style
				style = content[1..content_start]
			}
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
						chunk := textchunk(x: x, y: y, text: line, style: style)
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
		} else {
			if content == 'br' {
				// new line
				x, y = c.x + c.indent + c.margin, y + c.line_height + c.spacing
				line, line_width = '', f64(x)
			}
		}
	}
	c.chunks = chunks
	// update boundig boxes of all chunks
	// c.update_bounding_box(cv)
	$if parachunk ? {
		println('chunks=${c.chunks}')
		println('max_line_width=${max_line_width}')
	}
}

fn (mut c ParaChunk) draw_device(d DrawDevice, cv &ChunkView, offset Offset) {
	for mut chunk in c.chunks {
		chunk.draw_device(d, cv, offset)
	}
	$if p_bb ? {
		ChunkContent(c).draw_bb(cv)
	}
}

fn (mut c ParaChunk) update_bounding_box(cv &ChunkView, offset Offset) {
	mut bb := Rect{}
	for mut chunk in c.chunks {
		chunk.update_bounding_box(cv, offset)
		bb = bb.combine(chunk.bb)
	}
	c.bb = bb
}

fn (mut c ParaChunk) size() (int, int) {
	return c.bb.w, c.bb.h
}

fn (mut c ParaChunk) inner_pos() (int, int) {
	return c.x, c.y
}

fn (mut c ParaChunk) inner_size() (int, int) {
	return c.size()
}

// Aligned chunks (not ParaChunk)

struct VerticalAlignChunk {
mut:
	x      int
	y      int
	bb     Rect
	align  f32 // in [0,1]
	chunks []ChunkContent
}

[params]
pub struct VerticalAlignChunkParams {
	x      int
	y      int
	align  f32 // in [0,1]
	chunks []ChunkContent
}

pub fn valignchunk(p VerticalAlignChunkParams) VerticalAlignChunk {
	return VerticalAlignChunk{
		x: p.x
		y: p.y
		align: p.align
		chunks: p.chunks
	}
}

fn (mut c VerticalAlignChunk) init(cv &ChunkView) {
	for mut chunk in c.chunks {
		chunk.init(cv)
	}
}

fn (mut c VerticalAlignChunk) draw_device(d DrawDevice, cv &ChunkView, offset Offset) {
}

fn (mut c VerticalAlignChunk) update_bounding_box(cv &ChunkView, offset Offset) {
}

// Row Layout Chunk (also a ChunkContainer)
struct RowChunk {
mut:
	x       int
	y       int
	offset  Offset // used to locate chunks one after one
	bb      Rect
	chunks  []ChunkContent
	spacing int
	parent  ?ChunkContainer
	// style
	bg_radius    int
	bg_color     gx.Color
	border_color gx.Color
}

[params]
pub struct RowChunkParams {
	x       int
	y       int
	chunks  []ChunkContent
	spacing int
	parent  ?ChunkContainer
	// style
	bg_radius    int
	bg_color     gx.Color = no_color
	border_color gx.Color
}

pub fn rowchunk(p RowChunkParams) RowChunk {
	return RowChunk{
		x: p.x
		y: p.y
		chunks: p.chunks
		spacing: p.spacing
		parent: p.parent
		bg_radius: p.bg_radius
		bg_color: p.bg_color
		border_color: p.border_color
	}
}

fn (mut c RowChunk) init(cv &ChunkView) {
	if c.parent == none {
		c.parent = cv
	}
	for mut chunk in c.chunks {
		chunk.init(cv)
	}
	c.update_bounding_box(cv)
}

fn (mut c RowChunk) draw_device(d DrawDevice, cv &ChunkView, offset Offset) {
	if c.bg_color != no_color {
		if c.bg_radius > 0 {
			radius := relative_size(c.bg_radius, c.bb.w, c.bb.h)
			d.draw_rounded_rect_filled(c.bb.x, c.bb.y, c.bb.w, c.bb.h, radius, c.bg_color)
		} else {
			// println("$s.id ($s.real_x, $s.real_y, $s.real_width, $s.real_height), $s.bg_color")
			d.draw_rect_filled(c.bb.x, c.bb.y, c.bb.w, c.bb.h, c.bg_color)
		}
	}
	mut dx, mut dy := c.x + offset.x, c.y + offset.y
	for mut chunk in c.chunks {
		chunk.draw_device(d, cv, Offset{dx, dy})
		dy += chunk.bb.h + c.spacing
	}
	$if r_bb ? {
		ChunkContent(c).draw_bb(cv)
	}
}

fn (mut c RowChunk) update_bounding_box(cv &ChunkView, offset Offset) {
	mut bb := Rect{}
	mut dx, mut dy := c.x + offset.x, c.y + offset.y
	for mut chunk in c.chunks {
		chunk.update_bounding_box(cv, Offset{dx, dy})
		bb = bb.combine(chunk.bb)
		dy += chunk.bb.h + c.spacing
	}

	c.bb = bb
}

fn (mut c RowChunk) size() (int, int) {
	return c.bb.w, c.bb.h
}

fn (mut c RowChunk) update_chunks(cv &ChunkView) {
	for mut chunk in c.chunks {
		if mut chunk is ChunkContainer {
			chunk.update_chunks(cv)
		}
	}
	c.update_bounding_box(cv)
}

fn (mut c RowChunk) inner_pos() (int, int) {
	return c.x, c.y
}

fn (mut c RowChunk) inner_size() (int, int) {
	return c.size()
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
	// println('propose_size ${cv.id}: ${cv.size()}')
	cv.update_chunks(cv)
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

fn (mut cv ChunkView) inner_pos() (int, int) {
	return cv.x, cv.y
}

fn (mut cv ChunkView) inner_size() (int, int) {
	return cv.size()
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

fn (mut cv ChunkView) update_chunks(cv2 &ChunkView) {
	for mut chunk in cv.chunks {
		if mut chunk is ChunkContainer {
			chunk.update_chunks(cv2)
		}
	}
}
