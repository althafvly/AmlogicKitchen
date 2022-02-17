@echo off

setlocal EnableDelayedExpansion

cls

if exist level1 rmdir /q /s level1
md level1

echo .....................
echo Amlogic Kitchen
echo .....................
echo Files in input dir (*.img)
if not exist in\*.img (
  echo Can't find images
  if not exist in\ (
    mkdir in
  )
  pause
  exit 0
)

SET /A COUNT=0
for %%a in (in\*.img) do set /a count += 1 && echo !count! - %%~na
echo .....................
set /P projectname=Enter a file name :
echo %projectname%> level1\projectname.txt

if not exist in\%projectname%.img (
echo Can't find the file
pause
exit 0
)

set /p filename=< level1\projectname.txt

bin\windows\AmlImagePack -d "in\%filename%.img" level1

pause
