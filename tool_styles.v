module ui

import gx

// define style outside Widget definition
// all styles would be collected inside one map attached to ui

pub const (
	no_style = '_no_style_'
	no_color = gx.Color{0, 0, 0, 0}
)

pub struct Styles {
pub mut:
	btn map[string]ButtonStyle
}

// load styles

pub fn (mut gui UI) load_styles() {
	gui.load_default_style()
	gui.load_red_style()
	gui.load_blue_style()
}

// init at least default styles
pub fn (mut gui UI) load_default_style() {
	// "" means default
	gui.styles.btn['default'] = ButtonStyle{
		radius: .3
		border_color: button_border_color
		bg_color: gx.white
		bg_color_pressed: gx.rgb(119, 119, 119)
		bg_color_hover: gx.rgb(219, 219, 219)
	}
}

// Window

pub struct WindowStyle {
pub mut:
	bg_color gx.Color
}

// Button

pub struct ButtonShapeStyle {
pub mut:
	radius           f32
	border_color     gx.Color
	bg_color         gx.Color
	bg_color_pressed gx.Color
	bg_color_hover   gx.Color
}

pub struct ButtonStyle {
	ButtonShapeStyle // text_style TextStyle
	text_font_name      string = 'system'
	text_color          gx.Color
	text_size           int = 16
	text_align          TextHorizontalAlign = .center
	text_vertical_align TextVerticalAlign   = .middle
}

[params]
pub struct ButtonStyleParams {
	style            string = ui.no_style
	radius           f32
	border_color     gx.Color = ui.no_color
	bg_color         gx.Color = ui.no_color
	bg_color_pressed gx.Color = ui.no_color
	bg_color_hover   gx.Color = ui.no_color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = ui.no_color
	text_size           f64
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn (mut b Button) update_style(p ButtonStyleParams) {
	// println("update_style <$p.style>")
	style := if p.style == '' { 'default' } else { p.style }
	if style != ui.no_style && style in b.ui.styles.btn {
		bs := b.ui.styles.btn[style]
		b.theme_style = p.style
		b.style.radius = bs.radius
		b.style.border_color = bs.border_color
		b.style.bg_color = bs.bg_color
		b.style.bg_color_pressed = bs.bg_color_pressed
		b.style.bg_color_hover = bs.bg_color_hover
		mut dtw := DrawTextWidget(b)
		dtw.update_style(
			font_name: bs.text_font_name
			color: bs.text_color
			size: bs.text_size
			align: bs.text_align
			vertical_align: bs.text_vertical_align
		)
	} else {
		if p.radius > 0 {
			b.style.radius = p.radius
		}
		if p.border_color != ui.no_color {
			b.style.border_color = p.border_color
		}
		if p.bg_color != ui.no_color {
			b.style.bg_color = p.bg_color
		}
		if p.bg_color_pressed != ui.no_color {
			b.style.bg_color_pressed = p.bg_color_pressed
		}
		if p.bg_color_hover != ui.no_color {
			b.style.bg_color_hover = p.bg_color_hover
		}
		mut dtw := DrawTextWidget(b)
		if p.text_size > 0 {
			dtw.update_text_size(p.text_size)
		}
		mut ts, mut ok := TextStyleParams{}, false
		if p.text_font_name != '' {
			ok = true
			ts.font_name = p.text_font_name
		}
		if p.text_color != ui.no_color {
			ok = true
			ts.color = p.text_color
		}
		if p.text_align != .@none {
			ok = true
			ts.align = p.text_align
		}
		if p.text_vertical_align != .@none {
			ok = true
			ts.vertical_align = p.text_vertical_align
		}
		if ok {
			dtw.update_style(ts)
		}
	}
}
