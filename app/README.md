![](https://github.com/deepnight/ldtk/blob/master/app/assets/appIcon.png)

**Level Designer Toolkit** (*LDtk*) is a **modern**, **efficient** and **open-source** 2D level editor with a strong focus on user-friendliness.

This repository aims to make LDtk work as a package that can be invoked from an electron app.


Links: [Official website](https://ldtk.io/) | [Haxe API (on GitHub)](https://github.com/deepnight/ldtk-haxe-api)

# Building from source

## Requirements

 - **[Haxe compiler](https://haxe.org)**: you need an up-to-date and working Haxe install  to build LDtk.
 - **[NPM](https://nodejs.org/en/download/)**: this package manager is used for various install and packaging scripts. It is packaged with NodeJS.

## Installing required stuff

 - Open a command line **in the `ldtk` root dir**,
 - Install required Haxe libs:
 ```
 haxe setup.hxml
 ```
 - Install Electron locally and other dependencies through NPM (**IMPORTANT**: you need to be in the `app` dir):
 ```
 cd app
 npm i
 ```

## Compiling *master* branch

First, from the root of the repo, build the electron **Main**:

```
haxe main.debug.hxml
```

This should create a `app/assets/main.js` file.

Then, build the electron **Renderer**:

```
haxe renderer.debug.hxml
```

This should create `app/assets/js/renderer.js`.

## Running

From your electron app, use the following code to invoke LDtk:

```
const ldtk = require('@nanite-factory-games/ldtk');

let ldtkWindow = new ldtk.ElectronMain();
ldtkWindow.main(null);
```

We still need to add a way to pass a specific file to open and will customize what settings can
be set.

# Contributing

You can read the general Pull Request guidelines here:
https://github.com/deepnight/ldtk/wiki#pull-request-guidelines

# Related tools & licences

 - Tileset images: see [README](app/extraFiles/samples/README.md) in samples
 - Haxe: https://haxe.org/
 - Heaps.io: https://heaps.io/
 - Electron: https://www.electronjs.org/
 - JQuery: https://jquery.com
 - MarkedJS: https://github.com/markedjs/marked
 - SVG icons from https://material.io
 - Default palette: "*Endesga32*" by Endesga (https://lospec.com/palette-list/endesga-32)
 - Default color blind palette: "*Colorblind 16*" by FilipWorks (https://github.com/filipworksdev/colorblind-palette-16)
