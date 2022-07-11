module tinyfiledialogs

// see corresponding tinyfiledialogs.c to see the owner of this source
// TODO: transform this file in v file since originally it is a c file
// First inspiration comes from github.com/malisipi/mui from @malisipi

fn cstr(the_string string) &char {
	return &char(the_string.str)
}

// dialog_type => "ok", "okcancel", "yesno", "yesnocancel"
// icon_type   => "info", "warning", "error"
// 0 -> cancel/no, 1 -> ok/yes, 2 -> no (yesnocancel)

[params]
pub struct MessageBoxParams {
	title       string
	dialog_type string = 'ok'
	icon_type   string = 'info'
}

pub fn message(text string, p MessageBoxParams) int {
	return C.tinyfd_messageBox(cstr(p.title), cstr(text), cstr(p.dialog_type), cstr(p.icon_type),
		0)
}

// pub fn message(text string, p MessageBoxParams) int {
// 	return C.tinyfd_messageBox(cstr(p.title), cstr(text), cstr(p.dialog_type), cstr(p.icon_type),
// 		0)
// }

pub fn input(title string, text string, default_text string) string {
	temp := unsafe { C.tinyfd_inputBox(cstr(title), cstr(text), cstr(default_text)) }
	if temp != &char(0) {
		return unsafe { temp.vstring() }
	} else {
		return ''
	}
}

pub fn password(title string, text string) string {
	temp := unsafe { C.tinyfd_inputBox(cstr(title), cstr(text), voidptr(0)) }
	if temp != &char(0) {
		return unsafe { temp.vstring() }
	} else {
		return ''
	}
}

pub fn openfile(title string) string {
	temp := unsafe {
		C.tinyfd_openFileDialog(cstr(title), cstr(''), 0, cstr(''), cstr(''), cstr(''))
	}
	if temp != &char(0) {
		return unsafe { temp.vstring() }
	} else {
		return ''
	}
}

pub fn savefile(title string) string {
	temp := unsafe { C.tinyfd_saveFileDialog(cstr(title), cstr(''), 0, cstr(''), cstr('')) }
	if temp != &char(0) {
		return unsafe { temp.vstring() }
	} else {
		return ''
	}
}

pub fn selectfolder(title string) string {
	temp := C.tinyfd_selectFolderDialog(cstr(title), cstr(''))
	if temp != &char(0) {
		return unsafe { temp.vstring() }
	} else {
		return ''
	}
}

// pub fn colorchooser(title string, default_color string) string {
// 	temp := C.tinyfd_colorChooser(cstr(title), cstr(default_color), cstr(''), cstr(''))
// 	if temp != &char(0) {
// 		return unsafe { temp.vstring() }
// 	} else {
// 		return ''
// 	}
// }

// pub fn notifypopup(title string, text string, icon_type string) { // "info", "warning", "error"
// 	C.tinyfd_notifyPopup(cstr(title), cstr(text), cstr(icon_type))
// }

pub fn beep() {
	C.tinyfd_beep()
}

// pub fn message(text string, p MessageBoxParams) int {
// 	return C.tinyfd_messageBox(p.title.str, text.str, p.dialog_type.str, p.icon_type.str,
// 		0)
// }

// pub fn input(title string, text string, default_text string) string {
// 	temp := unsafe { C.tinyfd_inputBox(title.str, text.str, default_text.str) }
// 	if temp != &char(0) {
// 		return unsafe { temp.vstring() }
// 	} else {
// 		return ''
// 	}
// }

// pub fn password(title string, text string) string {
// 	temp := unsafe { C.tinyfd_inputBox(title.str, text.str, voidptr(0)) }
// 	if temp != &char(0) {
// 		return unsafe { temp.vstring() }
// 	} else {
// 		return ''
// 	}
// }

// pub fn openfile(title string) string {
// 	temp := unsafe { C.tinyfd_openFileDialog(title.str, ''.str, 0, ''.str, ''.str, ''.str) }
// 	if temp != &char(0) {
// 		return unsafe { temp.vstring() }
// 	} else {
// 		return ''
// 	}
// }

// pub fn savefile(title string) string {
// 	temp := unsafe { C.tinyfd_saveFileDialog(title.str, ''.str, 0, ''.str, ''.str) }
// 	if temp != &char(0) {
// 		return unsafe { temp.vstring() }
// 	} else {
// 		return ''
// 	}
// }

// pub fn selectfolder(title string) string {
// 	temp := C.tinyfd_selectFolderDialog(title.str, ''.str)
// 	if temp != &char(0) {
// 		return unsafe { temp.vstring() }
// 	} else {
// 		return ''
// 	}
// }

// // pub fn colorchooser(title string, default_color string) string {
// // 	temp := C.tinyfd_colorChooser(title.str, default_color.str, ''.str, ''.str)
// // 	if temp != &char(0) {
// // 		return unsafe { temp.vstring() }
// // 	} else {
// // 		return ''
// // 	}
// // }

// // pub fn notifypopup(title string, text string, icon_type string) { // "info", "warning", "error"
// // 	C.tinyfd_notifyPopup(title.str, text.str, icon_type.str)
// // }

// pub fn beep() {
// 	C.tinyfd_beep()
// }
