// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct EmptyResizer {
pub mut:
   useless int
}

pub fn empty_resizer() &IResizer {
	mut er := &EmptyResizer{}
	return er
}

/*Resizer Interface Methods*/
fn (l &ui.EmptyResizer) resize(widgets []IWidgeter){
}