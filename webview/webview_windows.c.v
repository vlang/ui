module webview

// WebView2.h includes objidl.h, but _too late_.
// We fix it by including objidl.h earlier than including WebView2.h
#include <objidl.h>
 
// WinRT headers. EventToken.h lies here.
#flag -I /Program Files (x86)/Windows Kits/10/Include/10.0.19041.0/winrt
#include <EventToken.h>

#flag Version.lib Advapi32.lib Shell32.lib

#flag @VMODROOT/webview/WebView2LoaderStatic.lib
#flag @VMODROOT/webview/stbi.lib
#include "@VMODROOT/webview/webview_windows.c"

fn C.new_windows_web_view(url &byte, title &byte) voidptr

fn C.windows_webview_close()
