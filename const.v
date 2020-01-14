// v ui public consts
module ui

import (
  gx
)

public const (
  font_dir = []string{
    r'c:\windows\fonts\arial.ttf',
    '/usr/share/font/dejavu/dajaVusans.tff',
    '/usr/share/fonts/truetype/arial.ttf',
    '/usr/share/fonts/truetype/msttcorefonts/Arial.ttf',
		'/usr/share/fonts/truetype/ubuntu-font-family/Ubuntu-R.ttf',
		'/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
		'/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
		'/usr/share/fonts/truetype/freefont/FreeSans.ttf',
		'/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    '/System/Library/Fonts/SFNSText.ttf'
  }
  
  // error massages
  img_notfound = 'Image file not found.'
  font_notfound = 'System font file not found.'
  glfw_notinstalled = 'glfw not installed.'
  freetype_notinstalled = 'freetype is not installed.'
  
  // default size
  default_font_size = 13
  default_height = 20
  
  button_bg_color = gx.rgb(28, 28, 28)
	button_border_color = gx.rgb(200, 200, 200)
	btn_text_cfg = gx.TextCfg{
	
	button_horizontal_padding = 26
  
  check_mark_size = 14
	cb_border_color = gx.rgb(76, 145, 244)
	cb_image = u32(0)
    
  progress_bar_color = gx.rgb(87, 153, 245)
	progress_bar_border_color = gx.rgb(76, 133, 213)
	progress_bar_background_color = gx.rgb(219, 219, 219)
	progress_bar_background_border_color = gx.rgb(191, 191, 191)
    
  placeholder_cfg = gx.TextCfg{
		color: gx.gray
		size: freetype.default_font_size
		align: gx.ALIGN_LEFT
	}
	default_window_color = gx.rgb(236, 236, 236)
	text_border_color = gx.rgb(177, 177, 177)
	text_inner_border_color = gx.rgb(240, 240, 240)
	textbox_padding = 5
  
)
