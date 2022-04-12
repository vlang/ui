module ui

import gx

// define style outside Widget definition
// all styles would be collected inside one map attached to ui

pub const (
	no_style = '_no_style_'
)

pub struct Styles {
pub mut:
	btn map[string]ButtonFullStyle
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
	gui.styles.btn[''] = ButtonFullStyle{
		radius: .3
		border_color: button_border_color
		bg_color: gx.white
		bg_color_pressed: gx.rgb(119, 119, 119)
		bg_color_hover: gx.rgb(219, 219, 219)
	}
}

// Button

pub struct ButtonStyle {
pub mut:
	radius           f32
	border_color     gx.Color
	bg_color         gx.Color
	bg_color_pressed gx.Color
	bg_color_hover   gx.Color
}

pub struct ButtonFullStyle {
	ButtonStyle // text_style TextStyle
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
	border_color     gx.Color
	bg_color         gx.Color
	bg_color_pressed gx.Color
	bg_color_hover   gx.Color
	// text_style TextStyle
	text_font_name      string
	text_color          gx.Color = no_color
	text_size           int      = -1
	text_align          TextHorizontalAlign = .@none
	text_vertical_align TextVerticalAlign   = .@none
}

pub fn (mut b Button) update_style(p ButtonStyleParams) {
	// println("update_style <$p.style>")
	if p.style != ui.no_style && p.style in b.ui.styles.btn {
		bs := b.ui.styles.btn[p.style]
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
	}

	// radius: p.radius
	// 		border_color: p.border_color.color()
	// 		bg_color: p.bg_color.color()
	// 		bg_color_pressed: p.bg_color_pressed.color()
	// 		bg_color_hover: p.bg_color_hover.color()
	// 		text_style: TextStyle{
	// 			font_name: p.text_font_name
	// 			color: p.text_color
	// 			size: p.text_size
	// 			align: p.text_align
	// 			vertical_align: p.text_vertical_align
	// 			mono: p.text_mono
	// 		}
	// 	}
	// }
	// b.radius = bs.radius
	// b.border_color = bs.border_color
}
