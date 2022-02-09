@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist level2 rmdir /q /s level2
md level2

if exist level1\system.PARTITION (
bin\windows\imgextractor level1\system.PARTITION level2\system
)
if exist level1\system_ext.PARTITION (
bin\windows\imgextractor level1\system_ext.PARTITION level2\system_ext
)
if exist level1\vendor.PARTITION (
bin\windows\imgextractor level1\vendor.PARTITION level2\vendor
)
if exist level1\product.PARTITION (
bin\windows\imgextractor level1\product.PARTITION level2\product
)
if exist level1\odm.PARTITION (
bin\windows\imgextractor level1\odm.PARTITION level2\odm
)
if exist level1\oem.PARTITION (
bin\windows\imgextractor level1\oem.PARTITION level2\oem
)

del level1\*.raw.img

echo Done.
pause
