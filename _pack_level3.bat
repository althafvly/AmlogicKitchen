@echo off

cls

if exist level3 goto pass
echo Unpack level 3 first
pause
exit

:pass

set kernel="level3\boot\boot.PARTITION-zImage"
set ramdisk="level3\boot\boot.PARTITION-ramdisk.gz"
set second="level3\boot\boot.PARTITION-second"

set /p cmdline=<"level3\boot\boot.PARTITION-cmdline"
set /p headerversion=<"level3\boot\boot.PARTITION-header_version"
set /p base=<"level3\boot\boot.PARTITION-base"
set /p pagesize=<"level3\boot\boot.PARTITION-pagesize"
set /p kerneloff=<"level3\boot\boot.PARTITION-kernel_offset"
set /p ramdiskoff=<"level3\boot\boot.PARTITION-ramdisk_offset"
set /p secondoff=<"level3\boot\boot.PARTITION-second_offset"
set /p tagsoff=<"level3\boot\boot.PARTITION-tags_offset"
set /p oslevel=<"level3\boot\boot.PARTITION-os_patch_level"
set /p osversion=<"level3\boot\boot.PARTITION-os_version"
set /p boardname=<"level3\boot\boot.PARTITION-board"
set /p hash=<"level3\boot\boot.PARTITION-hashtype"

if exist level3\boot\ (
bin\windows\mkbootimg.exe --kernel %kernel% --kernel_offset %kerneloff% --ramdisk %ramdisk% --ramdisk_offset %ramdiskoff% --second %second% --second_offset %secondoff% --cmdline "%cmdline%" --board "%boardname%" --base %base% --pagesize %pagesize% --tags_offset %tagsoff% --os_version %osversion% --os_patch_level %oslevel% --header_version %headerversion% --hashtype %hash% -o level1\boot.PARTITION
)

set kernel="level3\recovery\recovery.PARTITION-zImage"
set ramdisk="level3\recovery\recovery.PARTITION-ramdisk.gz"
set second="level3\recovery\recovery.PARTITION-second"
set recoverydtbo="level3\recovery\recovery.PARTITION-recovery_dtbo"

set /p cmdline=<"level3\recovery\recovery.PARTITION-cmdline"
set /p headerversion=<"level3\recovery\recovery.PARTITION-header_version"
set /p base=<"level3\recovery\recovery.PARTITION-base"
set /p pagesize=<"level3\recovery\recovery.PARTITION-pagesize"
set /p kerneloff=<"level3\recovery\recovery.PARTITION-kernel_offset"
set /p ramdiskoff=<"level3\recovery\recovery.PARTITION-ramdisk_offset"
set /p secondoff=<"level3\recovery\recovery.PARTITION-second_offset"
set /p tagsoff=<"level3\recovery\recovery.PARTITION-tags_offset"
set /p oslevel=<"level3\recovery\recovery.PARTITION-os_patch_level"
set /p osversion=<"level3\recovery\recovery.PARTITION-os_version"
set /p boardname=<"level3\recovery\recovery.PARTITION-board"
set /p hash=<"level3\recovery\recovery.PARTITION-hashtype"

if exist level3\recovery\ (
bin\windows\mkbootimg.exe --kernel %kernel% --kernel_offset %kerneloff% --ramdisk %ramdisk% --ramdisk_offset %ramdiskoff% --second %second% --second_offset %secondoff% --recovery_dtbo %recoverydtbo% --cmdline "%cmdline%" --board "%boardname%" --base %base% --pagesize %pagesize% --tags_offset %tagsoff% --os_version %osversion% --os_patch_level %oslevel% --header_version %headerversion% --hashtype %hash% -o level1\recovery.PARTITION
)

if exist level3\logo\ (
bin\windows\imgpack -r level3\logo level1\logo.PARTITION
)

if exist level3\devtree\ (
for %%x in (level3\devtree\*.dts) do (
  bin\windows\dtc.exe -I dts -O dtb -o level3\devtree\%%~nx.dtb %%x
  del %%x
)
bin\windows\dtbTool -p bin\windows\ -v level3/devtree/ -o _aml_dtb
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
