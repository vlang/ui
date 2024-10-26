module libvg

import math
import gx
import x.ttf
import encoding.utf8

//***************************************************************//
// IMPORTANT: All this nice work is directly inspired from x.ttf //
//  (@penguindark: Copyright (c) 2021 Dario Deledda)             //
//***************************************************************//
/******************************************************************************
*
* Filler functions
*
******************************************************************************/
// TODO: documentation
pub fn (mut r Raster) init_filler() {
	h := r.height - r.filler.len
	// println("init_filler h $h = $r.height - $r.filler.len")
	if h < 1 {
		return
	}
	for _ in 0 .. h {
		r.filler << []int{len: 4}
	}
	// println("Init filler: ${r.filler.len} rows ${r.filler[0].len}")
}

// TODO: documentation
pub fn (mut r Raster) clear_filler() {
	for i in 0 .. r.height {
		r.filler[i].clear()
	}
}

// TODO: documentation
pub fn (mut r Raster) exec_filler(color gx.Color) {
	// println("exec filler inside $r.height")
	for y in 0 .. r.height {
		// println("${r.filler[y].len} > 0")
		if r.filler[y].len > 0 {
			r.filler[y].sort()
			if r.filler[y].len & 1 != 0 {
				// println("even line!! $y => ${r.filler[y]}")
				continue
			}
			mut index := 0
			for index < r.filler[y].len {
				startx := r.filler[y][index] + 1
				endx := r.filler[y][index + 1]
				if startx >= endx {
					index += 2
					continue
				}
				for x in startx .. endx {
					// println(" exec filler set pixel $x $y $color")
					r.set_pixel(y, x, color)
				}
				index += 2
			}
		}
	}
}

// TODO: documentation
pub fn (mut r Raster) fline(in_x0 int, in_y0 int, in_x1 int, in_y1 int, c gx.Color) {
	mut x0 := f32(in_x0)
	mut x1 := f32(in_x1)
	mut y0 := f32(in_y0)
	mut y1 := f32(in_y1)
	mut tmp := f32(0)

	// check bounds
	if (in_x0 < 0 && in_x1 < 0) || (in_x0 > r.width && in_x1 > r.width) {
		return
	}

	if y1 < y0 {
		tmp = x0
		x0 = x1
		x1 = tmp

		tmp = y0
		y0 = y1
		y1 = tmp
	}

	mut dx := x1 - x0
	mut dy := y1 - y0

	if dy == 0 {
		if in_y0 >= 0 && in_y0 < r.filler.len {
			if in_x0 <= in_x1 {
				r.filler[in_y0] << in_x0
				r.filler[in_y0] << in_x1
			} else {
				r.filler[in_y0] << in_x1
				r.filler[in_y0] << in_x0
			}
		}
		return
	}
	mut n := dx / dy
	for y in 0 .. int(dy + 0.5) {
		yd := int(y + y0)
		x := n * y + x0
		if x > r.width || yd >= r.filler.len {
			break
		}
		if yd >= 0 && yd < r.filler.len {
			r.filler[yd] << int(x + 0.5)
			// r.set_pixel(yd, int(x+0.5), r.color)
		}
	}
}

/******************************************************************************
*
* Draw functions
*
******************************************************************************/

