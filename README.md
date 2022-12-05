<p align="left">
  <img src="docs/logo.png" width="350" >
</p>

<b>Kitchen for working with Amlogic firmware (WINDOWS/LINUX only).</b>
- Used for unpacking/packing amlogic images.

<b>Disclaimer:</b>

     - The user takes sole responsibility for any damage that might arise due to use of this tool.
     - This includes physical damage (to device), injury, data loss, and also legal matters.
     - This project was made as a learning initiative and the developer or organization cannot
       be held liable in any way for the use of this tool.

<b>Pull submodules:</b>

     git submodule update --init --recursive

<b>Supported features (Rockchip):</b>
- Unpack/repack Rockchip images.

<b>Supported features (Amlogic):</b>
- Unpack/repack Amlogic images.
- Create flashable zip from amlogic image.
- Create aml image from supported flashable zips.
- Dump ROM from device through mask mode.

<b>Common features (Rockchip/Amlogic):</b>
- Unpack/repack partitions (system,product,system_ext,oem and odm).
- Unpack/repack recovery,boot,logo and dtb.
- Support for super image unpack/repack.
- Sign ROM with custom key

<b>NOTE:</b>
- Ignore some errors with dtb (some conditions are missing), decompiling/compiling dtb should work fine.
- This tool is only tested in some firmwares, devices and processors.
- There is no guarantee that packed flashable zip or amlogic/rockship image will flash successfully.
- This tool is only tested on windows and linux (Ubuntu) machines. Even if it's works on any other platform, 
  there's no can't guarantee for full functionality.
  (Most of the binaries are compiled for linux x86_64 and windows 64bit - using gnuwin64 and cygwin)

[Docs](docs)<br/>
[Credits](docs/credits.md)<br/>
[Report issue](https://github.com/xKern/AmlogicKitchen/issues/new)
