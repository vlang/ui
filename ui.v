module ui

import gx

pub struct UI {
mut:
	gg                   &gg.GG
	ft                   &freetype.FreeType
	window               ui.Window
	show_cursor          bool
	cb_image             u32
	//circle_image         u32
	radio_image          u32
	selected_radio_image u32
	clipboard            &clipboard.Clipboard
}


pub enum Cursor {
	hand
	arrow
	ibeam
}

pub fn draw_text(x, y int, s string, cfg gx.TextCfg) {

}

pub fn draw_text_def(x, y int, s string) {
}