// aline draw an aliased line on the bitmap
@[inline]
pub fn (mut r Raster) aline(in_x0 int, in_y0 int, in_x1 int, in_y1 int, c gx.Color) {
	mut x0 := f32(in_x0)
	mut x1 := f32(in_x1)
	mut y0 := f32(in_y0)
	mut y1 := f32(in_y1)
	mut tmp := f32(0)

	mut dx := x1 - x0
	mut dy := y1 - y0

	dist := f32(0.4)

	if math.abs(dx) > math.abs(dy) {
		if x1 < x0 {
			tmp = x0
			x0 = x1
			x1 = tmp

			tmp = y0
			y0 = y1
			y1 = tmp
		}
		dx = x1 - x0
		dy = y1 - y0

		x0 += 0.5
		y0 += 0.5

		m := dy / dx
		mut x := x0
		for x <= x1 + 0.5 {
			y := m * (x - x0) + y0
			e := 1 - math.abs(y - 0.5 - int(y))
			r.set_pixel(int(y), int(x), color_multiply_alpha(c, e * 0.75))

			ys1 := y + dist
			if int(ys1) != int(y) {
				v1 := math.abs(ys1 - y) / dist * (1 - e)
				r.set_pixel(int(ys1), int(x), color_multiply_alpha(c, v1))
			}

			ys2 := y - dist
			if int(ys2) != int(y) {
				v2 := math.abs(y - ys2) / dist * (1 - e)
				r.set_pixel(int(ys2), int(x), color_multiply_alpha(c, v2))
			}

			x += 1.0
		}
	} else {
		if y1 < y0 {
			tmp = x0
			x0 = x1
			x1 = tmp

			tmp = y0
			y0 = y1
			y1 = tmp
		}
		dx = x1 - x0
		dy = y1 - y0

		x0 += 0.5
		y0 += 0.5

		n := dx / dy
		mut y := y0
		for y <= y1 + 0.5 {
			x := n * (y - y0) + x0
			e := f32(1 - math.abs(x - 0.5 - int(x)))
			r.set_pixel(int(y), int(x), color_multiply_alpha(c, e * 0.75))

			xs1 := x + dist
			if int(xs1) != int(x) {
				v1 := math.abs(xs1 - x) / dist * (1 - e)
				r.set_pixel(int(y), int(xs1), color_multiply_alpha(c, v1))
			}

			xs2 := x - dist
			if int(xs2) != int(x) {
				v2 := math.abs(x - xs1) / dist * (1 - e)
				r.set_pixel(int(y), int(xs2), color_multiply_alpha(c, v2))
			}
			y += 1.0
		}
	}
}

/******************************************************************************
*
* draw functions
*
******************************************************************************/
// TODO: documentation
pub fn (mut r Raster) line(in_x0 int, in_y0 int, in_x1 int, in_y1 int, c gx.Color) {
	// outline with aliased borders
	if r.style == .outline_aliased {
		r.aline(in_x0, in_y0, in_x1, in_y1, c)
		return
	}
	// filled with aliased borders
	else if r.style == .filled {
		r.aline(in_x0, in_y0, in_x1, in_y1, c)
		r.fline(in_x0, in_y0, in_x1, in_y1, c)
		return
	}
	// only the filler is drawn
	else if r.style == .raw {
		r.fline(in_x0, in_y0, in_x1, in_y1, c)
		return
	}
	// if we are here we are drawing an outlined border

	x0 := int(in_x0)
	x1 := int(in_x1)
	y0 := int(in_y0)
	y1 := int(in_y1)
	// dprintln("line[$x0,$y0,$x1,$y1]")

	mut x := x0
	mut y := y0

	dx := math.abs(x1 - x0)
	sx := if x0 < x1 { 1 } else { -1 }
	dy := -math.abs(y1 - y0)
	sy := if y0 < y1 { 1 } else { -1 }

	// verical line
	if dx == 0 {
		if y0 < y1 {
			for yt in y0 .. y1 + 1 {
				r.set_pixel(yt, x0, c)
			}
			return
		}
		for yt in y1 .. y0 + 1 {
			r.set_pixel(yt, x0, c)
		}
		// horizontal line
		return
	} else if dy == 0 {
		if x0 < x1 {
			for xt in x0 .. x1 + 1 {
				r.set_pixel(y0, xt, c)
			}
			return
		}
		for xt in x1 .. x0 + 1 {
			r.set_pixel(y0, xt, c)
		}
		return
	}

	mut err := dx + dy // error value e_xy
	for {
		// r.set_pixel(x, y, u32(0xFF00))
		r.set_pixel(y, x, c)

		// dprintln("$x $y [$x0,$y0,$x1,$y1]")
		if x == x1 && y == y1 {
			break
		}
		e2 := 2 * err
		if e2 >= dy { // e_xy+e_x > 0
			err += dy
			x += sx
		}
		if e2 <= dx { // e_xy+e_y < 0
			err += dx
			y += sy
		}
	}
}

