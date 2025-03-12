module ui

import gg
import gx
import math

/*
Goal: propose a viewer of chunk sequence
*/

const text_chunk_wrap = 10

const para_style_delim = '|'

// const empty_chunk_container = rowlayoutchunk()

@[params]
pub struct Offset {
pub mut:
	x int
	y int
}

pub interface ChunkContent {
mut:
	bb Rect
	init(cv &ChunkView)
	draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) // offset only used for groupchunk children
	update_bounding_box(cv &ChunkView, offset Offset)
}

fn (cc ChunkContent) draw_bb(cv &ChunkView) {
	col := gx.red
	println('bb: ${cc.type_name()} (${cc.bb.x}, ${cc.bb.y} ,${cc.bb.w}, ${cc.bb.h})')
	cv.ui.dd.draw_rect_empty(cc.bb.x, cc.bb.y, cc.bb.w, cc.bb.h, col)
}

// ChunkView, ParaChunk, RowChunk, VerticalAlignChunk
interface ChunkContainer {
mut:
	x         int
	y         int
	bb        Rect
	chunks    []ChunkContent
	container ?ChunkContainer
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

@[params]
pub struct TextChunkParams {
pub:
	x     int
	y     int
	text  string
	style string // related to ChunkView text_styles
}

pub fn textchunk(p TextChunkParams) TextChunk {
	return TextChunk{
		x:     p.x
		y:     p.y
		text:  p.text
		style: p.style
	}
}

fn (mut c TextChunk) init(cv &ChunkView) {
	c.update_bounding_box(cv)
}

fn (mut c TextChunk) draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) {
	mut dtw := DrawTextWidget(cv)
	dtw.draw_device_styled_text(d, cv.x + offset.x + c.x, cv.y + offset.y + c.y, c.text, id: c.style)
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
		bb:  Rect{p.x, p.y, p.width, p.height}
		img: p.img
	}
}

fn (mut c ImageChunk) init(cv &ChunkView) {}

fn (mut c ImageChunk) draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) {
}

fn (mut c ImageChunk) update_bounding_box(cv &ChunkView, offset Offset) {
}

type DrawChunkFn = fn (&DrawChunk)

struct DrawChunk {
mut:
	bb     Rect
	state  voidptr     = unsafe { nil }
	drawfn DrawChunkFn = unsafe { nil }
}

pub fn drawchunk(drawfn DrawChunkFn, state voidptr) DrawChunk {
	return DrawChunk{
		drawfn: drawfn
		state:  state
	}
}

fn (mut c DrawChunk) init(cv &ChunkView) {}

fn (mut c DrawChunk) draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) {
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
	container   ?ChunkContainer
	// clipping
	clipping bool = true
	width    int
	height   int
}

@[params]
pub struct ParaChunkParams {
pub:
	x         int
	y         int
	margin    int
	indent    int
	spacing   int = 10
	content   []string
	container ?ChunkContainer
}

pub fn parachunk(p ParaChunkParams) ParaChunk {
	return ParaChunk{
		x:         p.x
		y:         p.y
		margin:    p.margin
		spacing:   p.spacing
		indent:    p.indent
		content:   p.content
		container: p.container
	}
}

fn (mut c ParaChunk) init(cv &ChunkView) {
	// if c.container == none {
	// 	c.container = cv
	// }
	c.update_line_height(cv)
	c.update_chunks(cv)
}

fn (mut c ParaChunk) update_clipping() {
	if mut container := c.container {
		if mut container is RowChunk {
			// println("HHHHHHHH ${container.inner_size()}")
			c.width, c.height = container.full_width_bb.w, container.full_width_bb.h
		}
	} else {
		c.width, c.height = c.bb.w, c.bb.h
	}
	// println("$c.x, $c.y, $c.width, $c.height")
}

