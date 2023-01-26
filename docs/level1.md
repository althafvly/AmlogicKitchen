# Working with the first level of Amlogic/Rockchip firmware

---

Instructions:

Note: run `bat` or `sh` depending on HOST OS

1. To unpack the firmware, take the amlogic/rockchip flash image (.img) file and put it in the in folder.
   If the name is confusing, rename it to something simple, like S905X.img/RK2550.img

2. run unpack/rkunpack and select 1

3. In the level1 folder, we can replace/edit the files:

- image.cfg - config file to compile amlogic firmware
- aml_sdc_burn.UBOOT - bootloader
- DDR.USB - bootloader
- boot.PARTITION - kernel (boot_a for some A/B firmwares)
- \_aml_dtb.PARTITION - kernel settings file
- recovery.PARTITION - recovery (some A/B devices doesn't have recovery partition, its embedded in boot)
- logo.PARTITION - logo (sometimes depends on the loader).
- oem.PARTITION -
- odm.PARTITION -
- product.PARTITION -
- system.PARTITION -
- system_ext.PARTITION -
- vendor.PARTITION - these 6 partitions contain system files. (partitions differ per firmwares/android versions)
- super.PARTITION - (mainly for a/b device) - contains 4 or more system partitions inside

4. run pack/rkpack, select 1 and in out folder we can take the finished img file or to create full OTA, run pack_level1_fota

note: A/B devices will be having partitions like '\_a.PARTITION' or 'b.PARTITION' in the filename