// TODO: documentation
pub fn (mut r Raster) box(in_x0 int, in_y0 int, in_x1 int, in_y1 int, c gx.Color) {
	r.line(in_x0, in_y0, in_x1, in_y0, c)
	r.line(in_x1, in_y0, in_x1, in_y1, c)
	r.line(in_x0, in_y1, in_x1, in_y1, c)
	r.line(in_x0, in_y0, in_x0, in_y1, c)
}

// TODO: documentation
pub fn (mut r Raster) quadratic(in_x0 int, in_y0 int, in_x1 int, in_y1 int, in_cx int, in_cy int, c gx.Color) {
	/*
	x0 := int(in_x0 * r.scale)
	x1 := int(in_x1 * r.scale)
	y0 := int(in_y0 * r.scale)
	y1 := int(in_y1 * r.scale)
	cx := int(in_cx * r.scale)
	cy := int(in_cy * r.scale)
	*/
	x0 := int(in_x0)
	x1 := int(in_x1)
	y0 := int(in_y0)
	y1 := int(in_y1)
	cx := int(in_cx)
	cy := int(in_cy)

	mut division := f64(1.0)
	dx := math.abs(x0 - x1)
	dy := math.abs(y0 - y1)

	// if few pixel draw a simple line
	// if dx == 0 && dy == 0 {
	if dx <= 2 || dy <= 2 {
		// r.plot(x0, y0, c)
		r.line(x0, y0, x1, y1, c)
		return
	}

	division = 1.0 / (f64(if dx > dy { dx } else { dy }))

	// division = 0.1   // 10 division
	// division = 0.25  // 4 division

	// dprintln("div: $division")

	/*
	----- Bezier quadratic form -----
	t = 0.5; // given example value, half length of the curve
	x = (1 - t) * (1 - t) * p[0].x + 2 * (1 - t) * t * p[1].x + t * t * p[2].x;
	y = (1 - t) * (1 - t) * p[0].y + 2 * (1 - t) * t * p[1].y + t * t * p[2].y;
	---------------------------------
	*/

	mut x_old := x0
	mut y_old := y0
	mut t := 0.0

	for t <= (1.0 + division / 2.0) {
		s := 1.0 - t
		x := s * s * x0 + 2.0 * s * t * cx + t * t * x1
		y := s * s * y0 + 2.0 * s * t * cy + t * t * y1
		xi := int(x + 0.5)
		yi := int(y + 0.5)
		// r.plot(xi, yi, c)
		r.line(x_old, y_old, xi, yi, c)
		x_old = xi
		y_old = yi
		t += division
	}
}

/******************************************************************************
*
* TTF draw glyph
*
******************************************************************************/
fn (mut r Raster) draw_notdef_glyph(in_x int, in_w int) {
	mut bmp := r.bmp
	mut p := ttf.Point{in_x, 0, false}
	x1, y1 := bmp.trf_txt(p)
	// init ch_matrix
	bmp.ch_matrix[0] = bmp.tr_matrix[0] * bmp.scale * bmp.scale_x
	bmp.ch_matrix[1] = bmp.tr_matrix[1] * bmp.scale * bmp.scale_x
	bmp.ch_matrix[3] = bmp.tr_matrix[3] * -bmp.scale * bmp.scale_y
	bmp.ch_matrix[4] = bmp.tr_matrix[4] * -bmp.scale * bmp.scale_y
	bmp.ch_matrix[6] = int(x1)
	bmp.ch_matrix[7] = int(y1)
	x, y := bmp.trf_ch(p)

	y_h := math.abs(bmp.tf.y_max - bmp.tf.y_min) * bmp.scale * 0.5

	r.box(int(x), int(y), int(x - in_w), int(y - y_h), r.color)
	r.line(int(x), int(y), int(x - in_w), int(y - y_h), r.color)
	r.line(int(x - in_w), int(y), int(x), int(y - y_h), r.color)
}

