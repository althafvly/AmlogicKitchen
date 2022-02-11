@echo off

cls

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
    )
)

del level1\*.raw.img

echo Done.
pause
