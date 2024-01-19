// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

fn C.MessageBox(h voidptr, text &u16, caption &u16, kind u32) int

pub fn message_box(s string) {
	title := ''
	C.MessageBox(0, s.to_wide(), title.to_wide(), C.MB_OK)
}
