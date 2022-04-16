module ui

import gx
import toml
import os

// define style outside Widget definition
// all styles would be collected inside one map attached to ui

pub const (
	no_style    = '_no_style_'
	no_color    = gx.Color{0, 0, 0, 0}
	transparent = gx.Color{0, 0, 0, 1}
)

pub struct Style {
pub mut:
	win    WindowStyle
	btn    ButtonStyle
	pgbar  ProgressBarStyle
	cl     CanvasLayoutStyle
	stack  StackStyle
	tb     TextBoxStyle
	lb     ListBoxStyle
	slider SliderStyle
}

pub fn (s Style) to_toml() string {
	mut toml := ''
	toml += '[window]\n'
	toml += s.win.to_toml()
	toml += '\n[button]\n'
	toml += s.btn.to_toml()
	toml += '\n[progressbar]\n'
	toml += s.pgbar.to_toml()
	toml += '\n[slider]\n'
	toml += s.slider.to_toml()
	toml += '\n[canvaslayout]\n'
	toml += s.cl.to_toml()
	toml += '\n[stack]\n'
	toml += s.stack.to_toml()
	return toml
}

pub fn parse_style_toml_file(path string) Style {
	doc := toml.parse_file(path) or { panic(err) }
	mut s := Style{}
	s.win.from_toml(doc.value('window'))
	s.btn.from_toml(doc.value('button'))
	s.pgbar.from_toml(doc.value('progressbar'))
	s.slider.from_toml(doc.value('slider'))
	s.cl.from_toml(doc.value('canvaslayout'))
	s.stack.from_toml(doc.value('stack'))
	return s
}

pub fn (s Style) as_toml_file(path string) {
	text := '# $path generated automatically\n' + s.to_toml()
	os.write_file(path, text) or { panic(err) }
}

pub fn style_toml_file(style_id string) string {
	return os.join_path(settings_styles_dir, 'style_${style_id}.toml')
}

// load styles

pub fn (mut gui UI) load_styles() {
	// ensure some theme styles are predefined
	create_theme_styles()
	for style_id in ['default', 'red', 'blue'] {
		gui.load_style_from_file(style_id)
	}
}

pub fn (mut gui UI) load_style_from_file(style_id string) {
	style := parse_style_toml_file(style_toml_file(style_id))
	// println("$style_id: $style")
	gui.styles[style_id] = style
}

// predefined style

fn create_theme_styles() {
	if !os.exists(settings_styles_dir) {
		os.mkdir_all(settings_styles_dir) or { panic(err) }
	}
	if !os.exists(style_toml_file('default')) {
		create_default_style_file()
	}
	if !os.exists(style_toml_file('red')) {
		create_red_style_file()
	}
	if !os.exists(style_toml_file('blue')) {
		create_blue_style_file()
	}
}

pub fn default_style() Style {
	// "" means default
	return Style{
		// window
		win: WindowStyle{
			bg_color: default_window_color
		}
		// button
		btn: ButtonStyle{
			radius: .3
			border_color: button_border_color
			bg_color: gx.white
			bg_color_pressed: gx.rgb(119, 119, 119)
			bg_color_hover: gx.rgb(219, 219, 219)
		}
		// progressbar
		pgbar: ProgressBarStyle{
			color: gx.rgb(87, 153, 245)
			border_color: gx.rgb(76, 133, 213)
			bg_color: gx.rgb(219, 219, 219)
			bg_border_color: gx.rgb(191, 191, 191)
		}
	}
}

pub fn create_default_style_file() {
	default_style().as_toml_file(style_toml_file('default'))
}

pub fn blue_style() Style {
	return Style{
		// win
		win: WindowStyle{
			bg_color: gx.blue
		}
		// button
		btn: ButtonStyle{
			radius: .3
			border_color: button_border_color
			bg_color: gx.light_blue
			bg_color_pressed: gx.rgb(0, 0, 119)
			bg_color_hover: gx.rgb(0, 0, 219)
		}
		// progressbar
		pgbar: ProgressBarStyle{
			color: gx.rgb(87, 153, 245)
			border_color: gx.rgb(76, 133, 213)
			bg_color: gx.rgb(219, 219, 219)
			bg_border_color: gx.rgb(191, 191, 191)
		}
		// canvas layout
		cl: CanvasLayoutStyle{
			bg_color: ui.transparent // gx.rgb(220, 220, 255)
		}
		// stack
		stack: StackStyle{
			bg_color: ui.transparent // gx.rgb(220, 220, 255)
		}
	}
}

