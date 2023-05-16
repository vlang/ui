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

fn (mut cc TextChunk) draw_device(d DrawDevice, cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	dtw.draw_device_styled_text(d, cv.x + cc.bb.x, cv.y + cc.bb.y, cc.text, id: cc.style)
}

fn (mut cc TextChunk) update_bounding_box(cv &ChunkView) {
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

fn (mut cc ImageChunk) draw_device(d DrawDevice, cv &ChunkView) {
}

fn (mut cc ImageChunk) update_bounding_box(cv &ChunkView) {
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

fn (mut cc DrawChunk) draw_device(d DrawDevice, cv &ChunkView) {
}

fn (mut cc DrawChunk) update_bounding_box(cv &ChunkView) {
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
	width    int
	height   int
	// ChunkView specific field
	bb     Rect
	chunks []ChunkContent // sorted with respect of ChunkList bounding box
	// text styles
	text_styles TextStyles
	// images
	cache map[string]gg.Image
}

[params]
pub struct ChunkViewParams {
	id     string
	chunks []ChunkContent
}

pub fn chunkview(c ChunkViewParams) &ChunkView {
	return &ChunkView{
		id: c.id
		chunks: c.chunks
	}
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
