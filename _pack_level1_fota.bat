@echo off

cls

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

for /R %%f in (in\*.img) do (set filename=%%~nf)

bin\windows\7za x bin\windows\update.zip -otmp

copy level1\boot.PARTITION tmp\boot.img
copy level1\ddr.USB tmp\bootloader.img
copy level1\_aml_dtb.PARTITION tmp\dt.img
copy level1\dtbo.PARTITION tmp\dtbo.img
copy level1\logo.PARTITION tmp\logo.img
copy level1\recovery.PARTITION tmp\recovery.img
copy level1\vbmeta.PARTITION tmp\vbmeta.img

copy level1\odm.PARTITION tmp\odm.img
bin\windows\img2sdat tmp\odm.img -o tmp -v 4 -p odm
bin\windows\brotli.exe --in tmp\odm.new.dat --out tmp\odm.new.dat.br --quality 6 -w 24
del tmp\odm.img tmp\odm.new.dat

copy level1\product.PARTITION tmp\product.img
bin\windows\img2sdat tmp\product.img -o tmp -v 4 -p product
bin\windows\brotli.exe --in tmp\product.new.dat --out tmp\product.new.dat.br --quality 6 -w 24
del tmp\product.img tmp\product.new.dat

copy level1\vendor.PARTITION tmp\vendor.img
bin\windows\img2sdat tmp\vendor.img -o tmp -v 4 -p vendor
echo Please Wait...
bin\windows\brotli.exe --in tmp\vendor.new.dat --out tmp\vendor.new.dat.br --quality 6 -w 24
del tmp\vendor.img tmp\vendor.new.dat

copy level1\system.PARTITION tmp\system.img
bin\windows\img2sdat tmp\system.img -o tmp -v 4 -p system
echo Please Wait...
bin\windows\brotli.exe --in tmp\system.new.dat --out tmp\system.new.dat.br --quality 6 -w 24
del tmp\system.img tmp\system.new.dat

bin\windows\7za a out\update_tmp.zip .\tmp\*

echo Signing...
java -jar bin\windows\zipsigner.jar out\update_tmp.zip "out\%filename%_fota.zip"

del out\update_tmp.zip
if exist tmp rmdir /q /s tmp

echo Done.
pause
