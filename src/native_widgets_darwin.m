// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

// ---- Button Action Target Helper ----

typedef void (*VUIButtonCallback)(void* v_button);

@interface VUIButtonTarget : NSObject
@property (assign) VUIButtonCallback callback;
@property (assign) void* v_button;
- (void)buttonClicked:(id)sender;
@end

@implementation VUIButtonTarget
- (void)buttonClicked:(id)sender {
	if (self.callback) {
		self.callback(self.v_button);
	}
}
@end

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

void vui_native_button_set_callback(void* handle, VUIButtonCallback callback, void* v_button) {
	NSButton* btn = (__bridge NSButton*)handle;
	VUIButtonTarget* target = [[VUIButtonTarget alloc] init];
	target.callback = callback;
	target.v_button = v_button;
	objc_setAssociatedObject(btn, "vui_target", target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[btn setTarget:target];
	[btn setAction:@selector(buttonClicked:)];
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
	// Only update placeholder (non-interactive). Text is owned by the native widget.
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
	// Do NOT set state — it is owned by the native widget.
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
	// Do NOT set selection — it is owned by the native widget.
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

// ---- Slider (NSSlider) ----

void* vui_native_create_slider(void* parent, int x, int y, int w, int h,
                                bool horizontal, double min, double max, double val) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSSlider* slider = [[NSSlider alloc] initWithFrame:frame];
	[slider setMinValue:min];
	[slider setMaxValue:max];
	[slider setDoubleValue:val];
	if (!horizontal) {
		// NSSlider is horizontal by default; for vertical, swap w/h and set vertical flag
		[slider setVertical:YES];
	}
	[slider setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:slider];
	return (__bridge_retained void*)slider;
}

void vui_native_update_slider(void* handle, int x, int y, int w, int h, double val) {
	NSSlider* slider = (__bridge NSSlider*)handle;
	NSView* parentView = [slider superview];
	if (parentView) {
		slider.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	// Do NOT set value — it is owned by the native widget.
	[slider setNeedsDisplay:YES];
}

double vui_native_slider_get_value(void* handle) {
	NSSlider* slider = (__bridge NSSlider*)handle;
	return [slider doubleValue];
}

// ---- Dropdown (NSPopUpButton) ----

void* vui_native_create_dropdown(void* parent, int x, int y, int w, int h,
                                  const char** items, int count, int selected) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSPopUpButton* popup = [[NSPopUpButton alloc] initWithFrame:frame pullsDown:NO];
	for (int i = 0; i < count; i++) {
		[popup addItemWithTitle:[NSString stringWithUTF8String:items[i] ? items[i] : ""]];
	}
	if (selected >= 0 && selected < count) {
		[popup selectItemAtIndex:selected];
	}
	[popup setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:popup];
	return (__bridge_retained void*)popup;
}

void vui_native_update_dropdown(void* handle, int x, int y, int w, int h, int selected) {
	NSPopUpButton* popup = (__bridge NSPopUpButton*)handle;
	NSView* parentView = [popup superview];
	if (parentView) {
		popup.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	// Do NOT set selection — it is owned by the native widget.
	[popup setNeedsDisplay:YES];
}

int vui_native_dropdown_get_selected(void* handle) {
	NSPopUpButton* popup = (__bridge NSPopUpButton*)handle;
	return (int)[popup indexOfSelectedItem];
}

// ---- ListBox (NSScrollView containing NSTableView) ----
// Simplified: use an NSScrollView with stacked NSTextFields for list items

void* vui_native_create_listbox(void* parent, int x, int y, int w, int h,
                                 const char** items, int count, int selected) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);

	NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:frame];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setBorderType:NSBezelBorder];
	[scrollView setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];

	int item_height = 20;
	NSView* docView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, w, count * item_height)];

	for (int i = 0; i < count; i++) {
		NSRect itemFrame = NSMakeRect(0, (count - 1 - i) * item_height, w - 15, item_height);
		NSTextField* lbl = [[NSTextField alloc] initWithFrame:itemFrame];
		[lbl setStringValue:[NSString stringWithUTF8String:items[i] ? items[i] : ""]];
		[lbl setEditable:NO];
		[lbl setSelectable:NO];
		[lbl setBordered:NO];
		if (i == selected) {
			[lbl setBackgroundColor:[NSColor selectedTextBackgroundColor]];
		} else {
			[lbl setBackgroundColor:[NSColor clearColor]];
		}
		[lbl setTag:i];
		[docView addSubview:lbl];
	}

	[scrollView setDocumentView:docView];
	[parentView addSubview:scrollView];
	return (__bridge_retained void*)scrollView;
}

