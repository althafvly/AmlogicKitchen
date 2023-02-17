<p align="left">
  <img src="docs/logo.png" width="350" >
</p>

<b>Kitchen for working with Amlogic firmware (WINDOWS/LINUX only).</b>

- Used for unpacking/packing Amlogic images.

<b>Disclaimer:</b>

     - The user takes sole responsibility for any damage that might arise due to the use of this tool.
     - This includes physical damage (to device), injury, data loss, and also legal matters.
     - This project was made as a learning initiative and the developer or organization cannot
       be held liable in any way for the use of this tool.

<b>Pull submodules:</b>

     git submodule update --init --recursive

<b>Supported features (Rockchip):</b>

- Unpack/pack Rockchip images.

<b>Supported features (Amlogic):</b>

- Unpack/pack Amlogic images.
- Create flashable zip from Amlogic image.
- Create Amlogic image from supported flashable zips.
- Dump ROM from device through mask mode.

<b>Common features (Rockchip/Amlogic):</b>

- Unpack/pack partitions (system,product,system_ext,oem and odm).
- Unpack/pack recovery,boot,logo and DTB.
- Support for super image unpack/pack.
- Sign ROM with custom key

<b>NOTE:</b>

- Some binaries for windows are too old/missing. Always try to use Linux or wsl (Ubuntu) in windows.
- Ignore some errors with DTB (some conditions are missing), decompiling/compiling dtb should work fine.
- This tool is only tested in some firmwares, devices and processors.
- There's no guarantee that packed flashable zip or Amlogic/Rockchip image will flash successfully.
- This tool is only tested on windows and Linux (Ubuntu) machines. Even if it works on any other platform,
  there's no can't guarantee for full functionality.
  (Most of the binaries are compiled for Linux x86_64 and windows 64bit - using gnuwin64 and cygwin)

[Docs](docs)<br/>
[Credits](docs/credits.md)<br/>
[Report issue](https://github.com/xKern/AmlogicKitchen/issues/new)
