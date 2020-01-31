// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import math

pub struct VResizer {
pub mut:
   layout LayoutType  //fill, 
   align Alignment
   wrap bool = true
   margin_left int = 5
   margin_top int = 5
   margin_right int = 5
   margin_bottom int = 5
   spacing int = 5
}

pub struct VResizerConfig {
   layout LayoutType  //fill, 
   align Alignment
   wrap bool
}

pub fn resizer(c VResizerConfig) &VResizer {
	mut er := &VResizer{
		layout: c.layout
		align: c.align
		wrap: c.wrap
	}
	return er
}

/*Resizer Interface Methods*/
fn (vr &ui.VResizer) resize(w,h int, widgets []IWidgeter) {
    if vr.layout == LayoutType.auto {
        return
    }

    if vr.layout == LayoutType.fill {
	    if vr.align == Alignment.vertical {
	        mut start_y := 0
	        mut height := h/widgets.len
	        for widget in widgets {
	        	widget.set_pos(0, start_y)
	        	widget.propose_size(w, height)
	        	start_y = start_y + height
	        }
	    }else{
	        mut start_x := 0
	        mut width := w/widgets.len
	        for widget in widgets {
	        	widget.set_pos(start_x, 0)
	        	widget.propose_size(width, h)
	        	start_x = start_x + width
	        }
	    }
    }else if vr.layout == LayoutType.row {
        if vr.align == Alignment.vertical {
	        mut start_x := vr.margin_left
	        mut start_y := vr.margin_top
	        mut height := h/widgets.len
	        for widget in widgets {
	        	mut pw, ph := widget.get_size()
	        	widget.set_pos(start_x, start_y)
	        	start_y = start_y + ph + vr.spacing
	        }
        }else{
	        mut start_x := vr.margin_left
	        mut start_y := vr.margin_top
	        mut width := w/widgets.len
	        mut max_height := 0
	        for widget in widgets {
				mut pw, ph := widget.get_size()
	            if (start_x + pw + vr.margin_right) > w && vr.wrap {
	                start_x = vr.margin_right
	                start_y = start_y + max_height + vr.spacing
	            }

	        	widget.set_pos(start_x, start_y)
	        	if ph > max_height {
	        		max_height = ph
	        	}
	        	start_x = start_x + pw + vr.spacing
	        }
        }
    }
}