module ui

import gx

// No color is defined when alpha = 0 at least
const no_color = gx.Color{0, 0, 0, 0}

enum ColorType {
	button_normal = 1 // see button.v
	button_pressed
	button_hover
}

struct Color {
	id    int
	color gx.Color
}

type ColorTheme = map[int]gx.Color

type ColorThemeCfg = ColorTheme | string

// create new color theme
pub fn color_theme(items ...Color) ColorTheme {
	mut theme := map[int]gx.Color{}
	for item in items {
		theme[item.id] = item.color
	}
	return theme
}

// register color theme
pub fn (mut w Window) register_color_theme(name string, theme ColorTheme) {
	w.color_themes[name] = theme
}

fn (mut w Window) register_default_color_themes() {
	w.color_themes['classic'] = color_theme(Color{1, gx.white}, Color{2, gx.rgb(119, 119,
		119)}, Color{3, gx.rgb(219, 219, 219)})
	w.color_themes['red'] = color_theme(Color{1, gx.light_red}, Color{2, gx.rgb(119, 0,
		0)}, Color{3, gx.rgb(219, 0, 0)})
	w.color_themes['blue'] = color_theme(Color{1, gx.light_blue}, Color{2, gx.blue}, Color{3, gx.rgb(119,
		119, 219)})
}

pub fn color(theme map[int]gx.Color, id int) gx.Color {
	return theme[id]
}

pub fn set_color(mut theme map[int]gx.Color, id int, color gx.Color) {
	theme[id] = color
}

pub fn update_colors_from(mut theme map[int]gx.Color, theme2 map[int]gx.Color, ids []int) {
	for id in ids {
		theme[id] = theme2[id]
	}
}

interface ColorThemeWidget {
	ui &UI
mut:
	theme_cfg ColorThemeCfg
	theme map[int]gx.Color
}

fn theme(w ColorThemeWidget) map[int]gx.Color {
	mut theme := map[int]gx.Color{}
	theme_cfg := w.theme_cfg
	if theme_cfg is string {
		theme = w.ui.window.color_themes[theme_cfg]
	} else if theme_cfg is ColorTheme {
		theme = theme_cfg
	}
	return theme
}
