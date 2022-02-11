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

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist level3 rmdir /q /s level3
md level3 level3\boot level3\recovery level3\logo level3\devtree

FOR %%A IN (recovery boot) DO (
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

bin\windows\dtc -I dtb -O dts -o level3\devtree\single.dts level1\_aml_dtb.PARTITION
bin\windows\7za x level1\_aml_dtb.PARTITION -y > NUL:
bin\windows\dtbSplit level1\_aml_dtb.PARTITION level3\devtree\

if exist _aml_dtb (
	bin\windows\dtbSplit _aml_dtb level3\devtree\
	del _aml_dtb
)

for %%x in (level3\devtree\*.dtb) do (
  bin\windows\dtc -I dtb -O dts -o level3\devtree\%%~nx.dts %%x
  del %%x
)

ROBOCOPY level3 level3 /S /MOVE /NFL /NDL /NJH /NJS /nc /ns /np

echo Done.
pause
