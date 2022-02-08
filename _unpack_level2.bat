@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist level2 rmdir /q /s level2
md level2

bin\windows\imgextractor level1\system.PARTITION level2\system
bin\windows\imgextractor level1\vendor.PARTITION level2\vendor
bin\windows\imgextractor level1\product.PARTITION level2\product
bin\windows\imgextractor level1\odm.PARTITION level2\odm

del level1\*.raw.img

echo Done.
pause
