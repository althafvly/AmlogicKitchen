@echo off

cls

if exist level1 rmdir /q /s level1
md level1

for /R %%f in (in\*.img) do (set filename=%%~nf)

if not exist in\*.img (
  echo Can't find images
) else if exist in\ (

bin\windows\AmlImagePack -d "in\%filename%.img" level1

echo Done.
) else (
  echo Can't find /in folder
  echo Creating /in folder
  mkdir in
)

pause
