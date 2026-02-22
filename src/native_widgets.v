// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

// NativeWidget holds an opaque handle to a platform-native widget.
// On macOS this is an NSView*, on Windows an HWND, on other platforms it is nil.
pub struct NativeWidget {
mut:
	handle voidptr
}

// NativeWidgets manages creation, positioning and lifecycle of platform-native
// controls. When `Window` is created with `native_widgets: true`, every widget
// that has a native counterpart will create a platform control and delegate
// drawing/events to the OS instead of using the custom gg-based rendering.
pub struct NativeWidgets {
pub mut:
	// Parent native window handle (NSWindow*/HWND)
	parent_handle voidptr
	enabled       bool
}

// is_enabled returns whether native widgets mode is active.
pub fn (nw &NativeWidgets) is_enabled() bool {
	return nw.enabled
}
