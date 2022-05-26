<p align="left">
  <img src="docs/logo.png" width="350" >
</p>

# Kitchen for working with Amlogic firmware (WINDOWS/LINUX only).
Used for unpacking/packing amlogic images.

Supported features:
- Unpack/repack Amlogic images.
- Unpack/repack partitions (system,product,system_ext,oem and odm).
- Create flashable zip from amlogic image.
- Unpack/repack recovery,boot,logo and dtb.
- Create aml image from supported flashable zips.
- Support for super image unpack/repack.
- Dump os from device through mask mode.

<b>NOTE:</b>
- Ignore some errors with dtb (some conditions are missing), decompiling/compiling dtb should work fine.
- This tool is tested only in some firmwares and devices.
- Theres no guarantee that packed flashable zips or amlogic images will flash successfully.
- This tool is meant to run on windows (10 and 11) or linux (tested on Ubuntu 20) machines only. Even if it's working in any other platform, we can't guarantee full functionality. (Most of the binaries are compiled for linux x86_64 and windows 64bit - using gnuwin64 and cygwin)
  

# Disclaimer:

- <b>The user takes sole responsibility for any damage that might arise due to use of this tool. <br/>
- This includes physical damage (to device), injury, data loss, and also legal matters. <br/>
- This project was made as a learning initiative and the developer or organization cannot be held liable in any way for the use of it.</b>

[Docs](docs)<br/>
[Credits](docs/credits.md)<br/>
[Report issue](https://github.com/xKern/AmlogicKitchen/issues/new)
