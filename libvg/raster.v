module libvg

import gg
import gx
import os
import stbi
import x.ttf

// draw style
// pub enum Style {
// 	outline
// 	outline_aliased
// 	filled
// 	raw
// }

[heap]
pub struct Raster {
pub mut:
	width     int
	height    int
	channels  int = 4
	data      []byte
	ttf_font  &ttf.TTF_File = voidptr(0)
	ttf_fonts map[string]ttf.TTF_File
	bmp       &ttf.BitMap = voidptr(0)
	color     gx.Color
	// to remove
	filler [][]int
	style  ttf.Style
}

[params]
pub struct RasterParams {
	width    int = 16
	height   int = 16
	channels int = 4
}

pub fn raster(p RasterParams) &Raster {
	r := &Raster{
		width: p.width
		height: p.height
		channels: p.channels
		data: []byte{len: p.width * p.height * p.channels}
	}
	return r
}

pub fn (mut r Raster) clear() {
	r.data = []byte{len: r.width * r.height * r.channels}
}

pub fn (mut r Raster) load(img &gg.Image) {
	// println("$img.width, $img.height, $img.nr_channels")
	// println("$img.ok, $img.simg_ok")

	r.width, r.height, r.channels = img.width, img.height, img.nr_channels
	r.data = []byte{len: r.width * r.height * r.channels}
	// println("${r.data.len}")
	unsafe { C.memcpy(r.data.data, img.data, r.data.len) }
}

pub fn (mut r Raster) load_image(mut ctx gg.Context, path string) {
	if !os.exists(path) {
		return
	}
	r.load(ctx.create_image(path))
}

pub fn (r &Raster) save_image_as(path string) {
	stbi.stbi_write_png(path, r.width, r.height, r.channels, r.data.data, r.width * r.channels) or {
		panic(err)
	}
}

pub fn (r &Raster) get_pixel(i int, j int) gx.Color {
	k := (i * r.width + j) * r.channels
	if r.channels == 4 {
		return gx.rgba(r.data[k], r.data[k + 1], r.data[k + 2], r.data[k + 3])
	} else if r.channels == 3 {
		return gx.rgb(r.data[k], r.data[k + 1], r.data[k + 2])
	}
	return gx.rgba(0, 0, 0, 0)
}

pub fn (mut r Raster) set_pixel(i int, j int, color gx.Color) {
	if j < 0 || j >= r.width || i < 0 || i >= r.height {
		return
	}
	k := (i * r.width + j) * r.channels
	// println("set_pixel($i, $j, $k=($i * $r.width + $j) * $r.channels) ($r.width, $r.height, $r.data.len) $r.channels")
	if r.channels == 4 {
		r.data[k], r.data[k + 1], r.data[k + 2], r.data[k + 3] = color.r, color.g, color.b, color.a
	} else if r.channels == 3 {
		r.data[k], r.data[k + 1], r.data[k + 2] = color.r, color.g, color.b
	}
}

pub fn (mut r Raster) rectangle_filled(x int, y int, w int, h int, color gx.Color) {
	for i in y .. (y + h) {
		for j in x .. (x + w) {
			r.set_pixel(i, j, color)
		}
	}
}

pub fn (mut r Raster) copy(r2 &Raster, x int, y int, w int, h int) {
	w2, h2 := f32(r2.width), f32(r2.height)
	mut color := gx.white
	for i in y .. (y + h) {
		for j in x .. (x + w) {
			color = r2.get_pixel(int(f32(i - y) / f32(h) * h2), int(f32(j - x) / f32(w) * w2))
			if color.a > 0 {
				r.set_pixel(i, j, color)
			}
		}
	}
}
