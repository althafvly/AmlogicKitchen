@echo off
setlocal EnableDelayedExpansion

cls

if exist level2 goto pass
echo Unpack level 2 first
pause
exit

:pass

FOR %%A IN (odm oem product vendor system system_ext) DO (
    if exist level2\%%A\ (
        set /p size=<"level2\%%A_size"
        bin\windows\make_ext4fs -s -J -L %%A -T -1 -S level2\%%A_file_contexts -C level2\%%A_fs_config -l !size! -a %%A level1\%%A.PARTITION level2\%%A\
    )
)

echo Done.
pause
exit

:size
set SIZE=%~z1
goto :eof