// TODO: documentation
pub fn (mut r Raster) draw_text(in_string string) (int, int) {
	mut bmp := r.bmp
	mut w := 0

	mut space_cw, _ := bmp.tf.get_horizontal_metrics(u16(` `))
	div_space_cw := int((f32(space_cw) * bmp.space_mult) * bmp.scale)
	space_cw = int(space_cw * bmp.scale)

	bmp.tf.reset_kern()

	mut i := 0
	for i < in_string.len {
		mut chr := u16(in_string[i])

		// draw the space
		if int(chr) == 32 {
			w += int(space_cw * bmp.space_cw)
			i++
			continue
		}
		// manage unicode chars like latin greek etc
		c_len := ((0xe5000000 >> ((chr >> 3) & 0x1e)) & 3) + 1
		if c_len > 1 {
			tmp_char := utf8.get_rune(in_string, i)
			// dprintln("tmp_char: ${tmp_char.hex()}")
			chr = u16(tmp_char)
		}

		c_index := bmp.tf.map_code(int(chr))
		// Glyph not found
		if c_index == 0 {
			r.draw_notdef_glyph(w, int(space_cw * bmp.space_cw))
			w += int(space_cw * bmp.space_cw)
			i += c_len
			continue
		}

		ax, ay := bmp.tf.next_kern(c_index)
		// dprintln("char_index: $c_index ax: $ax ay: $ay")

		cw, _ := bmp.tf.get_horizontal_metrics(u16(chr))
		// cw, lsb := bmp.tf.get_horizontal_metrics(u16(chr))
		// dprintln("metrics: [${u16(chr):c}] cw:$cw lsb:$lsb")

		//----- Draw_Glyph transformations -----
		mut x0 := w + int(ax * bmp.scale)
		mut y0 := 0 + int(ay * bmp.scale)

		p := ttf.Point{x0, y0, false}
		x1, y1 := bmp.trf_txt(p)
		// init ch_matrix
		bmp.ch_matrix[0] = bmp.tr_matrix[0] * bmp.scale * bmp.scale_x
		bmp.ch_matrix[1] = bmp.tr_matrix[1] * bmp.scale * bmp.scale_x
		bmp.ch_matrix[3] = bmp.tr_matrix[3] * -bmp.scale * bmp.scale_y
		bmp.ch_matrix[4] = bmp.tr_matrix[4] * -bmp.scale * bmp.scale_y
		bmp.ch_matrix[6] = int(x1)
		bmp.ch_matrix[7] = int(y1)

		x_min, x_max := r.draw_glyph(c_index)
		// x_min := 1
		// x_max := 2
		//-----------------

		mut width := int((math.abs(x_max + x_min) + ax) * bmp.scale)
		if bmp.use_font_metrics {
			width = int((cw + ax) * bmp.scale)
		}
		w += width + div_space_cw
		i += c_len
	}

	// dprintln("y_min: $bmp.tf.y_min y_max: $bmp.tf.y_max res: ${int((bmp.tf.y_max - bmp.tf.y_min)*buf.scale)} width: ${int( (cw) * buf.scale)}")
	// buf.box(0,y_base - int((bmp.tf.y_min)*buf.scale), int( (x_max) * buf.scale), y_base-int((bmp.tf.y_max)*buf.scale), u32(0xFF00_0000) )
	return w, int(math.abs(int(bmp.tf.y_max - bmp.tf.y_min)) * bmp.scale)
}