pub fn create_blue_style_file() {
	blue_style().as_toml_file(os.join_path(settings_styles_dir, 'style_blue.toml'))
}

pub fn red_style() Style {
	return Style{
		// win
		win: WindowStyle{
			bg_color: gx.red
		}
		// button
		btn: ButtonStyle{
			radius: .3
			border_color: button_border_color
			bg_color: gx.light_red
			bg_color_pressed: gx.rgb(119, 0, 0)
			bg_color_hover: gx.rgb(219, 0, 0)
			text_color: gx.red
		}
		// progressbar
		pgbar: ProgressBarStyle{
			color: gx.rgb(245, 153, 87)
			border_color: gx.rgb(213, 133, 76)
			bg_color: gx.rgb(219, 219, 219)
			bg_border_color: gx.rgb(191, 191, 191)
		}
		// slider
		slider: SliderStyle{
			thumb_color: gx.rgb(245, 153, 87)
		}
		// canvas layout
		cl: CanvasLayoutStyle{
			bg_color: ui.transparent // gx.rgb(255, 220, 220)
		}
		// stack
		stack: StackStyle{
			bg_color: ui.transparent // gx.rgb(255, 220, 220)
		}
	}
}

pub fn create_red_style_file() {
	red_style().as_toml_file(os.join_path(settings_styles_dir, 'style_red.toml'))
}

// Style with Text

interface DrawTextWidgetStyle {
mut:
	text_font_name string
	text_color gx.Color
	text_size int
	text_align TextHorizontalAlign
	text_vertical_align TextVerticalAlign
}

interface DrawTextWidgetStyleParams {
	text_font_name string
	text_color gx.Color
	text_size f64
	text_align TextHorizontalAlign
	text_vertical_align TextVerticalAlign
}

pub fn (mut dtw DrawTextWidget) update_theme_style(ds DrawTextWidgetStyle) {
	dtw.update_style(
		font_name: ds.text_font_name
		color: ds.text_color
		size: ds.text_size
		align: ds.text_align
		vertical_align: ds.text_vertical_align
	)
}

pub fn (mut dtw DrawTextWidget) update_theme_style_params(ds DrawTextWidgetStyleParams) {
	if ds.text_size > 0 {
		dtw.update_text_size(ds.text_size)
	}
	mut ts, mut ok := TextStyleParams{}, false
	if ds.text_font_name != '' {
		ok = true
		ts.font_name = ds.text_font_name
	}
	if ds.text_color != ui.no_color {
		ok = true
		ts.color = ds.text_color
	}
	if ds.text_align != .@none {
		ok = true
		ts.align = ds.text_align
	}
	if ds.text_vertical_align != .@none {
		ok = true
		ts.vertical_align = ds.text_vertical_align
	}
	if ok {
		dtw.update_style(ts)
	}
}

// parent style

pub fn (l Layout) bg_color() gx.Color {
	mut col := ui.no_color
	if l is Stack {
		col = l.style.bg_color
		if col in [ui.no_color, ui.transparent] {
			return l.parent.bg_color()
		}
	} else if l is CanvasLayout {
		col = l.style.bg_color
		if col in [ui.no_color, ui.transparent] {
			return l.parent.bg_color()
		}
	} else if l is Window {
		col = l.bg_color
	}
	return col
}

// add shortcut
pub fn (mut window Window) add_shortcut_theme() {
	mut sc := ui.Shortcutable(window)
	sc.add_shortcut('ctrl + t', fn (mut w Window) {
		themes := ['default', 'red', 'blue']
		for i, theme in themes {
			if w.theme_style == theme {
				w.theme_style = themes[if i + 1 == themes.len { 0 } else { i + 1 }]
				break
			}
		}
		mut l := Layout(w)
		l.update_theme_style(w.theme_style)
	})
}
