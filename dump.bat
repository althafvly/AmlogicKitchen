@echo off

setlocal EnableDelayedExpansion

cls

echo .....................
echo Amlogic Dumper
echo .....................
echo Before going any further
echo Please connect your amlogic box in mask mode
echo .....................
pause

if exist dtb rmdir /s /q dtb
md dtb

if exist dump rmdir /s /q dump
md dump

echo .....................
set /P blsize=Input bootloader size in bytes (most are: 4194304) :
set /P dtbsize=Input dtb size in bytes (most are: 262144) :
bin\windows\update mread store bootloader normal !blsize! dump\bootloader.img
bin\windows\update mread store _aml_dtb normal !dtbsize! dtb\dtb.img

if exist dtb\dtb.img (
    bin\windows\dtc -I dtb -O dts -o dtb\single.dts dtb\dtb.img
    bin\windows\7za x dtb\dtb.img -y > NUL:
    bin\windows\dtbSplit dtb\dtb.img dtb\

    if exist _aml_dtb (
        bin\windows\dtbSplit _aml_dtb dtb\
        del _aml_dtb
    )

    for %%x in (dtb\*.dtb) do (
        bin\windows\dtc -I dtb -O dts -o dtb\%%~nx.dts %%x
        del %%x
    )

    for %%x in (dtb\*.dtb) do (
        bin\windows\dtc -I dtb -O dts -o dtb\%%~nx.dts %%x
        del %%x
    )

    move dtb\dtb.img dump\

    SET /A COUNT=0
    for %%a in (dtb\*.dts) do set /a count += 1 && echo !count! - %%~na
    echo .....................
    set /P dtsfile=Input a dts name for dump :

    if not exist dtb\!dtsfile!.dts (
    echo Can't find the file
    pause
    exit 0
    )

    bin\windows\grep -P "\tpname" dtb\!dtsfile!.dts | bin\windows\grep -oP "(?<="")\w+">dump\partitions.txt

    for /f "tokens=*" %%s in (dump\partitions.txt) do (
        bin\windows\sed -n "/%%s {/,/};/p" dtb\single.dts | bin\windows\grep -A 3 "pname" | bin\windows\grep "size" |  bin\windows\grep -oP "(?<=0x0 )\w+">dump\%%s_size.txt
        set /p size=<"dump\%%s_size.txt"
        bin\windows\update mread store %%s normal !size! dump\%%s.img
        del dump\%%s_size.txt
    )
)

if exist dump\partitions.txt (
    del dump\partitions.txt
)

if exist dtb\ (
    rmdir /s /q dtb
)

echo Done.
pause
exit
