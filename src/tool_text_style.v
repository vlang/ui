module ui

import gx
import os
import os.font

const no_string = '_none_'

pub enum TextHorizontalAlign {
	@none = -10
	left = C.FONS_ALIGN_LEFT
	center = C.FONS_ALIGN_CENTER
	right = C.FONS_ALIGN_RIGHT
}

pub enum TextVerticalAlign {
	@none = -10
	top = C.FONS_ALIGN_TOP
	middle = C.FONS_ALIGN_MIDDLE
	bottom = C.FONS_ALIGN_BOTTOM
	baseline = C.FONS_ALIGN_BASELINE
}

// TextStyle is similar to gg.TextCfg (main difference: font_name and id)
pub struct TextStyle {
pub mut:
	// text style identifier
	id string = ui.no_string
	// fields
	font_name      string   = 'system'
	color          gx.Color = gx.black
	size           int      = 16
	align          TextHorizontalAlign = .left
	vertical_align TextVerticalAlign   = .top
	mono           bool
}

[params]
pub struct TextStyleParams {
pub mut:
	// text style identifier
	id string = ui.no_string
	// fields
	font_name      string   = ui.no_string
	color          gx.Color = no_color
	size           int      = -1
	align          TextHorizontalAlign = .@none
	vertical_align TextVerticalAlign   = .@none
}

pub struct TextStyles {
pub mut:
	current TextStyle
	hash    map[string]TextStyle
}

pub fn (t &TextStyles) style(id string) TextStyle {
	return t.hash[id]
}

// Sort of shareable FontSets between DrawTextWidget via ui field
struct FontSet {
mut:
	hash map[string]int
}

pub fn (mut ui UI) add_font(font_name string, font_path string) {
	$if fontset ? {
		println('add font ${font_name} at ${font_path}')
	}
	if mut ui.dd is DrawDeviceContext {
		// IMPORTANT: This fix issue that makes DrawTextFont not working for fontstash
		// (in fons__getGlyph, added becomes 0)
		ui.dd.ft.fons.reset_atlas(512, 512)

		bytes := os.read_bytes(font_path) or { []u8{} }
		// gg := ui.gg
		// mut f := ui.fonts
		if bytes.len > 0 {
			font_ := ui.dd.ft.fons.add_font_mem('sans', bytes, false)
			if font_ >= 0 {
				ui.font_paths[font_name] = font_path
				ui.fonts.hash[font_name] = font_
				$if fontset ? {
					println('font ${font_} ${font_name} added (${font_path})')
				}
			} else {
				$if fontset ? {
					println('font ${font_name} NOT added (${font_path})')
				}
			}
		} else {
			$if fontset ? {
				println('font bytes unreadable')
			}
		}
	} else {
		$if fontset ? {
			println('DrawDevice has no gg.Context')
		}
	}
	$if fontset ? {
		println('${ui.fonts}')
	}
}

// define style to be used with drawtext method
pub fn (mut ui UI) add_style(ts TextStyle) {
	mut id := ts.id
	if id == '' {
		if ts.font_name == '' {
			eprintln('Warning: nothing done in add_style since id or font_name missing')
			return
		}
		id = ts.font_name
	}
	ui.text_styles[id] = TextStyle{
		id: id
		font_name: ts.font_name
		color: ts.color
		size: ts.size
		align: ts.align
		vertical_align: ts.vertical_align
		mono: ts.mono
	}
}

pub fn (mut u UI) update_style(ts TextStyleParams) {
	if ts.id in u.text_styles {
		mut ts_ := &(u.text_styles[ts.id])
		unsafe {
			*ts_ = TextStyle{
				...(*ts_)
				size: if ts.size < 0 { ts_.size } else { ts.size }
				font_name: if ts.font_name == ui.no_string { ts_.font_name } else { ts.font_name }
				color: if ts.color == no_color { ts_.color } else { ts.color }
			}
		}
	}
}

pub fn font_path_list() []string {
	mut font_root_path := ''
	$if windows {
		font_root_path = 'C:/windows/fonts'
	}
	$if macos {
		font_root_path = '/System/Library/Fonts/*'
	}
	$if linux {
		font_root_path = '/usr/share/fonts/truetype/*'
	}
	$if android {
		font_root_path = '/system/fonts/*'
	}
	font_paths := os.glob('${font_root_path}/*.ttf') or { panic(err) }
	return font_paths
}

pub struct FontSearcher {
	paths  []string
	lpaths []string
}

pub fn new_font_searcher() FontSearcher {
	paths := font_path_list()
	lpaths := paths.map(it.to_lower())
	return FontSearcher{
		paths: paths
		lpaths: lpaths
	}
}

pub fn (a FontSearcher) search(word string) string {
	wl := word.to_lower()
	for i, fpl in a.lpaths {
		if fpl.contains(wl) {
			fp := a.paths[i]
			return fp
		}
	}
	return font_default()
}

pub fn font_default() string {
	return font.default()
}

// font_path differs depending on os
pub fn (mut w Window) add_font(id string, font_path string) {
	$if windows {
		if os.exists('C:/windows/fonts/${font_path}') {
			w.ui.add_font(id, 'C:/windows/fonts/${font_path}')
			return
		}
	} $else {
		if os.exists(font_path) {
			w.ui.add_font(id, font_path)
			return
		}
	}
	w.ui.add_font(id, font_default())
}

pub fn (mut w Window) init_text_styles() {
	$if screenshot ? {
		w.ui.add_style(id: '_default_')
	} $else {
		w.ui.add_font('system', font_default())
		// init default style
		w.ui.add_style(id: '_default_')
		fs := new_font_searcher()
		$if macos {
			w.add_font('fixed', fs.search('courier new.ttf'))
			w.add_font('fixed_bold', fs.search('courier new bold.ttf'))
			w.add_font('fixed_italic', fs.search('courier new italic.ttf'))
			w.add_font('fixed_bold_italic', fs.search('courier new bold italic.ttf'))
		}
		$if windows {
			w.add_font('fixed', fs.search('cour.ttf'))
			w.add_font('fixed_bold', fs.search('courbd.ttf'))
			w.add_font('fixed_italic', fs.search('couri.ttf'))
			w.add_font('fixed_bold_italic', fs.search('courbi.ttf'))
		}
		$if linux {
			w.add_font('fixed', fs.search('LiberationMono-Regular.ttf'))
			w.add_font('fixed_bold', fs.search('LiberationMono-Bold.ttf'))
			w.add_font('fixed_italic', fs.search('LiberationMono-Italic.ttf'))
			w.add_font('fixed_bold_italic', fs.search('LiberationMono-BoldItalic.ttf'))
		}
	}
}

pub fn (mut w Window) init_screenshot_text_styles() {
	// init default style
	w.ui.add_style(id: '_default_')
}
