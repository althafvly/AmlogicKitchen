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

if exist level3 goto pass
echo Unpack level 3 first
pause
exit

:pass

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

call :size _aml_dtb
if %SIZE% gtr 196607 (
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

:size
set SIZE=%~z1
goto :eof
