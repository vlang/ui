/*
	Tested compilers :	
	- gcc.exe (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0
	- Microsoft MSVC cl.exe C/C++ version 19.25.28614 for x64
*/

module windows

#flag -L @VROOT/shcore/x64
#flag -l shcore

#define windows__setprocessdpiwareness SetProcessDpiAwareness

/* PROCESS_DPI_AWARENESS constants */
const (
	PDpiA = '> Process Dpi Awareness:'
	Process_DPI_Unaware = 0
	Process_System_DPI_Aware = 1
	Process_Per_Monitor_DPI_Aware = 2
)

/* pub is needed for msvc compiler compatibility */
pub fn setprocessdpiwareness(process_dpi_awareness int) voidptr

pub fn set_process_dpi_awareness(awareness int) {
	match awareness {
		0 { println( PDpiA + if setprocessdpiwareness( Process_DPI_Unaware) == 0  { ' Process_DPI_Unaware' } else { ' 0 change failed' }) }
		1 { println( PDpiA + if setprocessdpiwareness( Process_System_DPI_Aware) == 0  { ' Process_System_DPI_Aware' } else { ' 1 change failed'}) }
		2 { println( PDpiA + if setprocessdpiwareness( Process_Per_Monitor_DPI_Aware) == 0  { ' Process_Per_Monitor_DPI_Aware' } else { ' 2 change failed'}) }
		else { println( PDpiA  + ' no change') }
		}
	println('')
}