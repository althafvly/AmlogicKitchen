# Kitchen for working with Amlogic firmware
Used for unpacking/packing amlogic images

Supported features

- Unpack/repack Amlogic images
- Unpack/repack partitions (system,product,system_ext,oem and odm)
- Create flashable zip from amlogic image
- Unpack/repack recovery,boot,logo and dtb

NOTE:
- Ignore some errors with dtb (some conditions are missing). decompiling/compiling dtb should work fine.

TODO:
- Add support for super image unpack/repack
- Create aml image from supported flashable zips
- Dump os from device through adb/flash/mask mode

# Credits: 
----------

- 7-Zip - Igor Pavlov
- ImgExtractor - unix3dgforce, blackeange and xiaoxindada
- AIK - osm0sis
- SuperImage tools - LonelyFool
- Aml dtb, unpack tools - LineageOS
- simg2img - anestisb
- img2sdat - xpirt

# Working with the first level of Amlogic firmware
--------------------------------------------------

Instructions:

Note: run `bat` or `sh` depending on HOST OS

1) To unpack the firmware, take the UBT Image (.img) file and put it in the in folder.
If the name is confusing, rename it to something simple, like S905X.img

2) run _unpack_level1

3) In the level1 folder, we can replace/edit the files:

- image.cfg - config file to compile amlogic firmware
- aml_sdc_burn.UBOOT - bootloader
- DDR.USB - bootloader
- boot.PARTITION - kernel
- _aml_dtb.PARTITION - kernel settings file
- recovery.PARTITION - recovery
- logo.PARTITION - logo (sometimes depends on the loader).
- oem.PARTITION -
- odm.PARTITION -
- product.PARTITION -
- system.PARTITION -
- system_ext.PARTITION -
- vendor.PARTITION - these 6 partitions contain system files. (partitions differ per firmwares/android versions)

4) run _pack_level1 and in out folder we take the finished img file or to create full OTA, run _pack_level1_fota


# Working with the second level of Amlogic firmware
---------------------------------------------------

Instructions:

1) To work with the second level, you must unpack level 1 first

2) run _unpack_level2

3) In the level2 folder, we replace/correct the files in the folders:

- system - section system
- vendor - vendor section
- product - product section
- system_ext - system_ext section
- odm - section odm
- oem - oem section

4) run _pack_level2

5) then to pack level 1 run _pack_level1 or to create full OTA, run _pack_level1_fota


Notes:

- If you are adding new files or folders that require special permissions (by default, new files and folders are assigned permissions 0644 and 0755 when packing) then write these rights in *_fs_config.
- The *_file_contexts files are required for setting SELinux privileges
- And the *_size files set the size of a particular partition.


# Working with the third level of Amlogic firmware
--------------------------------------------------------

Instructions:

1) To work with the third level, you must unpack level 1 first

2) run _unpack_level3

3) In the level3 folder, we replace/correct the files in the folders:

- boot - boot partition (kernel)
- recovery - partition recovery
- logo - logo section
- devtree - device tree section

4) run _pack_level3

5) then pack level 1 to run  _pack_level1.bat or to create full OTA, run _pack_level1_fota.bat
