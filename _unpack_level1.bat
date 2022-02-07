@echo off

cls

if exist level1 rmdir /q /s level1
md level1

for /R %%f in (in\*.img) do (set filename=%%~nf)

bin\AmlImagePack -d "in\%filename%.img" level1

echo Done.
pause
