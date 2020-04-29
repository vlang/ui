module ui

#flag -L @VROOT/thirdparty/shcore
#flag -l /x64/shcore
// #flag -l /x86/shcore
#flag -I @VROOT/thirdparty/shcore
#include <ShellScalingApi.h>
#define setprocessdpiawareness SetProcessDpiAwareness

// PROCESS_DPI_AWARENESS constants
const (
	PDpiA = '> Process Dpi Awareness:'
	Process_DPI_Unaware = 0
	Process_System_DPI_Aware = 1
	Process_Per_Monitor_DPI_Aware = 2
)

fn setprocessdpiawareness(process_dpi_awareness int) voidptr

pub fn set_process_default_dpi_awareness_level(awareness int) {
	match awareness {
		0 { println( PDpiA + if setprocessdpiawareness( Process_DPI_Unaware) == 0  { ' Process_DPI_Unaware' } else { ' 0 change failed' }) }
		1 {	println( PDpiA + if setprocessdpiawareness( Process_System_DPI_Aware) == 0  { ' Process_System_DPI_Aware' } else { ' 1 change failed'}) }
		2 {	println( PDpiA + if setprocessdpiawareness( Process_Per_Monitor_DPI_Aware) == 0  { ' Process_Per_Monitor_DPI_Aware' } else { ' 2 change failed'}) }
		else { println( PDpiA  + ' no change') }
		}
	println('')
}