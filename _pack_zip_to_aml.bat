@echo off

cls

>nul 2>nul assoc .py && echo Python installed || echo Python not available && exit /b 0
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

for /R %%f in (in\*.zip) do (set filename=%%~nf)

bin\windows\7za x in\%filename%.zip -otmp

if exist tmp\META-INF\ (
    rmdir /q /s tmp\META-INF
)

if exist tmp\compatibility.zip (
    del tmp\compatibility.zip
)

if exist tmp\file_contexts.bin (
    del tmp\file_contexts.bin
)

if exist tmp\system\ (
    rmdir /q /s tmp\system
)

FOR %%A IN (odm oem product vendor system system_ext) DO (
    if exist tmp\%%A.transfer.list (
        if exist tmp\%%A.new.dat.br (
            bin\windows\brotli.exe --decompress --in tmp\%%A.new.dat.br --out tmp\%%A.new.dat
            del tmp\%%A.new.dat.br
        )
        python bin\common\sdat2img.py tmp\%%A.transfer.list tmp\%%A.new.dat tmp\%%A.img
        del tmp\%%A.new.dat tmp\%%A.transfer.list
        if exist tmp\%%A.patch.dat (
            del tmp\%%A.patch.dat
        )
        bin\windows\img2simg.exe tmp\%%A.img tmp\%%A_simg.img
        copy tmp\%%A_simg.img tmp\%%A.img
        del tmp\%%A_simg.img
    )
)

if exist tmp\dt.img (
    copy tmp\dt.img level1\_aml_dtb.PARTITION
)

FOR %%A IN (boot recovery logo dtbo vbmeta bootloader odm oem product vendor system system_ext) DO (
    if exist tmp\%%A.img (
        move tmp\%%A.img level1\%%A.PARTITION
    )
)

rmdir /q /s tmp

copy bin\common\aml_sdc_burn.ini level1\aml_sdc_burn.ini

set configname=level1\image.cfg

echo [LIST_NORMAL] > %configname%

if exist level1\DDR.USB (
    echo file="DDR.USB"		main_type="USB"		sub_type="DDR" >> %configname%
) else (
    echo file="bootloader.PARTITION"		main_type="USB"		sub_type="DDR" >> %configname%
)

if exist level1\UBOOT.USB (
    echo file="UBOOT.USB"		main_type="USB"		sub_type="UBOOT" >> %configname%
) else (
    echo file="bootloader.PARTITION"		main_type="USB"		sub_type="UBOOT" >> %configname%
)

if exist level1\aml_sdc_burn.UBOOT (
    echo file="aml_sdc_burn.UBOOT"		main_type="UBOOT"		sub_type="aml_sdc_burn" >> %configname%
) else (
    echo file="bootloader.PARTITION"		main_type="UBOOT"		sub_type="aml_sdc_burn" >> %configname%
)

if exist level1\aml_sdc_burn.ini (
    echo file="aml_sdc_burn.ini"		main_type="ini"		sub_type="aml_sdc_burn" >> %configname%
)

if exist level1\_aml_dtb.PARTITION (
    echo file="_aml_dtb.PARTITION"		main_type="dtb"		sub_type="meson1" >> %configname%
    echo file="_aml_dtb.PARTITION"		main_type="PARTITION"		sub_type="_aml_dtb" >> %configname%
)

if exist level1\platform.conf (
    echo file="platform.conf"		main_type="conf"		sub_type="platform" >> %configname%
)

FOR %%A IN (boot recovery bootloader dtbo logo odm oem product vendor system system_ext vbmeta) DO (
    if exist level1\%%A.PARTITION (
        echo file="%%A.PARTITION"		main_type="PARTITION"		sub_type="%%A" >> %configname%
    )
)

echo [LIST_VERIFY] >> %configname%

if exist level1\image.cfg (
    for /R %%f in (in\*.zip) do (set filename=%%~nf)
    bin\windows\AmlImagePack -r level1\image.cfg level1 "out\%filename%.img"
    echo Done.
) else (
    echo Can't find image.cfg
)

echo Done.
pause
