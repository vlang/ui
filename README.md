# V UI 0.0.4

[![Build Status](https://github.com/vlang/ui/workflows/CI/badge.svg)](https://github.com/vlang/ui/commits/master)
<a href='https://patreon.com/vlang'><img src='https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3Dvlang%26type%3Dpledges' height='20'></a>

[![Twitter handle][]][twitter badge]

<a href='https://github.com/vlang/ui/blob/master/examples/users.v'>
<img src='https://raw.githubusercontent.com/vlang/ui/c2f802a137b5171dade1d5fdc364cd92d34e3ca7/examples/users/screenshot.png' width=712>
</a>


```v
ui.window({
    width: 600
    height: 400
    title: 'V UI Demo'
}, [
    ui.row({
        stretch: true
        margin: {
            top: 10
            left: 10
            right: 10
            bottom: 10
        }
    }, [
        ui.column({
            width: 200
            spacing: 13
        }, [
            ui.textbox({
                max_len: 20
                width: 200
                placeholder: 'First name'
                text: &app.first_name
            }),
            ui.textbox({
                max_len: 50
                width: 200
                placeholder: 'Last name'
                text: &app.last_name
            }),
        ]),
    ]),
])
````

### Installation

```bash
v up
v install ui
```

### Running the examples

```bash
cd examples
v run users.v
v run temperature.v
v run ...
```

**This is pre-alpha software.**

V UI is a cross-platform UI toolkit written in [the V programming language](https://github.com/vlang/v)
for Windows, macOS, Linux, and soon Android, iOS and the web (JS/WASM). V UI
uses native widgets on Windows and macOS, on all other platforms the widgets
are drawn by V UI. Right now only the non-native widgets are available.

This is a very early version of the library, lots of features are missing, lots of things will change.

The API is declarative, and there will be hot reloading, similar to SwiftUI and Flutter.

On Linux, V UI will be a full-featured lightweight alternative to GTK and Qt.

[0.1 roadmap](https://github.com/vlang/ui/issues/31)

Discord: [`#v-ui` channel](https://discord.gg/vlang)

Documentation will be available soon. In the meantime use the examples as the documentation. The framework is very simple and straightforward.

### Dependencies

Binaries built with V UI will have no dependencies.

To develop V UI apps, you need to install [V](https://github.com/vlang/v#installing-v-from-source). This takes a couple of seconds.

On some Linux distros you also need `libXi-dev` and `libXcursor-dev`, and other(Fedora) may need `mesa-libGL-devel`.

### License

V UI is licensed under GPL3. A commercial license will be available.
Open-source projects will have access to the commercial license for free. Every
single feature will be open-sourced right away and available under both
licenses. At some point in the future the library will be relicensed under MIT.

### Contributing

After the first contribution you will be asked to agree to a CLA, declaring that you have the right to, and actually do, grant us the rights to use your contribution.

[twitter handle]: https://img.shields.io/twitter/follow/v_language.svg?style=social&label=Follow
[twitter badge]: https://twitter.com/v_language
