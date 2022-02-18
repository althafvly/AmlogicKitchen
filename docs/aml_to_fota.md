# Working with aml image to flashable zip creation
--------------------------------------------------

Instructions:

Note: run `bat` or `sh` depending on HOST OS

1) To unpack the firmware, take the UBT Image (.img) file and put it in the in folder.
If the name is confusing, rename it to something simple, like S905X.img

2) run _unpack_level1

3) to create full OTA recovery flashable zip, run _pack_level1_fota

4) take packed zip file from out
