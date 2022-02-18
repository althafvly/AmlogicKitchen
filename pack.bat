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


echo .....................
echo Amlogic Kitchen
echo .....................
set /P level=Select level 1,2 or 3: 
IF %level% == 1 GOTO level1
IF %level% == 2 GOTO level2
IF %level% == 3 GOTO level3
ELSE echo Invalid option
echo Unpack level 1 first
pause
exit

:level1

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist out rmdir /q /s out
md out

set /p filename=< level1\projectname.txt
if exist level1\image.cfg (
    bin\windows\AmlImagePack -r level1\image.cfg level1 "out\%filename%.img"
    echo Done.
) else (
    echo Can't find image.cfg
)

pause
exit

:level2

if exist level2 goto pass2
echo Unpack level 2 first
pause
exit

:pass2

FOR %%A IN (odm oem product vendor system system_ext) DO (
    if exist level2\%%A\ (
        set /p size=<"level2\%%A_size"
        bin\windows\make_ext4fs -s -J -L %%A -T -1 -S level2\%%A_file_contexts -C level2\%%A_fs_config -l !size! -a %%A level1\%%A.PARTITION level2\%%A\
    )
)

if exist level1\super.PARTITION (
    FOR %%A IN (system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b) DO (
        if exist level2\%%A\ (
            set /p size=<"level2\config\%%A_size.txt"
            bin\windows\make_ext4fs -s -J -L %%A -T -1 -S level2\config\%%A_file_contexts -C level2\config\%%A_fs_config -l !size! -a %%A level2\%%A.img level2\%%A\
        )
    )
)

echo Done.
pause
exit

:level3

if exist level3 goto pass3
echo Unpack level 3 first
pause
exit

:pass3

FOR %%A IN (recovery boot recovery_a boot_a) DO (
    if exist level3\%%A\ (
        call bin\windows\aik\cleanup.bat
        if exist level3\%%A\ramdisk\ (
            move level3\%%A\ramdisk bin\windows\aik\
        )
        move level3\%%A\split_img bin\windows\aik\
        call bin\windows\aik\repackimg.bat
        move bin\windows\aik\image-new.img bin\windows\aik\%%A.img
        call bin\windows\aik\unpackimg.bat bin\windows\aik\%%A.img
        if exist bin\windows\aik\ramdisk\ (
            move bin\windows\aik\ramdisk level3\%%A\
        )
        move bin\windows\aik\split_img  level3\%%A\
        move bin\windows\aik\%%A.img level1\%%A.PARTITION
        call bin\windows\aik\cleanup.bat
    )
)

if exist level3\logo\ (
bin\windows\imgpack -r level3\logo level1\logo.PARTITION
)

@echo off
set cnt=0
for %%A in (level3\devtree\*.dts) do set /a cnt+=1
echo File count = !cnt!

if !cnt! gtr 1 (
for %%x in (level3\devtree\*.dts) do (
  bin\windows\dtc.exe -I dts -O dtb -o level3\devtree\%%~nx.dtb %%x
)
bin\windows\dtbTool -p bin\windows\ -v level3\devtree\ -o _aml_dtb
) else (
bin\windows\dtc -I dts -O dtb -o level1\_aml_dtb.PARTITION level3\devtree\single.dts 
)

set file="_aml_dtb"
FOR /F "usebackq" %%A IN ('%file%') DO set size=%%~zA

if %size% gtr 196607 (
  bin\windows\gzip -nc _aml_dtb > level1\_aml_dtb.PARTITION
) else (
  copy _aml_dtb level1\_aml_dtb.PARTITION
)

del level3\devtree\*.dtb

if exist _aml_dtb (
  del _aml_dtb
)

echo Done.
pause
exit
