@echo off

cls

if exist level2 goto pass
echo Unpack level 2 first
pause
exit

:pass

set /p system_size=<"level2\system_size"
bin\make_ext4fs -s -J -L system -T -1 -S level2\system_file_contexts -C level2\system_fs_config -l %system_size% -a system level1\system.PARTITION level2\system\
call :size level1\system.PARTITION
if %SIZE%==0 exit

set /p vendor_size=<"level2\vendor_size"
bin\make_ext4fs -s -J -L vendor -T -1 -S level2\vendor_file_contexts -C level2\vendor_fs_config -l %vendor_size% -a vendor level1\vendor.PARTITION level2\vendor\
call :size level1\vendor.PARTITION
if %SIZE%==0 exit

set /p product_size=<"level2\product_size"
bin\make_ext4fs -s -J -L product -T -1 -S level2\product_file_contexts -C level2\product_fs_config -l %product_size% -a product level1\product.PARTITION level2\product\
call :size level1\product.PARTITION
if %SIZE%==0 exit

set /p odm_size=<"level2\odm_size"
bin\make_ext4fs -s -J -L odm -T -1 -S level2\odm_file_contexts -C level2\odm_fs_config -l %odm_size% -a odm level1\odm.PARTITION level2\odm\
call :size level1\odm.PARTITION
if %SIZE%==0 exit

echo Done.
pause
exit

:size
set SIZE=%~z1
goto :eof
