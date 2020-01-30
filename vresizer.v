// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct VResizer {
pub mut:
   layout LayoutType  //fill, 
   align Alignment
}

pub struct VResizerConfig {
   layout LayoutType  //fill, 
   align Alignment
}

pub fn resizer(c VResizerConfig) &VResizer {
	mut er := &VResizer{
		layout: c.layout
		align: c.align
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
	        	widget.set_size(w, height)
	        	start_y = start_y + height
	        }
	    }else{
	        mut start_x := 0
	        mut width := w/widgets.len
	        for widget in widgets {
	        	widget.set_pos(start_x, 0)
	        	widget.set_size(width, h)
	        	start_x = start_x + width
	        }
	    }
    }
}