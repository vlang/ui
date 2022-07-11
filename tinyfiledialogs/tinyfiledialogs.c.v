module tinyfiledialogs

#include "@VMODROOT/tinyfiledialogs/tinyfiledialogs.h"
#flag @VMODROOT/tinyfiledialogs/tinyfiledialogs.c
#flag windows -lole32
#flag windows -lcomdlg32

fn C.tinyfd_messageBox(a &char, b &char, c &char, d &char, e int) int

fn C.tinyfd_inputBox(a &char, b &char, c &char) &char

fn C.tinyfd_openFileDialog(a &char, b &char, c &char, d &char, e &char, f &char) &char

fn C.tinyfd_saveFileDialog(a &char, b &char, c &char, d &char, e &char) &char

fn C.tinyfd_selectFolderDialog(a &char, b &char) &char

fn C.tinyfd_colorChooser(a &char, b &char, c &char, d &char) &char

fn C.tinyfd_notifyPopup(a &char, b &char, c &char)

fn C.tinyfd_beep()
