@echo off

cls

if exist level1 rmdir /q /s level1
md level1

if not exist in\*.img (
  echo Can't find images
) else if exist in\ (
for /R %%f in (in\*.img) do (set filename=%%~nf)

bin\windows\AmlImagePack -d "in\%filename%.img" level1

echo Done.
) else (
  echo Can't find /in folder
  echo Creating /in folder
  mkdir in
)

pause
