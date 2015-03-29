@echo off

REM
REM create a separate virtual disk for the storage of downloaded Debian packages, for Wheezy or Jessie
REM

set DISK_FILE=

set UUID=02b876b6-efa4-445a-8365-440681173099

REM -----------------------------------------------

set DO_CREATE_DISK=true

if %DO_CREATE_DISK% == true (

	REM
	REM 1024MB
	REM

	%VBoxManage% createhd --filename %DISK_FILE% --size 1024 --format VHD
)


REM
REM add it as the 2nd SATA disk
REM

%VBoxManage% storageattach %UUID% --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium %DISK_FILE%