fn (mut c ParaChunk) update_line_height(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	mut lh := 0
	mut style, mut left := '', ''
	for content in c.content {
		if content.index_after(para_style_delim, 0) or { -1 } == 0 {
			content_start := content.index_after(para_style_delim, 1) or { -1 }
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
	c.update_clipping()
	max_line_width := c.width - 10
	// max_line_width, _ := c.container?.inner_size()
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
	mut add_chunk := cv.has_scrollview // false

	for content in c.content {
		if content.index_after(para_style_delim, 0) or { -1 } == 0 {
			content_start := content.index_after(para_style_delim, 1) or { -1 }
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
						|| line_width + lw < max_line_width - c.margin * 2 - text_chunk_wrap {
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
						add_chunk = cv.has_scrollview // false
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

fn (mut c ParaChunk) draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) {
	// c.update_clipping()
	// cstate := clipping_start(c, mut d) or { return }
	// defer {
	// 	clipping_end(c, mut d, cstate)
	// }
	for mut chunk in c.chunks {
		chunk.draw_device(mut d, cv, offset)
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

pub struct VerticalAlignChunk {
mut:
	x           int
	y           int
	bb          Rect
	line_height int
	content     []string
	line_chunks [][]ChunkContent
	chunks      []ChunkContent
	container   ?ChunkContainer
	// clipping
	clipping bool = true
	width    int
	height   int
pub mut:
	align   f32 // in [0,1]
	spacing int
}

@[params]
pub struct AlignChunkParams {
pub:
	x         int
	y         int
	spacing   int = 10
	content   []string
	container ?ChunkContainer
}

@[params]
pub struct VerticalAlignChunkParams {
	AlignChunkParams
pub:
	align f32 // in [0,1]
}

pub fn valignchunk(p VerticalAlignChunkParams) VerticalAlignChunk {
	return VerticalAlignChunk{
		x:       p.x
		y:       p.y
		align:   p.align
		spacing: p.spacing
		content: p.content
	}
}

pub fn leftchunk(p AlignChunkParams) VerticalAlignChunk {
	return VerticalAlignChunk{
		x:       p.x
		y:       p.y
		align:   0.0
		spacing: p.spacing
		content: p.content
	}
}

pub fn rightchunk(p AlignChunkParams) VerticalAlignChunk {
	return VerticalAlignChunk{
		x:       p.x
		y:       p.y
		align:   1.0
		spacing: p.spacing
		content: p.content
	}
}

pub fn centerchunk(p AlignChunkParams) VerticalAlignChunk {
	return VerticalAlignChunk{
		x:       p.x
		y:       p.y
		align:   0.5
		spacing: p.spacing
		content: p.content
	}
}

fn (mut c VerticalAlignChunk) init(cv &ChunkView) {
	for mut chunk in c.chunks {
		if mut chunk is ChunkContainer {
			chunk.container = c
		}
		chunk.init(cv)
	}
	c.update_line_height(cv)
	c.init_line_chunks(cv)
}

fn (mut c VerticalAlignChunk) update_clipping() {
	if container := c.container {
		if container is RowChunk {
			c.x, c.y, c.width, c.height = container.full_width_bb.x, container.full_width_bb.y, container.full_width_bb.w, container.full_width_bb.h
		}
	}
	// println("$c.x, $c.y, $c.width, $c.height")
}

fn (mut c VerticalAlignChunk) draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) {
	if !cv.has_scrollview {
		c.update_clipping()
		cstate := clipping_start(c, mut d) or { return }
		defer {
			clipping_end(c, mut d, cstate)
		}
	}
	for mut chunk in c.chunks {
		chunk.draw_device(mut d, cv, offset)
	}
	$if p_bb ? {
		ChunkContent(c).draw_bb(cv)
	}
}

fn (mut c VerticalAlignChunk) update_bounding_box(cv &ChunkView, offset Offset) {
	mut bb := Rect{}
	for mut chunk in c.chunks {
		chunk.update_bounding_box(cv, offset)
		// println("vac add $chunk.bb")
		bb = bb.combine(chunk.bb)
	}
	// println("vac $bb")
	c.bb = bb
}

fn (mut c VerticalAlignChunk) size() (int, int) {
	return c.bb.w, c.bb.h
}

fn (mut c VerticalAlignChunk) inner_pos() (int, int) {
	return c.x, c.y
}

fn (mut c VerticalAlignChunk) inner_size() (int, int) {
	return c.size()
}

fn (mut c VerticalAlignChunk) update_line_height(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	mut lh := 0
	mut style, mut left := '', ''
	for content in c.content {
		if content.index_after(para_style_delim, 0) or { -1 } == 0 {
			content_start := content.index_after(para_style_delim, 1) or { -1 }
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

// only once in init
fn (mut c VerticalAlignChunk) init_line_chunks(cv &ChunkView) {
	mut dtw := DrawTextWidget(cv)
	// split c.content into the lines 'br' being the separator
	mut contents := [][]string{}
	mut lines := []string{}
	for content in c.content {
		if content.index_after(para_style_delim, 0) or { -1 } == 0 {
			if lines.len > 0 && lines[0] == 'br' {
				contents << lines
				lines = []string{}
			}
			lines << content
		} else {
			if content == 'br' {
				if lines.len > 0 && lines[0] != 'br' {
					contents << lines
					lines = []string{}
				}
				lines << content
			}
		}
	}
	if c.content.len > 0 {
		contents << lines
	}
	// println('contents: ${contents}')
	// convert content to chunks
	c.line_chunks = [][]ChunkContent{}
	mut style := ''
	mut text := ''
	mut x, mut y := 0, c.y // x = 0 at start but will be modified by offset when drawn if visible
	mut tw := 0.0
	for line_content in contents {
		if line_content.len > 0 && line_content[0] == 'br' {
			// jump line
			y += line_content.len * (c.line_height + c.spacing)
			x = 0
		} else {
			mut chunks := []ChunkContent{}
			c.line_chunks << chunks
			for content in line_content {
				// TextChunk
				if content.index_after(para_style_delim, 0) or { -1 } == 0 {
					content_start := content.index_after(para_style_delim, 1) or { -1 }
					if content_start > 1 { // empty style means same style
						style = content[1..content_start]
					}
					cv.load_style(style)
					text = content[(content_start + 1)..]
					tw = dtw.text_width_additive(text)
					mut chunk := textchunk(x: x, y: y, text: text, style: style)
					chunk.bb = Rect{x, y, int(tw), c.line_height}
					x += int(tw)
					c.line_chunks.last() << chunk
				} else {
					// Maybe to deal with ImageChunk and DrawChunk
				}
			}
		}
	}
	// println("line_chunks = $c.line_chunks")
}

fn (mut c VerticalAlignChunk) update_chunks(cv &ChunkView) {
	c.update_clipping()
	max_line_width := c.width - 10 // c.container?.inner_size()
	winf, wsup := -c.align * max_line_width, (f32(1) - c.align) * max_line_width
	// this is a selection step required after resizing
	c.chunks = []ChunkContent{}
	for line_chunk in c.line_chunks {
		last := line_chunk[line_chunk.len - 1]
		delta := -c.align * (last.bb.x + last.bb.w)
		for chunk in line_chunk {
			// This is the visible part
			binf := chunk.bb.x + delta
			bsup := binf + chunk.bb.w
			if bsup >= winf && wsup >= binf {
				if chunk is TextChunk {
					mut new_chunk := textchunk(
						x:     int(binf - winf)
						y:     chunk.bb.y
						text:  chunk.text
						style: chunk.style
					)
					new_chunk.bb.x = int(binf - winf)
					new_chunk.bb.y = chunk.bb.y
					new_chunk.bb.w = chunk.bb.w
					new_chunk.bb.h = chunk.bb.h
					c.chunks << new_chunk
				}
			}
		}
	}
}

// Row Layout Chunk (also a ChunkContainer)
pub struct RowChunk {
mut:
	x         int
	y         int
	offset    Offset // used to locate chunks one after one
	bb        Rect
	spacing   int
	margin    int
	container ?ChunkContainer
	// style
	full_width    bool
	full_width_bb Rect
pub mut:
	chunks       []ChunkContent
	bg_radius    int
	bg_color     gx.Color
	border_color gx.Color
}

@[params]
pub struct RowChunkParams {
pub:
	x         int
	y         int
	chunks    []ChunkContent
	spacing   int
	margin    int
	container ?ChunkContainer
	// style
	full_width   bool = true
	bg_radius    int
	bg_color     gx.Color = no_color
	border_color gx.Color
}

pub fn rowchunk(p RowChunkParams) RowChunk {
	return RowChunk{
		x:            p.x
		y:            p.y
		chunks:       p.chunks
		spacing:      p.spacing
		margin:       p.margin
		container:    p.container
		full_width:   p.full_width
		bg_radius:    p.bg_radius
		bg_color:     p.bg_color
		border_color: p.border_color
	}
}

fn (mut c RowChunk) init(cv &ChunkView) {
	if c.container == none {
		c.container = cv
	}
	for mut chunk in c.chunks {
		if mut chunk is ChunkContainer {
			chunk.container = c
		}
		chunk.init(cv)
	}
	c.update_bounding_box(cv)
}

fn (mut c RowChunk) draw_device(mut d DrawDevice, cv &ChunkView, offset Offset) {
	if c.bg_color != no_color {
		mut x, mut y, w, h := c.full_width_bb.x, c.full_width_bb.y, c.full_width_bb.w, c.full_width_bb.h
		if cv.has_scrollview {
			x -= cv.scrollview.offset_x
			y -= cv.scrollview.offset_y
		}
		if c.bg_radius > 0 {
			radius := relative_size(c.bg_radius, w, h)
			d.draw_rounded_rect_filled(x, y, w, h, radius, c.bg_color)
		} else {
			// println("$s.id ($s.real_x, $s.real_y, $s.real_width, $s.real_height), $s.bg_color")
			d.draw_rect_filled(c.bb.x, c.bb.y, c.bb.w, c.bb.h, c.bg_color)
		}
	}
	mut dx, mut dy := c.x + c.margin + offset.x, c.y + c.margin + offset.y
	for mut chunk in c.chunks {
		chunk.draw_device(mut d, cv, Offset{dx, dy})
		dy += chunk.bb.h + c.spacing
	}
	$if r_bb ? {
		ChunkContent(c).draw_bb(cv)
	}
}

fn (mut c RowChunk) update_bounding_box(cv &ChunkView, offset Offset) {
	mut bb := Rect{}
	mut dx, mut dy := c.x + c.margin + offset.x, c.y + c.margin + offset.y
	for mut chunk in c.chunks {
		chunk.update_bounding_box(cv, Offset{dx, dy})
		bb = bb.combine(chunk.bb)
		dy += chunk.bb.h + c.spacing
	}

	c.bb = bb
	c.bb.x -= c.margin
	c.bb.y -= c.margin
	c.bb.w += 2 * c.margin
	c.bb.h += 2 * c.margin

	// full_width mode
	mut x, y := c.bb.x, c.bb.y - c.margin
	mut w, h := c.bb.w, c.bb.h
	if c.full_width {
		x, _ = c.inner_pos()
		// x, _ = c.container?.inner_pos()
		x += c.margin + offset.x
		// w, _ = c.container?.inner_size()
		w, _ = c.inner_size()
	}
	c.full_width_bb = Rect{x, y, w, h}
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
	return c.x + c.margin, c.y + c.margin
}

fn (mut c RowChunk) inner_size() (int, int) {
	if mut container := c.container {
		w, h := container.inner_size()
		return w - 2 * c.margin, h - 2 * c.margin
	} else {
		return -1, -1
	}
}

@[heap]
pub struct ChunkView {
pub mut:
	ui        &UI = unsafe { nil }
	id        string
	x         int
	y         int
	z_index   int
	offset_x  int
	offset_y  int
	hidden    bool
	parent    Layout = empty_stack
	container ?ChunkContainer
	clipping  bool
	// ChunkView specific field
	bb Rect
	// text styles
	text_styles TextStyles
	// images
	cache map[string]gg.Image
	// scrollview
	has_scrollview   bool
	scrollview       &ScrollView         = unsafe { nil }
	on_scroll_change ScrollViewChangedFn = unsafe { ScrollViewChangedFn(0) }
	bg_color         gx.Color
	width            int
	height           int
	chunks           []ChunkContent // sorted with respect of ChunkList bounding box
}

@[params]
pub struct ChunkViewParams {
pub:
	id               string
	chunks           []ChunkContent
	clipping         bool                = true
	bg_color         gx.Color            = gx.white
	scrollview       bool                = true
	on_scroll_change ScrollViewChangedFn = unsafe { ScrollViewChangedFn(0) }
}

pub fn chunkview(p ChunkViewParams) &ChunkView {
	mut cv := &ChunkView{
		id:               p.id
		chunks:           p.chunks
		clipping:         p.clipping
		bg_color:         p.bg_color
		on_scroll_change: p.on_scroll_change
	}
	if p.scrollview {
		scrollview_add(mut cv)
	}
	return cv
}

fn (mut cv ChunkView) init(parent Layout) {
	cv.parent = parent
	ui_ := parent.get_ui()
	cv.ui = ui_
	for mut chunk in cv.chunks {
		chunk.init(cv)
	}
	if has_scrollview(cv) {
		cv.scrollview.init(parent)
		cv.ui.window.evt_mngr.add_receiver(cv, [events.on_scroll])
		scrollview_update(cv)
	}
}

fn (cv &ChunkView) load_style(style string) {
	mut dtw := DrawTextWidget(cv)
	dtw.set_current_style(id: style) // to update style for text_width_additive
	dtw.load_style()
}

fn (mut cv ChunkView) set_pos(x int, y int) {
	scrollview_widget_save_offset(cv)
	cv.x, cv.y = x, y
	scrollview_widget_restore_offset(cv, true)
}

fn (mut cv ChunkView) propose_size(w int, h int) (int, int) {
	cv.width, cv.height = w, h
	// println('propose_size ${cv.id}: ${cv.size()}')
	cv.update()
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
	if cv.has_scrollview {
		return cv.x + cv.scrollview.offset_x, cv.y + cv.scrollview.offset_y
	} else {
		return cv.x, cv.y
	}
}

fn (mut cv ChunkView) inner_size() (int, int) {
	if cv.has_scrollview {
		return cv.bb.w, cv.bb.h
	} else {
		return math.max(cv.width, cv.bb.w), math.max(cv.height, cv.bb.h)
	}
}

fn (mut cv ChunkView) point_inside(x f64, y f64) bool {
	if cv.has_scrollview {
		return cv.scrollview.point_inside(x, y, .view)
	} else {
		return point_inside(cv, x, y)
	}
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
	scrollview_draw_begin(mut cv, d)
	defer {
		scrollview_draw_end(cv, d)
	}
	cstate := clipping_start(cv, mut d) or { return }
	defer {
		clipping_end(cv, mut d, cstate)
	}
	if cv.bg_color != no_color {
		x, y := cv.inner_pos()
		d.draw_rect_filled(x, y, cv.width, cv.height, cv.bg_color)
	}
	for mut chunk in cv.chunks {
		chunk.draw_device(mut d, cv)
	}
	$if bb ? {
		debug_draw_bb_widget(mut cv, cv.ui)
	}
}

fn (cv &ChunkView) set_children_pos() {}

fn (mut cv ChunkView) cleanup() {}

fn (mut cv ChunkView) update_chunks(cv2 &ChunkView) {
	for mut chunk in cv.chunks {
		if mut chunk is ChunkContainer {
			chunk.update_chunks(cv2)
		}
	}
}

pub fn (mut cv ChunkView) update() {
	cv.update_chunks(cv)
	scrollview_update(cv)
}

pub fn (mut cv ChunkView) chunk(from ...int) ChunkContent {
	if from.len > 0 {
		mut chunks := cv.chunks.clone()
		for i, ind in from {
			// println("c $i $ind")
			c := chunks[ind]
			// println("c2 $i $ind")
			if i == from.len - 1 {
				// println("last")
				return c
			}
			if c is RowChunk {
				// println("chunk $i $ind")
				chunks = c.chunks.clone()
				// println("chunk2 $i $ind")
			}
		}
	}
	return textchunk()
}
