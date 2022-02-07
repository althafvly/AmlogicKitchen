@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist out rmdir /q /s out
md out

for /R %%f in (in\*.img) do (set filename=%%~nf)

bin\windows\AmlImagePack -r level1\image.cfg level1 "out\%filename%.img"

echo Done.
pause
