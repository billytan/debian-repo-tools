@echo off

call C:\bin\X.bat jessie /home/billy/debian-tools common.tcl
call C:\bin\X.bat jessie /home/billy/debian-tools common-tests.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools DebianRepository.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools DebianLocalRepository.tcl
call C:\bin\X.bat jessie /home/billy/debian-tools DebianLocalRepository-tests.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools DebianRemoteRepository.tcl
call C:\bin\X.bat jessie /home/billy/debian-tools DebianRemoteRepository-tests.tcl


call C:\bin\X.bat jessie /home/billy/debian-tools  IncomingDirRepository.tcl
call C:\bin\X.bat jessie /home/billy/debian-tools  IncomingDirRepository-tests.tcl

exit /B

call C:\bin\X.bat jessie /home/billy/debian-tools E:/kbskit/kbskit-0.4.6/Linux64_kbsmk8.6-cli