// TODO: documentation
pub fn (mut r Raster) draw_glyph(index u16) (int, int) {
	mut bmp := r.bmp
	glyph := bmp.tf.read_glyph(index)
	// println("draw glyph $bmp.style")
	if !glyph.valid_glyph {
		return 0, 0
	}

	if bmp.style == .filled || bmp.style == .raw {
		r.clear_filler()
	}

	mut s := 0 // status
	mut c := 0 // contours count
	mut contour_start := 0
	mut x0 := 0
	mut y0 := 0
	color := r.color // u32(0xFFFF_FF00) // RGBA white
	// color1            := u32(0xFF00_0000) // RGBA red
	// color2            := u32(0x00FF_0000) // RGBA green

	mut sp_x := 0
	mut sp_y := 0
	mut point := ttf.Point{}

	for count, point_raw in glyph.points {
		// println("count: $count, state: $s pl:$glyph.points.len")
		point.x = point_raw.x
		point.y = point_raw.y

		point.x, point.y = bmp.trf_ch(point)
		point.on_curve = point_raw.on_curve

		if s == 0 {
			x0 = point.x
			y0 = point.y
			sp_x = x0
			sp_y = y0
			s = 1 // next state
			continue
		} else if s == 1 {
			if point.on_curve {
				r.line(x0, y0, point.x, point.y, color)
				// bmp.aline(x0, y0, point.x, point.y, u32(0xFFFF0000))
				x0 = point.x
				y0 = point.y
			} else {
				s = 2
			}
		} else {
			// dprintln("s==2")
			mut prev := glyph.points[count - 1]
			prev.x, prev.y = bmp.trf_ch(prev)
			if point.on_curve {
				// dprintln("HERE1")
				// ctx.quadraticCurveTo(prev.x + x, prev.y + y,point.x + x, point.y + y);
				// bmp.line(x0, y0, point.x + in_x, point.y + in_y, color1)
				// bmp.quadratic(x0, y0, point.x + in_x, point.y + in_y, prev.x + in_x, prev.y + in_y, u32(0xa0a00000))
				r.quadratic(x0, y0, point.x, point.y, prev.x, prev.y, color)
				x0 = point.x
				y0 = point.y
				s = 1
			} else {
				// dprintln("HERE2")
				// ctx.quadraticCurveTo(prev.x + x, prev.y + y,
				//            (prev.x + point.x) / 2 + x,
				//            (prev.y + point.y) / 2 + y);

				// bmp.line(x0, y0, (prev.x + point.x)/2, (prev.y + point.y)/2, color2)
				// bmp.quadratic(x0, y0, (prev.x + point.x)/2, (prev.y + point.y)/2, prev.x, prev.y, color2)
				r.quadratic(x0, y0, (prev.x + point.x) / 2, (prev.y + point.y) / 2, prev.x,
					prev.y, color)
				x0 = (prev.x + point.x) / 2
				y0 = (prev.y + point.y) / 2
			}
		}

		if u16(count) == glyph.contour_ends[c] {
			// println("count == glyph.contour_ends[count]")
			if s == 2 { // final point was off-curve. connect to start

				mut start_point := glyph.points[contour_start]
				start_point.x, start_point.y = bmp.trf_ch(start_point)
				if point.on_curve {
					// ctx.quadraticCurveTo(prev.x + x, prev.y + y,
					// point.x + x, point.y + y);
					// bmp.line(x0, y0, start_point.x + in_x, start_point.y + in_y, u32(0x00FF0000))

					//	start_point.x + in_x, start_point.y + in_y, u32(0xFF00FF00))
					r.quadratic(x0, y0, start_point.x, start_point.y, start_point.x, start_point.y,
						color)
				} else {
					// ctx.quadraticCurveTo(prev.x + x, prev.y + y,
					//        (prev.x + point.x) / 2 + x,
					//        (prev.y + point.y) / 2 + y);

					// bmp.line(x0, y0, start_point.x, start_point.y, u32(0x00FF0000)
					// u32(0xFF000000))
					r.quadratic(x0, y0, start_point.x, start_point.y, (point.x + start_point.x) / 2,
						(point.y + start_point.y) / 2, color)
				}
			} else {
				// last point not in a curve
				// bmp.line(point.x, point.y, sp_x, sp_y, u32(0x00FF0000))
				r.line(point.x, point.y, sp_x, sp_y, color)
			}
			contour_start = count + 1
			s = 0
			c++
		}
	}

	if bmp.style == .filled || bmp.style == .raw {
		println('exec filler ${color}')
		r.exec_filler(color)
	}
	x_min := glyph.x_min
	x_max := glyph.x_max
	return x_min, x_max

	// return glyph.x_min, glyph.x_max
}

