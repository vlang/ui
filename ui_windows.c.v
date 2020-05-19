// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui
#flag -L @VROOT/windows_shcore/x64
#flag -l shcore

#define ui__setprocessdpiwareness SetProcessDpiAwareness

/* PROCESS_DPI_AWARENESS constants */
const (
	PDpiA = '> Process Dpi Awareness:'
	Process_DPI_Unaware = 0
	Process_System_DPI_Aware = 1
	Process_Per_Monitor_DPI_Aware = 2
)

/* pub is needed for msvc compiler compatibility */
pub fn setprocessdpiwareness(process_dpi_awareness int) voidptr

fn C.MessageBox(h voidptr, text charptr, caption charptr, kind u32) int

pub fn message_box(s string) {
	title := ''
	C.MessageBox(0, s.to_wide(), title.to_wide(), C.MB_OK)
}


/*
	SetProcessDpiAwareness function of Microsoft shcore.dll tested withcompilers:
	- gcc.exe (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0
	- Microsoft MSVC cl.exe C/C++ version 19.25.28614 for x64
*/
pub fn set_process_dpi_awareness(awareness int) {
	match awareness {
		0 { println( PDpiA + if setprocessdpiwareness( Process_DPI_Unaware) == 0  { ' Process_DPI_Unaware' } else { ' 0 change failed' }) }
		1 { println( PDpiA + if setprocessdpiwareness( Process_System_DPI_Aware) == 0  { ' Process_System_DPI_Aware' } else { ' 1 change failed'}) }
		2 { println( PDpiA + if setprocessdpiwareness( Process_Per_Monitor_DPI_Aware) == 0  { ' Process_Per_Monitor_DPI_Aware' } else { ' 2 change failed'}) }
		else { println( PDpiA  + ' no change') }
		}
	println('')
}
