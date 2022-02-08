@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist level3 rmdir /q /s level3
md level3 level3\boot level3\recovery level3\logo level3\devtree

bin\windows\unpackbootimg.exe -i level1\boot.PARTITION -o level3\boot
bin\windows\unpackbootimg.exe -i level1\recovery.PARTITION -o level3\recovery

bin\windows\imgpack -d level1\logo.PARTITION level3\logo

bin\windows\dtc -I dtb -O dts -o level3\devtree\single.dts level1\_aml_dtb.PARTITION
bin\windows\7za x level1\_aml_dtb.PARTITION -y
bin\windows\dtbSplit level1\_aml_dtb.PARTITION level3\devtree\
bin\windows\dtbSplit _aml_dtb level3\devtree\
del _aml_dtb

for %%x in (level3\devtree\*.dtb) do (
  bin\windows\dtc.exe -I dtb -O dts -o level3\devtree\%%~nx.dts %%x
  del %%x
)

echo Done.
pause
