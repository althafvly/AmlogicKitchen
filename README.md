# Kitchen for working with Amlogic firmware
Used for unpacking/packing amlogic images

Supported features

- Unpack/repack Amlogic images
- Unpack/repack partitions (system,product,system_ext,oem and odm)
- Create flashable zip from amlogic image
- Unpack/repack recovery,boot,logo and dtb
- Create aml image from supported flashable zips
- Support for super image unpack/repack
- Dump os from device through mask mode

NOTE:
- Ignore some errors with dtb (some conditions are missing). decompiling/compiling dtb should work fine.
- We only tested this tool in certain firmware/device, report if theres any issue

[Docs](docs)

[Credits](docs/credits.md)
