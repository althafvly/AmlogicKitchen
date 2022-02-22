@echo off

cls

python --version 2>NUL
if errorlevel 1 (
echo Error^: Python not installed
pause
exit
)
if exist level1 goto pass
echo Unpack level 1 first
pause
exit

if "%JAVA_HOME%" != "" goto pass
echo Install Java first
pause
exit

:pass

if not exist out md out

if exist tmp rmdir /q /s tmp
md tmp

if exist level1\super.PARTITION (
    echo Does not support Super Image at the moment
    pause
    exit
)

robocopy bin\common\fota tmp\ /E

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

:PROMPT
echo Compress with brolti?
SET /P compress=input y default n)?

FOR %%A IN (odm oem product vendor system system_ext) DO (
    if exist level1\%%A.PARTITION (
        copy level1\%%A.PARTITION tmp\%%A.img
        python bin\common\img2sdat.py tmp\%%A.img -o tmp -v 4 -p %%A
        IF /I "%compress%" EQU "y" (
            bin\windows\brotli.exe --in tmp\%%A.new.dat --out tmp\%%A.new.dat.br --quality 6 -w 24
            del tmp\%%A.img tmp\%%A.new.dat
        )
    )
)

set script="tmp/META-INF/com/google/android/updater-script"

echo set_bootloader_env("upgrade_step", "3");>%script%
echo show_progress(0.650000, 0);>>%script%

FOR %%A IN (system system_ext vendor product odm oem) DO (
    if exist tmp\%%A.new.dat (
        echo ui_print("Patching %%A image unconditionally...");>>%script%
        echo|set /p="block_image_update("/dev/block/%%A", package_extract_file("%%A.transfer.list"), "%%A.new.dat", "%%A.patch.dat") ||">>%script%
        echo:>>%script%
        echo|set /p="  abort("E1001: Failed to update %%A image.");">>%script%
        echo:>>%script%
    )
    if exist tmp\%%A.new.dat.br (
        echo ui_print("Patching %%A image unconditionally...");>>%script%
        echo|set /p="block_image_update("/dev/block/%%A", package_extract_file("%%A.transfer.list"), "%%A.new.dat.br", "%%A.patch.dat") ||">>%script%
        echo:>>%script%
        echo|set /p="  abort("E1001: Failed to update %%A image.");">>%script%
        echo:>>%script%
    )
)

if exist tmp\logo.img (
echo ui_print("update logo.img...");>>%script%
echo package_extract_file("logo.img", "/dev/block/logo");>>%script%
)

if exist tmp\dtbo.img (
echo ui_print("update dtbo.img...");>>%script%
echo package_extract_file("dtbo.img", "/dev/block/dtbo");>>%script%
)

if exist tmp\dtb.img (
echo ui_print("update dtb.img...");>>%script%
echo backup_data_cache(dtb, /cache/recovery/);>>%script%
echo delete_file("/cache/recovery/dtb.img");>>%script%
)

if exist tmp\recovery.img (
echo backup_data_cache(recovery, /cache/recovery/);>>%script%
echo ui_print("update recovery.img...");>>%script%
echo package_extract_file("recovery.img", "/dev/block/recovery");>>%script%
echo delete_file("/cache/recovery/recovery.img");>>%script%
)

if exist tmp\boot.img (
echo|set /p="package_extract_file("boot.img", "/dev/block/boot");">>%script%
echo:>>%script%
)

if exist tmp\dt.img (
echo|set /p="write_dtb_image(package_extract_file("dt.img"));">>%script%
echo:>>%script%
)

if exist tmp\vbmeta.img (
echo ui_print("update vbmeta.img...");>>%script%
echo package_extract_file("vbmeta.img", "/dev/block/vbmeta");>>%script%
)

if exist tmp\bootloader.img (
echo ui_print("update bootloader.img...");>>%script%
echo write_bootloader_image(package_extract_file("bootloader.img"));>>%script%
)

echo if get_update_stage() == "2" then>>%script%
echo format("ext4", "EMMC", "/dev/block/metadata", "0", "/metadata");>>%script%
echo format("ext4", "EMMC", "/dev/block/tee", "0", "/tee");>>%script%
echo wipe_cache();>>%script%
echo set_update_stage("0");>>%script%
echo endif;>>%script%
echo set_bootloader_env("upgrade_step", "1");>>%script%
echo set_bootloader_env("force_auto_update", "false");>>%script%
echo set_progress(1.000000);>>%script%

if exist out\update_tmp.zip (
del out\update_tmp.zip
)

bin\windows\7za a out\update_tmp.zip .\tmp\*

echo Signing...
set /p filename=< level1\projectname.txt
if exist out\%filename%_fota.zip (
  del out\%filename%_fota.zip
)
java -jar bin\common\zipsigner.jar bin\common\testkey.x509.pem bin\common\testkey.pk8 out\update_tmp.zip "out\%filename%_fota.zip"

del out\update_tmp.zip
if exist tmp rmdir /q /s tmp

echo Done.
pause
