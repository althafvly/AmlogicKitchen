@echo off
setlocal EnableDelayedExpansion

cls

if exist level2 goto pass
echo Unpack level 2 first
pause
exit

:pass

if exist level2\system\ (
set /p system_size=<"level2\system_size"
bin\windows\make_ext4fs -s -J -L system -T -1 -S level2\system_file_contexts -C level2\system_fs_config -l !system_size! -a system level1\system.PARTITION level2\system\
)

if exist level2\system_ext\ (
set /p system_ext_size=<"level2\system_ext_size"
bin\windows\make_ext4fs -s -J -L system_ext -T -1 -S level2\system_ext_file_contexts -C level2\system_ext_fs_config -l !system_ext_size! -a system_ext level1\system_ext.PARTITION level2\system_ext\
)

if exist level2\vendor\ (
set /p vendor_size=<"level2\vendor_size"
bin\windows\make_ext4fs -s -J -L vendor -T -1 -S level2\vendor_file_contexts -C level2\vendor_fs_config -l !vendor_size! -a vendor level1\vendor.PARTITION level2\vendor\
)

if exist level2\product\ (
set /p product_size=<"level2\product_size"
bin\windows\make_ext4fs -s -J -L product -T -1 -S level2\product_file_contexts -C level2\product_fs_config -l !product_size! -a product level1\product.PARTITION level2\product\
)

if exist level2\odm\ (
set /p odm_size=<"level2\odm_size"
bin\windows\make_ext4fs -s -J -L odm -T -1 -S level2\odm_file_contexts -C level2\odm_fs_config -l !odm_size! -a odm level1\odm.PARTITION level2\odm\
)

if exist level2\oem\ (
set /p oem_size=<"level2\oem_size"
bin\windows\make_ext4fs -s -J -L oem -T -1 -S level2\oem_file_contexts -C level2\oem_fs_config -l !oem_size! -a oem level1\oem.PARTITION level2\oem\
)

echo Done.
pause
exit

:size
set SIZE=%~z1
goto :eof
