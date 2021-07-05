#include "WebView2.h"
// Adapted from https://stackoverflow.com/questions/66820213/basic-win32-webview2-example-not-working-in-pure-c

/////////////////
// GLOBAL VARS //
/////////////////
ICoreWebView2Environment *environment;
ICoreWebView2Controller *controller;
ICoreWebView2 *webviewWindow;

ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler environmentCreatedHandler;
ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl environmentCreatedHandlerVtbl;
ICoreWebView2CreateCoreWebView2ControllerCompletedHandler controllerCreatedHandler;
ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl controllerCreatedHandlerVtbl;
ICoreWebView2ExecuteScriptCompletedHandler scriptCompletedHandler;
ICoreWebView2ExecuteScriptCompletedHandlerVtbl scriptCompletedHandlerVtbl;

typedef void(*navCallback)();

typedef struct {
    ICoreWebView2 window;
    ICoreWebView2Controller controller;
    ICoreWebView2Environment enviromnent;
    void* on_navigate;
} WebViewInstance;

WebViewInstance g_WebView;

//////////////////////////
// FORWARD DECLARATIONS //
//////////////////////////
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

/////////////////////////////////
// ENVIRONMENT CREATED HANDLER //
/////////////////////////////////
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
    environment = newEnvironment;
    void *hWnd = sapp_win32_get_hwnd();
    environment->lpVtbl->CreateCoreWebView2Controller(environment, (HWND)hWnd, &controllerCreatedHandler);
    return S_OK;
}

// void on_navigate(navCallback callbackfn)
// {
//     callbackfn();
// }

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
    controller = newController;
    HRESULT hr = controller->lpVtbl->get_CoreWebView2(controller, &webviewWindow);
    if (FAILED(hr))
        OutputDebugStringA("Failed to get corewebview2 window");

    hr = controller->lpVtbl->AddRef(controller);
    if (FAILED(hr))
        OutputDebugStringA("Failed to increment controller refcount");

    RECT bounds = {.left = 100, .top = 100, .right = 1280, .bottom = 720};
    //void* hWnd = sapp_win32_get_hwnd();
    //GetClientRect(hWnd, &bounds);
    hr = controller->lpVtbl->put_Bounds(controller, bounds);
    if (FAILED(hr))
        OutputDebugStringA("Failed to put bounds");

    ICoreWebView2Settings* webviewSettings = malloc(sizeof(ICoreWebView2Settings));
    hr = webviewWindow->lpVtbl->get_Settings(webviewWindow, &webviewSettings);
    if (FAILED(hr))
        OutputDebugStringA("Failed to get settings");

    webviewSettings->lpVtbl->put_IsStatusBarEnabled(webviewSettings, FALSE);

    hr = webviewWindow->lpVtbl->Navigate(webviewWindow, L"https://vlang.io");
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

/////////////////
// ENTRY POINT //
/////////////////
void* new_windows_web_view(char *url, char *title)
{
    CoInitialize(NULL);
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

    // The first step is to call CreateCoreWebView2Environment,
    // which is our only way to enter the WebView2 world.
    HRESULT hr = CreateCoreWebView2Environment(&environmentCreatedHandler);
    if (FAILED(hr))
    {
        OutputDebugStringA("Failed to create corewebview2environment");
    }
}

void windows_webview_close()
{
    controller->lpVtbl->Close(controller);
}

void exec(char* scriptSource)
{
    // ExecuteScript requires a wchar_t string, converting from char
    size_t scriptLength = strlen(scriptSource) + 1;
    wchar_t scriptSourceWide[500];
    int requiredSize = MultiByteToWideChar(CP_UTF8, 0, scriptSource, -1, &scriptSourceWide, 0);
    MultiByteToWideChar(CP_UTF8, 0, scriptSource, -1, &scriptSourceWide, requiredSize);
    HRESULT hr = webviewWindow->lpVtbl->ExecuteScript(webviewWindow, scriptSourceWide, &scriptCompletedHandler);
    if (FAILED(hr))
        OutputDebugStringA("Failed to execute script");
    OutputDebugStringA("Inside exec");
}

