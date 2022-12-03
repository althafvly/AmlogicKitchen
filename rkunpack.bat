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
echo Rockchip Kitchen
echo .....................
set /P level=Select level 1,2 or 3: 
IF %level% == 1 GOTO level1
IF %level% == 2 GOTO level2
IF %level% == 3 GOTO level3
echo Unpack level 1 first
pause
exit

:level1

if exist level1 rmdir /q /s level1
md level1

echo .....................
echo Rockchip Kitchen
echo .....................
echo Files in input dir (*.img)
if not exist in\*.img (
  echo Can't find images
  if not exist in\ (
    mkdir in
  )
  pause
  exit 0
)

SET /A COUNT=0
for %%a in (in\*.img) do set /a count += 1 && echo !count! - %%~na
echo .....................
set /P projectname=Enter a file name :
echo %projectname%> level1\projectname.txt

if not exist in\%projectname%.img (
echo Can't find the file
pause
exit 0
)

set /p filename=< level1\projectname.txt

bin\windows\rkImageMaker.exe -unpack "in\%filename%.img" level1
bin\windows\afptool.exe -unpack level1\firmware.img level1
del level1\boot.bin
del level1\firmware.img

pause
exit


:level2

python --version 2>NUL
if errorlevel 1 (
echo Error^: Python not installed
pause
exit
)

if exist level1 goto pass2
echo Unpack level 1 first
pause
exit

:pass2

if exist level2 rmdir /q /s level2
md level2\config\

FOR %%A IN (odm oem product vendor system system_ext odm_ext_a odm_ext_b) DO (
if exist level1\Image\%%A.img (
    python bin\common\imgextractor.py "level2\%%A.img" "level2"
    if exist level1\Image\%%A.raw.img (
        del level1\Image\%%A.raw.img
    )
    if exist level2\config\%%A_file_contexts (
        bin\windows\sed -n "G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P" level2\config\%%A_file_contexts > level2\config\%%A_sorted_file_contexts
        move level2\config\%%A_sorted_file_contexts level2\config\%%A_file_contexts
    )
)
)

if exist level1\Image\super.img (
    bin\windows\simg2img level1\Image\super.img level2\super.img
    bin\windows\du -sb level2\super.img | bin\windows\cut -f1> level2\config\super_size.txt
    bin\windows\super\lpunpack -slot=0 level2\super.img level2\
    del level2\super.img

    FOR %%A IN (odm oem product vendor system system_ext system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b) DO (
    if exist level2\%%A.img (
        call :setsize level2\%%A.img
        if !size! GTR 1024 (
            python bin\common\imgextractor.py "level2\%%A.img" "level2"
        )
        if exist level2\config\%%A_file_contexts (
            bin\windows\sed -n "G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P" level2\config\%%A_file_contexts > level2\config\%%A_sorted_file_contexts
            move level2\config\%%A_sorted_file_contexts level2\config\%%A_file_contexts
        )
    )
    )
)

set cnt=0
for %%A in (level2\*_a.img) do set /a cnt+=1
if exist level1\Image\super.img (
    echo %cnt%
    if %cnt% GTR 0 (
        echo 3 > level2\config\super_type.txt
    ) else (
        echo 2 > level2\config\super_type.txt
    )
)

:setsize
set size=%~z1
goto :eof

echo Done.
pause
exit

:level3

if exist level1 goto pass3
echo Unpack level 1 first
pause
exit

:pass3

if exist level3 rmdir /q /s level3
md level3 level3\boot level3\boot_a level3\recovery level3\recovery_a

FOR %%A IN (recovery boot recovery_a boot_a) DO (
    if exist level1\Image\%%A.img (
        copy level1\Image\%%A.img bin\windows\aik\%%A.img
        call bin\windows\aik\unpackimg.bat bin\windows\aik\%%A.img
        if exist bin\windows\aik\ramdisk\ (
            move bin\windows\aik\ramdisk level3\%%A\
        )
        move bin\windows\aik\split_img level3\%%A\
        del bin\windows\aik\%%A.img
    )
)

ROBOCOPY level3 level3 /S /MOVE /NFL /NDL /NJH /NJS /nc /ns /np

echo Done.
pause
exit
