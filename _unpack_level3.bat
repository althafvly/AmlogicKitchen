@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist level3 rmdir /q /s level3
md level3 level3\boot level3\recovery level3\logo level3\devtree

if exist level1\boot.PARTITION (
bin\windows\unpackbootimg.exe -i level1\boot.PARTITION -o level3\boot
)
if exist level1\recovery.PARTITION (
bin\windows\unpackbootimg.exe -i level1\recovery.PARTITION -o level3\recovery
)

if exist level1\logo.PARTITION (
bin\windows\imgpack -d level1\logo.PARTITION level3\logo
)

if exist level1\_aml_dtb.PARTITION (
bin\windows\dtbSplit level1\_aml_dtb.PARTITION level3\devtree\

for %%x in (level3\devtree\*.dtb) do (
  bin\windows\dtc.exe -I dtb -O dts -o level3\devtree\%%~nx.dts %%x
  del %%x
)
)

echo Done.
pause
