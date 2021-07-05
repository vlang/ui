#include "WebView2.h"
// Adapted from https://stackoverflow.com/questions/66820213/basic-win32-webview2-example-not-working-in-pure-c

//////////////////////////
// FORWARD DECLARATIONS //
//////////////////////////
// STRUCTS
typedef struct _webview_instance
{
    ICoreWebView2 *window;
    ICoreWebView2Settings *settings;
    ICoreWebView2Controller *controller;
    ICoreWebView2Environment *environment;
    void *on_navigate;
    wchar_t *url;
    wchar_t *title;
} WebViewInstance;

// PUBLIC API FUNCTIONS

// HELPER FUNCTIONS
void ConfigureWebViewWindow();
void SetupCOMHandlers();

// COM HANDLERS
ULONG __stdcall EnvironmentAddRef(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *);
ULONG __stdcall EnvironmentRelease(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *);
HRESULT __stdcall EnvironmentQueryInterface(
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *,
    REFIID,
    void **);
HRESULT __stdcall EnvironmentInvoke(
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *,
    HRESULT,
    ICoreWebView2Environment *);

ULONG __stdcall ControllerAddRef(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *);
ULONG __stdcall ControllerRelease(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This);
HRESULT __stdcall ControllerQueryInterface(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *,
    REFIID,
    void **);
HRESULT __stdcall ControllerInvoke(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *,
    HRESULT,
    ICoreWebView2Controller *);
HRESULT __stdcall ScriptInvoke(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This,
    HRESULT errorCode,
    ICoreWebView2Controller *newController);
HRESULT __stdcall ScriptQueryInterface(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This,
    REFIID riid,
    void **ppvObject);

/////////////////
// GLOBAL VARS //
/////////////////
BOOL hasCalledCoInitialize = FALSE;
WebViewInstance g_WebView;

ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler environmentCreatedHandler;
ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl environmentCreatedHandlerVtbl;
ICoreWebView2CreateCoreWebView2ControllerCompletedHandler controllerCreatedHandler;
ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl controllerCreatedHandlerVtbl;
ICoreWebView2ExecuteScriptCompletedHandler scriptCompletedHandler;
ICoreWebView2ExecuteScriptCompletedHandlerVtbl scriptCompletedHandlerVtbl;

////////////////
// PUBLIC API //
////////////////
void *new_windows_web_view(wchar_t *url, wchar_t *title)
{
    // To use COM functions at all, you have to call CoInitialize once and only once
    if (!hasCalledCoInitialize)
        CoInitialize(NULL);

    SetupCOMHandlers();

    g_WebView.url = url;
    g_WebView.title = title;

    // The first step is to call CreateCoreWebView2Environment,
    // which is our only way to enter the WebView2 world.
    HRESULT hr = CreateCoreWebView2Environment(&environmentCreatedHandler);
    if (FAILED(hr))
    {
        OutputDebugStringA("Failed to create corewebview2environment");
    }

    return &g_WebView;
}

void windows_webview_close()
{
    g_WebView.controller->lpVtbl->Close(g_WebView.controller);
}

void exec(wchar_t scriptSource)
{
    HRESULT hr = g_WebView.window->lpVtbl->ExecuteScript(g_WebView.window, scriptSource, &scriptCompletedHandler);
    if (FAILED(hr))
        OutputDebugStringA("Failed to execute script");
    OutputDebugStringA("Inside exec");
}

void navigate(wchar_t *url)
{
    g_WebView.window->lpVtbl->Navigate(g_WebView.window, url);
}

//////////////////////
// HELPER FUNCTIONS //
//////////////////////

