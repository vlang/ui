// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

#include <winbase.h>	
#define WM_SETCURSOR 0x0020
// #define CopyCursor(pcur) ((HCURSOR)CopyIcon((HICON)(pcur)))


fn C.MessageBox(h voidptr, text charptr, caption charptr, kind u32) int

pub fn message_box(s string) {
	title := ''
	C.MessageBox(0, s.to_wide(), title.to_wide(), C.MB_OK)
}


struct CURSORINFO {
     cb_size C.DWORD
     flags C.DWORD
   	 h_cursor C.HCURSOR
     pt_screen_pos C.POINT
} //CURSORINFO, *PCURSORINFO, *LPCURSORINFO;
 struct RECT {
   left C.LONG
   top C.LONG
   right C.LONG
   bottom C.LONG
}// RECT, *PRECT, *NPRECT, *LPRECT;
// fn C.LoadCursor(hInstance C.HINSTANCE,lpCursorName C.LPCSTR) &C.HCURSOR
// fn C.RegisterClassW(class WndClassW) int 
// fn C.SetCursor(h_cursor C.HCURSOR)

// fn C.ClipCursor(&lpRect RECT)bool	//Confines the cursor to a rectangular area on the screen. If a subsequent cursor position (set by the SetCursorPos function or the mouse) lies outside the rectangle, the system automatically adjusts the position to keep the cursor inside the rectangular area.
// fn C.CopyCursor(pcur)	//Copies the specified cursor.
// fn C.CreateCursor() C.HCURSOR	//Creates a cursor having the specified size, bit patterns, and hot spot.
fn C.DestroyCursor(h_cursor C.HCURSOR) bool	//Destroys a cursor and frees any memory the cursor occupied. Do not use this function to destroy a shared cursor.
fn C.GetClipCursor(lp_rect C.LPRECT)	//Retrieves the screen coordinates of the rectangular area to which the cursor is confined.
fn C.GetCursor() C.HCURSOR	//Retrieves a handle to the current cursor.
fn C.GetCursorInfo(pci C.PCURSORINFO) bool	//Retrieves information about the global cursor.
fn C.GetCursorPos(lp_point C.LPPOINT) bool	//Retrieves the cursor's position, in screen coordinates.
fn C.GetPhysicalCursorPos(lp_point C.LPPOINT)bool	//Retrieves the position of the cursor in physical coordinates.
fn C.LoadCursor(h_instance C.HINSTANCE,lp_cursorName C.LPCSTR) &C.HCURSOR	//Loads the specified cursor resource from the executable (.EXE) file associated with an application instance.
fn C.LoadCursorFromFile(lp_file_name C.LPCSTR ) &C.HCURSOR	//Creates a cursor based on data contained in a file.
fn C.SetCursor(h_cursor C.HCURSOR) C.HCURSOR	//Sets the cursor shape.
fn C.SetCursorPos(x int, y int) bool	//Moves the cursor to the specified screen coordinates. If the new coordinates are not within the screen rectangle set by the most recent ClipCursor function call, the system automatically adjusts the coordinates so that the cursor stays within the rectangle.
fn C.SetPhysicalCursorPos(x int, y int) bool	//Sets the position of the cursor in physical coordinates.
fn C.SetSystemCursor(hcur C.HCURSOR, id C.DWORD) bool	//Enables an application to customize the system cursors. It replaces the contents of the system cursor specified by the id parameter with the contents of the cursor specified by the hcur parameter and then destroys hcur.
fn C.ShowCursor(b_show bool) int	//Displays or hides the cursor.

pub fn set_cursor(lpCursorName int) {
	C.SetCursor(C.LoadCursor(C.NULL, lpCursorName))
}

