@echo off

setlocal EnableDelayedExpansion

cls

python --version 2>NUL
if errorlevel 1 (
echo Error^: Python not installed
pause
exit
)

if exist out rmdir /q /s level1
md level1

if not exist out md out

if exist tmp rmdir /q /s tmp
md tmp

echo .....................
echo Amlogic Kitchen
echo .....................
echo Files in input dir (*.zip)
if not exist in\*.zip (
  echo Can't find zips
  if not exist in\ (
    mkdir in
  )
  pause
  exit 0
)

SET /A COUNT=0
for %%a in (in\*.zip) do set /a count += 1 && echo !count! - %%~na
echo .....................
set /P projectname=Enter a file name :
echo %projectname%> level1\projectname.txt

if not exist in\%projectname%.zip (
echo Can't find the file
pause
exit 0
)

set /p filename=< level1\projectname.txt

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

if not exist level1\DDR.USB (
    echo "DDR.USB is missing, copy DDR.USB to level1 dir"
    pause
)

if exist level1\DDR.USB (
    echo file="DDR.USB"		main_type="USB"		sub_type="DDR" >> %configname%
)

if not exist level1\UBOOT.USB (
    echo "UBOOT.USB is missing, copy UBOOT.USB to level1 dir"
    pause
)

if exist level1\UBOOT.USB (
    echo file="UBOOT.USB"		main_type="USB"		sub_type="UBOOT" >> %configname%
)

if not exist level1\aml_sdc_burn.UBOOT (
    echo "aml_sdc_burn.UBOOT is missing, copy aml_sdc_burn.UBOOT to level1 dir"
    pause
)

if exist level1\aml_sdc_burn.UBOOT (
    echo file="aml_sdc_burn.UBOOT"		main_type="UBOOT"		sub_type="aml_sdc_burn" >> %configname%
)

if exist level1\aml_sdc_burn.ini (
    echo file="aml_sdc_burn.ini"		main_type="ini"		sub_type="aml_sdc_burn" >> %configname%
)

if not exist level1\meson1.PARTITION (
    echo "meson1.PARTITION is missing, copy meson1.PARTITION to level1 dir"
    pause
)

if exist level1\meson1.PARTITION (
    echo file="meson1.PARTITION"		main_type="dtb"		sub_type="meson1" >> %configname%
)

if not exist level1\platform.conf (
    echo "platform.conf is missing, copy platform.conf to level1 dir"
    pause
)

if exist level1\platform.conf (
    echo file="platform.conf"		main_type="conf"		sub_type="platform" >> %configname%
)

FOR %%A IN (_aml_dtb boot recovery bootloader dtbo logo odm oem product vendor system system_ext vbmeta) DO (
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
