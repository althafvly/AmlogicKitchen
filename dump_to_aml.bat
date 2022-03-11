@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------


setlocal EnableDelayedExpansion

cls

python --version 2>NUL
if errorlevel 1 (
echo Error^: Python not installed
pause
exit
)

if exist dump\super.img (
echo super image isn't supported yet
pause
exit 0
)

echo .....................
echo Amlogic Dump to Image script
echo .....................

if exist out rmdir /q /s level1 level2 level3
md level1 level2\config level3

if not exist out md out

FOR %%A IN (boot recovery logo dtbo vbmeta bootloader odm oem product vendor system system_ext) DO (
    if exist dump\%%A.img (
        copy dump\%%A.img level1\%%A.PARTITION
    )
)

if exist dump\dtb.img (
    copy dump\dtb.img level1\_aml_dtb.PARTITION
)

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

FOR %%A IN (system system_ext vendor product odm oem) DO (
if exist level1\%%A.PARTITION (
    echo Unpacking %%A
    python bin\common\imgextractor.py "level1\%%A.PARTITION" "level2"
    if exist level1\%%A.raw.img (
        del level1\%%A.raw.img
    )
    echo Repacking %%A
    set /p size=<"level2\config\%%A_size.txt"
    if exist level2\config\%%A_file_contexts (
        bin\windows\sed -n "G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P" level2\config\%%A_file_contexts > level2\config\%%A_sorted_file_contexts
        move level2\config\%%A_sorted_file_contexts level2\config\%%A_file_contexts
    )
    bin\windows\make_ext4fs -s -J -L %%A -T -1 -S level2\config\%%A_file_contexts -C level2\config\%%A_fs_config -l !size! -a %%A level1\%%A.PARTITION level2\%%A\
)
)

if exist level3 rmdir /q /s level3
md level3 level3\boot level3\boot_a level3\recovery level3\recovery_a level3\logo level3\devtree

FOR %%A IN (recovery boot recovery_a boot_a) DO (
    if exist level1\%%A.PARTITION (
        copy level1\%%A.PARTITION bin\windows\aik\%%A.img
        call bin\windows\aik\unpackimg.bat bin\windows\aik\%%A.img
        if exist bin\windows\aik\ramdisk\ (
            move bin\windows\aik\ramdisk level3\%%A\
        )
        move bin\windows\aik\split_img level3\%%A\
        del bin\windows\aik\%%A.img
    )
)

if exist level1\logo.PARTITION (
    bin\windows\imgpack -d level1\logo.PARTITION level3\logo
)

:: i dont have no idea to simplify this
if not exist level1\_aml_dtb.PARTITION (
    if exist level3\boot\split_img\boot.img-dtb (
        copy level3\boot\split_img\boot.img-dtb level1\_aml_dtb.PARTITION
    ) else if exist level3\boot_a\split_img\boot_a.img-dtb (
        copy level3\boot_a\split_img\boot_a.img-dtb level1\_aml_dtb.PARTITION
    ) else if exist level3\boot\split_img\boot.img-second (
        copy level3\boot\split_img\boot.img-second level1\_aml_dtb.PARTITION
    ) else if exist level3\boot_a\split_img\boot_a.img-second (
        copy level3\boot_a\split_img\boot_a.img-second level1\_aml_dtb.PARTITION
    ) else if exist level3\recovery\split_img\recovery.img-dtb (
        copy level3\recovery\split_img\recovery.img-dtb level1\_aml_dtb.PARTITION
    ) else if exist level3\recovery_a\split_img\recovery_a.img-dtb (
        copy level3\recovery_a\split_img\recovery_a.img-dtb level1\_aml_dtb.PARTITION
    ) else if exist level3\recovery\split_img\recovery.img-second (
        copy level3\recovery\split_img\recovery.img-second level1\_aml_dtb.PARTITION
    ) else if exist level3\recovery_a\split_img\recovery_a.img-second (
        copy level3\recovery_a\split_img\recovery_a.img-second level1\_aml_dtb.PARTITION
    )
)

bin\windows\dtc -I dtb -O dts -o level3\devtree\single.dts level1\_aml_dtb.PARTITION
bin\windows\dtbSplit level1\_aml_dtb.PARTITION level3\devtree\

for %%x in (level3\devtree\*.dtb) do (
    bin\windows\dtc -I dtb -O dts -o level3\devtree\%%~nx.dts %%x
    del %%x
)

ROBOCOPY level3 level3 /S /MOVE /NFL /NDL /NJH /NJS /nc /ns /np

FOR %%A IN (recovery boot recovery_a boot_a) DO (
    if exist level3\%%A\ (
        call bin\windows\aik\cleanup.bat
        if exist level3\%%A\ramdisk\ (
            move level3\%%A\ramdisk bin\windows\aik\
        )
        move level3\%%A\split_img bin\windows\aik\
        call bin\windows\aik\repackimg.bat
        move bin\windows\aik\image-new.img level1\%%A.PARTITION
        if exist bin\windows\aik\ramdisk\ (
            move bin\windows\aik\ramdisk level3\%%A\
        )
        move bin\windows\aik\split_img level3\%%A\
        call bin\windows\aik\cleanup.bat
    )
)

if exist level3\logo\ (
bin\windows\imgpack -r level3\logo level1\logo.PARTITION
)

set cnt=0
for %%A in (level3\devtree\*.dts) do set /a cnt+=1

if !cnt! gtr 1 (
    for %%x in (level3\devtree\*.dts) do (
        bin\windows\dtc.exe -I dts -O dtb -o level3\devtree\%%~nx.dtb %%x
    )
    bin\windows\dtbTool -p bin\windows\ -v level3\devtree\ -o level1\_aml_dtb.PARTITION
) else (
    bin\windows\dtc -I dts -O dtb -o level1\_aml_dtb.PARTITION level3\devtree\single.dts 
)

echo .....................
echo Amlogic Dump to Image script
echo .....................
set /P projectname=Enter a name for aml package: 
if exist level1\image.cfg (
    bin\windows\AmlImagePack -r level1\image.cfg level1 out\%projectname%.img
    echo Done.
) else (
    echo Can't find image.cfg
)
pause
exit
