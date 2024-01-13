// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import os
import rand

// Note: sokol currently does not allow proper handling of multiple windows:
// - closing the secondary window, causes closing of the primary one as well.
// - closing the secondary window frequently leads to crashes as well,
// depending on when the closing event is handled, in the secondary thread.
//
// Due to this, for now just implement a fallback to the wide spread program
// gxmessage, followed by xmessage, even though its messages do look a little ugly.
//
// TODO: implement a simple X11 message box, directly with C calls,
// instead of relying on external programs.

// message_box shows a simple message box, containing a single text message, and an OK button
pub fn message_box(s string) {
	// try several programs, in order from more modern to most likely installed but ugly:
	for cmd in ['gxmessage', 'xmessage'] {
		message_box_system(cmd, s) or {
			eprintln('message_box error: ${err}')
			continue
		}
		return
	}
	eprintln('-'.repeat(80))
	eprintln('| neither xmessage or gxmessage were found; please install the `x11-utils` and `gxmessage` packages |')
	eprintln('-'.repeat(80))
	eprintln(s)
	eprintln('-'.repeat(80))
}

fn message_box_system(cmdname string, s string) ! {
	msgcmd := os.find_abs_path_of_executable(cmdname) or {
		return error('${cmdname} was not found')
	}
	sfilepath := os.join_path(os.temp_dir(), '${rand.ulid()}.txt')
	os.write_file(sfilepath, s) or {}
	defer {
		os.rm(sfilepath) or {}
	}
	mut other_options := ['-nearmouse']
	if cmdname == 'gxmessage' {
		other_options << '-title "Message:"'
	}
	cmd := '${os.quoted_path(msgcmd)} ${other_options.join(' ')} -print -file ${os.quoted_path(sfilepath)}'
	os.system(cmd)
}
