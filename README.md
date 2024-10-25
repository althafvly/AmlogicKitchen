<p align="left">
  <img src="logo.png" width="350" >
</p>

<b>Kitchen for working with Amlogic/Rockchip/AllWinner firmware (LINUX only).</b>

- Used for unpacking/packing Amlogic/Rockchip/AllWinner images.

<b>Disclaimer:</b>

     - The user takes sole responsibility for any damage that might arise due to the use of this tool.
     - This includes physical damage (to device), injury, data loss, and also legal matters.
     - This project was made as a learning initiative and the developer or organization cannot
       be held liable in any way for the use of this tool.

<b>Clone the repository:</b>

     git clone --recurse-submodules https://github.com/althafvly/AmlogicKitchen -b master AmlogicKitchen

<b>Supported features (Rockchip):</b>

- Unpack/pack Rockchip images.

<b>Supported features (Amlogic):</b>

- Unpack/pack Amlogic images.
- Create flashable zip from Amlogic image.
- Create Amlogic image from supported flashable zips.
- Dump ROM from device through mask mode.

<b>Common features (Rockchip/Amlogic/AllWinner):</b>

- Unpack/pack partitions (system,product,system_ext,oem and odm).
- Unpack/pack recovery,boot,logo and DTB.
- Support for super image unpack/pack.
- Sign ROM with custom key

<b>NOTE:</b>

- Ignore some errors with DTB (some conditions are missing), decompiling/compiling dtb should work fine.
- This tool is only tested in some firmwares, devices and processors.
- There's no guarantee that packed flashable zip or Amlogic/Rockchip image will flash successfully.
- This tool is only tested Linux (Ubuntu) machines. Even if it works on any other platform,
  there's no can't guarantee for full functionality.
  (Most of the binaries are compiled for Linux x86_64)

# Credits:

---

- Base kitchen (vtx_kitchen) - Vortex
- gnuwin32 and cygwin for linux binary ports
- aml update tool - osmc
- 7-Zip - Igor Pavlov
- ImgExtractor - unix3dgforce, blackeange and xiaoxindada
- AIK - osm0sis
- SuperImage tools - LonelyFool
- Aml dtb, unpack tools - LineageOS
- simg2img - anestisb
- img2sdat, sdat2img - xpirt
- simg2img - A.S.\_id
- ROM_resigner - erfanoabdi
- imgRePacker - RedScorpioXDA

[Report issue](https://github.com/xKern/AmlogicKitchen/issues/new)