fn color_multiply_alpha(c gx.Color, a f64) gx.Color {
	return gx.Color{c.r, c.g, c.b, u8(c.a * a)}
}

@[params]
pub struct TextBlockParams {
pub:
	x         int // x postion of the left high corner
	y         int // y postion of the left high corner
	w         int // width of the text block
	h         int // heigth of the text block
	cut_lines bool = true // force to cut the line if the length is over the text block width
}

// write out a text
pub fn (mut r Raster) draw_text_block(text string, block TextBlockParams) {
	mut bmp := r.bmp
	mut x := block.x
	mut y := block.y
	mut y_base := int((bmp.tf.y_max - bmp.tf.y_min) * bmp.scale)

	// bmp.box(x, y, x + block.w, y + block.h, u32(0xFF00_0000))

	// spaces data
	mut space_cw, _ := bmp.tf.get_horizontal_metrics(u16(` `))
	space_cw = int(space_cw * bmp.scale)

	old_space_cw := bmp.space_cw

	mut offset_flag := f32(0) // default .left align
	if bmp.align == .right {
		offset_flag = 1
	} else if bmp.align == .center {
		offset_flag = 0.5
	}

	for txt in text.split_into_lines() {
		bmp.space_cw = old_space_cw
		mut w, _ := bmp.get_bbox(txt)
		if w <= block.w || block.cut_lines == false {
			// println("Solid block!")
			left_offset := int((block.w - w) * offset_flag)
			if bmp.justify && (f32(w) / f32(block.w)) >= bmp.justify_fill_ratio {
				bmp.space_cw = old_space_cw + bmp.get_justify_space_cw(txt, w, block.w, space_cw)
			}
			bmp.set_pos(x + left_offset, y + y_base)
			r.draw_text(txt)
			//---- DEBUG ----
			// mut txt_w , mut txt_h := bmp.draw_text(txt)
			// bmp.box(x + left_offset,y+y_base - int((bmp.tf.y_min)*bmp.scale), x + txt_w + left_offset, y + y_base - int((bmp.tf.y_max) * bmp.scale), u32(0x00ff_0000) )
			//---------------
			y += y_base
		} else {
			// println("to cut: ${txt}")
			mut txt1 := txt.split(' ')
			mut c := txt1.len
			// mut done := false
			for c > 0 {
				tmp_str := txt1[0..c].join(' ')
				// println("tmp_str: ${tmp_str}")
				if tmp_str.len < 1 {
					break
				}

				bmp.space_cw = old_space_cw
				w, _ = bmp.get_bbox(tmp_str)
				if w <= block.w {
					mut left_offset := int((block.w - w) * offset_flag)
					if bmp.justify && (f32(w) / f32(block.w)) >= bmp.justify_fill_ratio {
						// println("cut phase!")
						bmp.space_cw = 0.0
						w, _ = bmp.get_bbox(tmp_str)
						left_offset = int((block.w - w) * offset_flag)
						bmp.space_cw = bmp.get_justify_space_cw(tmp_str, w, block.w, space_cw)
					} else {
						bmp.space_cw = old_space_cw
					}
					bmp.set_pos(x + left_offset, y + y_base)
					r.draw_text(tmp_str)
					//---- DEBUG ----
					// txt_w , txt_h := bmp.draw_text(tmp_str)
					// println("printing [${x},${y}] => '${tmp_str}' space_cw: $bmp.space_cw")
					// bmp.box(x + left_offset,y + y_base - int((bmp.tf.y_min)*bmp.scale), x + txt_w + left_offset, y + y_base - int((bmp.tf.y_max) * bmp.scale), u32(0x00ff_0000) )
					//---------------
					y += y_base
					txt1 = unsafe { txt1[c..] }
					c = txt1.len
					//---- DEBUG ----
					// txt2 := txt1.join(' ')
					// println("new string: ${txt2} len: ${c}")
					//---------------
				} else {
					c--
				}
			}
		}
	}

	bmp.space_cw = old_space_cw
}
