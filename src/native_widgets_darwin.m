// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.

#import <Cocoa/Cocoa.h>

// ---- Window / Container ----

void* vui_native_get_content_view(void* window) {
	NSWindow* win = (__bridge NSWindow*)window;
	NSView* view = [win contentView];
	return (__bridge void*)view;
}

// ---- Helper: flip y-coordinate (Cocoa uses bottom-left origin) ----

static NSRect vui_flipped_rect(NSView* parent, int x, int y, int w, int h) {
	CGFloat parent_h = parent.bounds.size.height;
	return NSMakeRect(x, parent_h - y - h, w, h);
}

// ---- Button (NSButton) ----

void* vui_native_create_button(void* parent, int x, int y, int w, int h, const char* title) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSButton* btn = [[NSButton alloc] initWithFrame:frame];
	[btn setTitle:[NSString stringWithUTF8String:title ? title : ""]];
	[btn setBezelStyle:NSBezelStyleRounded];
	[btn setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:btn];
	return (__bridge_retained void*)btn;
}

void vui_native_update_button(void* handle, int x, int y, int w, int h, const char* title) {
	NSButton* btn = (__bridge NSButton*)handle;
	NSView* parentView = [btn superview];
	if (parentView) {
		btn.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	[btn setTitle:[NSString stringWithUTF8String:title ? title : ""]];
	[btn setNeedsDisplay:YES];
}

void vui_native_button_set_enabled(void* handle, bool enabled) {
	NSButton* btn = (__bridge NSButton*)handle;
	[btn setEnabled:enabled];
}

void vui_native_remove_view(void* handle) {
	NSView* view = (__bridge_transfer NSView*)handle;
	[view removeFromSuperview];
}

// ---- TextField (NSTextField) ----

void* vui_native_create_textfield(void* parent, int x, int y, int w, int h, const char* placeholder) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSTextField* tf = [[NSTextField alloc] initWithFrame:frame];
	if (placeholder) {
		[[tf cell] setPlaceholderString:[NSString stringWithUTF8String:placeholder]];
	}
	[tf setEditable:YES];
	[tf setSelectable:YES];
	[tf setBordered:YES];
	[tf setBezeled:YES];
	[tf setBezelStyle:NSTextFieldSquareBezel];
	[tf setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:tf];
	return (__bridge_retained void*)tf;
}

void vui_native_update_textfield(void* handle, int x, int y, int w, int h, const char* text, const char* placeholder) {
	NSTextField* tf = (__bridge NSTextField*)handle;
	NSView* parentView = [tf superview];
	if (parentView) {
		tf.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	if (text) {
		[tf setStringValue:[NSString stringWithUTF8String:text]];
	}
	if (placeholder) {
		[[tf cell] setPlaceholderString:[NSString stringWithUTF8String:placeholder]];
	}
	[tf setNeedsDisplay:YES];
}

const char* vui_native_textfield_get_text(void* handle) {
	NSTextField* tf = (__bridge NSTextField*)handle;
	return [[tf stringValue] UTF8String];
}

void vui_native_textfield_set_secure(void* handle, bool secure) {
	// NSSecureTextField cannot be toggled at runtime easily.
	// For now this is a hint — we store the flag but the initial creation determines the type.
	(void)handle;
	(void)secure;
}

// ---- CheckBox (NSButton with NSSwitchButton type) ----

void* vui_native_create_checkbox(void* parent, int x, int y, int w, int h, const char* title, bool checked) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSButton* cb = [[NSButton alloc] initWithFrame:frame];
	[cb setButtonType:NSSwitchButton];
	[cb setTitle:[NSString stringWithUTF8String:title ? title : ""]];
	[cb setState:checked ? NSControlStateValueOn : NSControlStateValueOff];
	[cb setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:cb];
	return (__bridge_retained void*)cb;
}