void SetupCOMHandlers()
{
    // Initialize vtables
    environmentCreatedHandler.lpVtbl = &environmentCreatedHandlerVtbl;
    controllerCreatedHandler.lpVtbl = &controllerCreatedHandlerVtbl;
    scriptCompletedHandler.lpVtbl = &scriptCompletedHandlerVtbl;
    // Set up IUnknown functions
    environmentCreatedHandler.lpVtbl->AddRef = EnvironmentAddRef;
    environmentCreatedHandler.lpVtbl->Release = EnvironmentRelease;
    environmentCreatedHandler.lpVtbl->QueryInterface = EnvironmentQueryInterface;
    environmentCreatedHandler.lpVtbl->Invoke = EnvironmentInvoke;

    controllerCreatedHandler.lpVtbl->AddRef = ControllerAddRef;
    controllerCreatedHandler.lpVtbl->Release = ControllerRelease;
    controllerCreatedHandler.lpVtbl->QueryInterface = ControllerQueryInterface;
    controllerCreatedHandler.lpVtbl->Invoke = ControllerInvoke;

    scriptCompletedHandler.lpVtbl->AddRef = ControllerAddRef;
    scriptCompletedHandler.lpVtbl->Release = ControllerRelease;
    scriptCompletedHandler.lpVtbl->QueryInterface = ScriptQueryInterface;
    scriptCompletedHandler.lpVtbl->Invoke = ScriptInvoke;
}

void ConfigureWebViewWindow()
{
    RECT bounds = {.left = 100, .top = 100, .right = 1280, .bottom = 720};
    //void* hWnd = sapp_win32_get_hwnd();
    //GetClientRect(hWnd, &bounds);
    HRESULT hr = g_WebView.controller->lpVtbl->put_Bounds(g_WebView.controller, bounds);
    if (FAILED(hr))
        OutputDebugStringA("Failed to put bounds");

    ICoreWebView2Settings *webviewSettings = malloc(sizeof(ICoreWebView2Settings));
    hr = g_WebView.window->lpVtbl->get_Settings(g_WebView.window, &webviewSettings);
    if (FAILED(hr))
        OutputDebugStringA("Failed to get settings");

    g_WebView.settings = webviewSettings;

    g_WebView.settings->lpVtbl->put_IsStatusBarEnabled(g_WebView.window, FALSE);
}

//////////////////
// COM HANDLERS //
//////////////////

// ENVIRONMENT CREATED HANDLER
ULONG __stdcall EnvironmentAddRef(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This)
{
    // Not concerned with refcount
    return 1;
}

ULONG __stdcall EnvironmentRelease(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This)
{
    // Not concerned with refcount
    return 1;
}

HRESULT __stdcall EnvironmentQueryInterface(
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This,
    REFIID riid,
    void **ppvObject)
{
    *ppvObject = This;
    EnvironmentAddRef(This);
    return S_OK;
}

HRESULT __stdcall EnvironmentInvoke(
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This,
    HRESULT errorCode,
    ICoreWebView2Environment *newEnvironment)
{
    g_WebView.environment = newEnvironment;
    void *hWnd = sapp_win32_get_hwnd();
    g_WebView.environment->lpVtbl->CreateCoreWebView2Controller(g_WebView.environment, (HWND)hWnd, &controllerCreatedHandler);
    return S_OK;
}

////////////////////////////////
// CONTROLLER CREATED HANDLER //
////////////////////////////////
ULONG __stdcall ControllerAddRef(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This)
{
    // Not concerned with refcount
    return 1;
}

ULONG __stdcall ControllerRelease(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This)
{
    // Not concerned with refcount
    return 1;
}

HRESULT __stdcall ControllerQueryInterface(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This,
    REFIID riid,
    void **ppvObject)
{
    *ppvObject = This;
    ControllerAddRef(This);
    return S_OK;
}

HRESULT __stdcall ControllerInvoke(
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This,
    HRESULT errorCode,
    ICoreWebView2Controller *newController)
{
    g_WebView.controller = newController;

    HRESULT hr = g_WebView.controller->lpVtbl->get_CoreWebView2(g_WebView.controller, &g_WebView.window);
    if (FAILED(hr))
        OutputDebugStringA("Failed to get corewebview2 window");

    // Window won't show if we don't call AddRef
    hr = g_WebView.controller->lpVtbl->AddRef(g_WebView.controller);
    if (FAILED(hr))
        OutputDebugStringA("Failed to increment controller refcount");

    ConfigureWebViewWindow();

    hr = g_WebView.window->lpVtbl->Navigate(g_WebView.window, g_WebView.url);
    if (FAILED(hr))
        OutputDebugStringA("Failed to get corewebview2 window");
    return S_OK;
}

HRESULT __stdcall ScriptQueryInterface()
{
}

HRESULT __stdcall ScriptInvoke()
{
    OutputDebugStringA("Inside invoke");
}