void vui_native_update_listbox(void* handle, int x, int y, int w, int h, int selected) {
	NSScrollView* scrollView = (__bridge NSScrollView*)handle;
	NSView* parentView = [scrollView superview];
	if (parentView) {
		scrollView.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	// Do NOT set selection — it is owned by the native widget.
	[scrollView setNeedsDisplay:YES];
}

int vui_native_listbox_get_selected(void* handle) {
	NSScrollView* scrollView = (__bridge NSScrollView*)handle;
	NSView* docView = [scrollView documentView];
	for (NSView* subview in [docView subviews]) {
		if ([subview isKindOfClass:[NSTextField class]]) {
			NSTextField* lbl = (NSTextField*)subview;
			if (![[lbl backgroundColor] isEqual:[NSColor clearColor]]) {
				return (int)[lbl tag];
			}
		}
	}
	return -1;
}

// ---- Switch (NSButton with toggle style) ----

void* vui_native_create_switch(void* parent, int x, int y, int w, int h, bool open) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSButton* sw = [[NSButton alloc] initWithFrame:frame];
	[sw setButtonType:NSSwitchButton];
	[sw setTitle:@""];
	[sw setState:open ? NSControlStateValueOn : NSControlStateValueOff];
	[sw setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:sw];
	return (__bridge_retained void*)sw;
}

void vui_native_update_switch(void* handle, int x, int y, int w, int h, bool open) {
	NSButton* sw = (__bridge NSButton*)handle;
	NSView* parentView = [sw superview];
	if (parentView) {
		sw.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	// Do NOT set state — it is owned by the native widget.
	[sw setNeedsDisplay:YES];
}

bool vui_native_switch_is_open(void* handle) {
	NSButton* sw = (__bridge NSButton*)handle;
	return [sw state] == NSControlStateValueOn;
}

// ---- Picture (NSImageView) ----

void* vui_native_create_picture(void* parent, int x, int y, int w, int h, const char* path) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSImageView* iv = [[NSImageView alloc] initWithFrame:frame];
	if (path) {
		NSString* nsPath = [NSString stringWithUTF8String:path];
		NSImage* img = [[NSImage alloc] initWithContentsOfFile:nsPath];
		if (img) {
			[iv setImage:img];
		}
	}
	[iv setImageScaling:NSImageScaleProportionallyUpOrDown];
	[iv setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[parentView addSubview:iv];
	return (__bridge_retained void*)iv;
}

void vui_native_update_picture(void* handle, int x, int y, int w, int h) {
	NSImageView* iv = (__bridge NSImageView*)handle;
	NSView* parentView = [iv superview];
	if (parentView) {
		iv.frame = vui_flipped_rect(parentView, x, y, w, h);
	}
	[iv setNeedsDisplay:YES];
}

// ---- Menu (NSView-based simple menu bar) ----

void* vui_native_create_menu(void* parent, int x, int y, int w, int h,
                              const char** items, int count) {
	NSView* parentView = (__bridge NSView*)parent;
	NSRect frame = vui_flipped_rect(parentView, x, y, w, h);
	NSView* container = [[NSView alloc] initWithFrame:frame];
	[container setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];

	int item_width = (count > 0) ? (w / count) : w;
	for (int i = 0; i < count; i++) {
		NSRect btnFrame = NSMakeRect(i * item_width, 0, item_width, h);
		NSButton* btn = [[NSButton alloc] initWithFrame:btnFrame];
		[btn setTitle:[NSString stringWithUTF8String:items[i] ? items[i] : ""]];
		[btn setBezelStyle:NSBezelStyleRounded];
		[btn setTag:i];
		[container addSubview:btn];
	}

	[parentView addSubview:container];
	return (__bridge_retained void*)container;
}
