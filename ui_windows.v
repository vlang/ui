// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub fn message_box(s string) {
	title := ''
     C.MessageBox(0, s.str, title.str, C.MB_OK)
}