void vui_native_update_checkbox(void* handle, int x, int y, int w, int h, const char* title, bool checked) {
	NSButton* cb = (__bridge NSButton*)handle;
	NSView* parentView = [cb superview];
	if (parentView) {
		cb.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	[cb setTitle:[NSString stringWithUTF8String:title ? title : ""]];
	[cb setState:checked ? NSControlStateValueOn : NSControlStateValueOff];
	[cb setNeedsDisplay:YES];
}

bool vui_native_checkbox_is_checked(void* handle) {
	NSButton* cb = (__bridge NSButton*)handle;
	return [cb state] == NSControlStateValueOn;
}

// ---- Radio Group (NSView containing NSButton radio buttons) ----

void* vui_native_create_radio_group(void* parent, int x, int y, int w, int h,
                                     const char** values, int count, int selected, const char* title) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSView* container = [[NSView alloc] initWithFrame:frame];
	[container setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];

	int item_height = 20;
	int title_offset = 0;

	// Add title label if provided
	if (title && strlen(title) > 0) {
		NSRect title_frame = NSMakeRect(0, (count) * item_height, w, item_height);
		NSTextField* lbl = [[NSTextField alloc] initWithFrame:title_frame];
		[lbl setStringValue:[NSString stringWithUTF8String:title]];
		[lbl setEditable:NO];
		[lbl setSelectable:NO];
		[lbl setBordered:NO];
		[lbl setBackgroundColor:[NSColor clearColor]];
		NSFont* boldFont = [NSFont boldSystemFontOfSize:12];
		[lbl setFont:boldFont];
		[container addSubview:lbl];
		title_offset = item_height;
	}

	for (int i = 0; i < count; i++) {
		NSRect btn_frame = NSMakeRect(0, (count - 1 - i) * item_height, w, item_height);
		NSButton* radio = [[NSButton alloc] initWithFrame:btn_frame];
		[radio setButtonType:NSRadioButton];
		[radio setTitle:[NSString stringWithUTF8String:values[i] ? values[i] : ""]];
		[radio setState:(i == selected) ? NSControlStateValueOn : NSControlStateValueOff];
		[radio setTag:i];
		[radio setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
		[container addSubview:radio];
	}

	[parentView addSubview:container];
	return (__bridge_retained void*)container;
}

void vui_native_update_radio_group(void* handle, int x, int y, int w, int h, int selected) {
	NSView* container = (__bridge NSView*)handle;
	NSView* parentView = [container superview];
	if (parentView) {
		container.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	for (NSView* subview in [container subviews]) {
		if ([subview isKindOfClass:[NSButton class]]) {
			NSButton* radio = (NSButton*)subview;
			[radio setState:([radio tag] == selected) ? NSControlStateValueOn : NSControlStateValueOff];
		}
	}
	[container setNeedsDisplay:YES];
}

int vui_native_radio_get_selected(void* handle) {
	NSView* container = (__bridge NSView*)handle;
	for (NSView* subview in [container subviews]) {
		if ([subview isKindOfClass:[NSButton class]]) {
			NSButton* radio = (NSButton*)subview;
			if ([radio state] == NSControlStateValueOn) {
				return (int)[radio tag];
			}
		}
	}
	return 0;
}

// ---- ProgressBar (NSProgressIndicator) ----

void* vui_native_create_progressbar(void* parent, int x, int y, int w, int h,
                                     double min, double max, double val) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSProgressIndicator* pi = [[NSProgressIndicator alloc] initWithFrame:frame];
	[pi setStyle:NSProgressIndicatorStyleBar];
	[pi setMinValue:min];
	[pi setMaxValue:max];
	[pi setDoubleValue:val];
	[pi setIndeterminate:NO];
	[pi setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:pi];
	return (__bridge_retained void*)pi;
}

void vui_native_update_progressbar(void* handle, int x, int y, int w, int h, double val) {
	NSProgressIndicator* pi = (__bridge NSProgressIndicator*)handle;
	NSView* parentView = [pi superview];
	if (parentView) {
		pi.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	[pi setDoubleValue:val];
	[pi setNeedsDisplay:YES];
}

// ---- Label (NSTextField, non-editable) ----

void* vui_native_create_label(void* parent, int x, int y, int w, int h, const char* text) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSTextField* lbl = [[NSTextField alloc] initWithFrame:frame];
	[lbl setStringValue:[NSString stringWithUTF8String:text ? text : ""]];
	[lbl setEditable:NO];
	[lbl setSelectable:NO];
	[lbl setBordered:NO];
	[lbl setBackgroundColor:[NSColor clearColor]];
	[lbl setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:lbl];
	return (__bridge_retained void*)lbl;
}

void vui_native_update_label(void* handle, int x, int y, int w, int h, const char* text) {
	NSTextField* lbl = (__bridge NSTextField*)handle;
	NSView* parentView = [lbl superview];
	if (parentView) {
		lbl.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	[lbl setStringValue:[NSString stringWithUTF8String:text ? text : ""]];
	[lbl setNeedsDisplay:YES];
}
