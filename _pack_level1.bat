@echo off

cls

if exist level1 goto pass
echo Unpack level 1 first
pause
exit

:pass

if exist out rmdir /q /s out
md out

set /p filename=< level1\projectname.txt
if exist level1\image.cfg (
    bin\windows\AmlImagePack -r level1\image.cfg level1 "out\%filename%.img"
    echo Done.
) else (
    echo Can't find image.cfg
)

pause
