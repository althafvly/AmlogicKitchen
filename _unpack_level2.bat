@echo off

cls
setlocal enabledelayedexpansion
if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist level2 rmdir /q /s level2
md level2

FOR %%A IN (odm oem product vendor system system_ext) DO (
    if exist level1\%%A.PARTITION (
        bin\windows\imgextractor level1\%%A.PARTITION level2\%%A
        if exist level1\%%A.raw.img (
            del level1\%%A.raw.img
        )
    )
)

if exist level1\super.PARTITION (
    bin\windows\simg2img level1\super.PARTITION level2\super.img
    bin\windows\super\lpunpack -slot=0 level2\super.img level2\
    del level2\super.img

    FOR %%A IN (system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b) DO (
    if exist level2\%%A.img (
		call :setsize level2\%%A.img
		if !size! GTR 1024 (
			python bin\common\imgextractor.py "level2\%%A.img" "level2"
			del level2\%%A.img
		)
    )
    )
)

:setsize
set size=%~z1
goto :eof

echo Done.
pause
