@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

if "%JAVA_HOME%" != "" goto pass
echo Install Java first
pause
exit

:pass

if exist out rmdir /q /s out
md out

if exist tmp rmdir /q /s tmp
md tmp

for /R %%f in (in\*.img) do (set filename=%%~nf)

bin\windows\7za x bin\common\update.zip -otmp

FOR %%A IN (boot dtbo logo recovery vbmeta) DO (
    if exist level1\%%A.PARTITION (
        copy level1\%%A.PARTITION tmp\%%A.img
    )
)

if exist level1\ddr.USB (
copy level1\ddr.USB tmp\bootloader.img
)

if exist level1\DDR.USB (
    copy level1\DDR.USB tmp\bootloader.img
)

if exist level1\_aml_dtb.PARTITION (
    copy level1\_aml_dtb.PARTITION tmp\dt.img
)

FOR %%A IN (odm oem product vendor system system_ext) DO (
    if exist level1\%%A.PARTITION (
        copy level1\%%A.PARTITION tmp\%%A.img
        bin\windows\img2sdat tmp\%%A.img -o tmp -v 4 -p %%A
        bin\windows\brotli.exe --in tmp\%%A.new.dat --out tmp\%%A.new.dat.br --quality 6 -w 24
        del tmp\%%A.img tmp\%%A.new.dat
    )
)

bin\windows\7za a out\update_tmp.zip .\tmp\*

echo Signing...
java -jar bin\common\zipsigner.jar out\update_tmp.zip "out\%filename%_fota.zip"

del out\update_tmp.zip
if exist tmp rmdir /q /s tmp

echo Done.
pause
