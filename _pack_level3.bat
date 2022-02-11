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

if exist level3\boot\ (
	call bin\windows\aik\cleanup.bat
	if exist level3\boot\ramdisk\ (
		move level3\boot\ramdisk bin\windows\aik\
	)
	move level3\boot\split_img bin\windows\aik\
	call bin\windows\aik\repackimg.bat
	move bin\windows\aik\image-new.img bin\windows\aik\boot.img
	call bin\windows\aik\unpackimg.bat bin\windows\aik\boot.img
	if exist bin\windows\aik\ramdisk\ (
		move bin\windows\aik\ramdisk level3\boot\
	)
	move bin\windows\aik\split_img  level3\boot\
	move bin\windows\aik\boot.img level1\boot.PARTITION
	call bin\windows\aik\cleanup.bat
)

if exist level3\recovery\ (
	call bin\windows\aik\cleanup.bat
	if exist level3\recovery\ramdisk\ (
		move level3\recovery\ramdisk bin\windows\aik\
	)
	move level3\recovery\split_img bin\windows\aik\
	call bin\windows\aik\repackimg.bat
	move bin\windows\aik\image-new.img bin\windows\aik\recovery.img
	call bin\windows\aik\unpackimg.bat bin\windows\aik\recovery.img
	if exist bin\windows\aik\ramdisk\ (
		move bin\windows\aik\ramdisk level3\recovery\
	)
	move bin\windows\aik\split_img  level3\recovery\
	move bin\windows\aik\recovery.img level1\recovery.PARTITION
	call bin\windows\aik\cleanup.bat
)

if exist level3\logo\ (
bin\windows\imgpack -r level3\logo level1\logo.PARTITION
)

@echo off
set cnt=0
for %%A in (level3\devtree\*.dts) do set /a cnt+=1
echo File count = %cnt%

bin\windows\dtc -I dts -O dtb -o level1\_aml_dtb.PARTITION level3\devtree\single.dts 

if %count% gtr 1 (
for %%x in (level3\devtree\*.dts) do (
  bin\windows\dtc.exe -I dts -O dtb -o level3\devtree\%%~nx.dtb %%x
  del %%x
)
bin\windows\dtbTool -p bin\windows\ -v level3\devtree\ -o _aml_dtb
)

call :size _aml_dtb
if %SIZE% gtr 196607 (
  bin\windows\gzip -nc _aml_dtb > level1\_aml_dtb.PARTITION
) else (
  copy _aml_dtb level1\_aml_dtb.PARTITION
)
del _aml_dtb

echo Done.
pause
exit

:size
set SIZE=%~z1
goto :eof
