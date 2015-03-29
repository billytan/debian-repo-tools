@echo off

call C:\bin\X.bat jessie /home/billy/debian-tools DebianRemoteRepo-tests.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools DebianRemoteRepo.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools common.tcl
call C:\bin\X.bat jessie /home/billy/debian-tools common-tests.tcl

exit /B

call C:\bin\X.bat jessie /home/billy/debian-tools E:/kbskit/kbskit-0.4.6/Linux64_kbsmk8.6-cli



