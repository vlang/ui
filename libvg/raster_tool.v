module libvg

import math
import gx

//***************************************************************//
// IMPORTANT: All this nice work is directly inspired from x.ttf //
//  (@penguindark: Copyright (c) 2021 Dario Deledda)             //
//***************************************************************//
/******************************************************************************
*
* Filler functions
*
******************************************************************************/
pub fn (mut r Raster) init_filler() {
	h := r.height - r.filler.len
	if h < 1 {
		return
	}
	for _ in 0 .. h {
		r.filler << []int{len: 4}
	}
	// dprintln("Init filler: ${r.filler.len} rows")
}

pub fn (mut r Raster) clear_filler() {
	for i in 0 .. r.height {
		r.filler[i].clear()
	}
}

pub fn (mut r Raster) exec_filler(color gx.Color) {
	for y in 0 .. r.height {
		if r.filler[y].len > 0 {
			r.filler[y].sort()
			if r.filler[y].len & 1 != 0 {
				// dprintln("even line!! $y => ${r.filler[y]}")
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
					r.set_pixel(y, x, color)
				}
				index += 2
			}
		}
	}
}

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
[inline]
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

pub fn (mut r Raster) box(in_x0 int, in_y0 int, in_x1 int, in_y1 int, c gx.Color) {
	r.line(in_x0, in_y0, in_x1, in_y0, c)
	r.line(in_x1, in_y0, in_x1, in_y1, c)
	r.line(in_x0, in_y1, in_x1, in_y1, c)
	r.line(in_x0, in_y0, in_x0, in_y1, c)
}

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

fn color_multiply_alpha(c gx.Color, a f64) gx.Color {
	return gx.Color{c.r, c.g, c.b, byte(c.a * a)}
}
