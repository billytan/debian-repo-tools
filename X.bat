@echo off

call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests common.tcl
call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests common-tests.tcl

call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests DebianRepository.tcl

call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests DebianLocalRepository.tcl
call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests DebianLocalRepository-tests.tcl

call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests DebianRemoteRepository.tcl
call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests DebianRemoteRepository-tests.tcl

call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests my-apt-cache.sh


REM call C:\bin\X.bat sugou /baixibao2/baixibao2_repo_root/tests G:/kbskit/kbskit-0.4.6/Linux64_kbsmk8.6-cli

exit /B

call C:\bin\X.bat jessie /home/billy/debian-tools DebianRemoteRepo-tests.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools DebianRemoteRepo.tcl

call C:\bin\X.bat jessie /home/billy/debian-tools common.tcl
call C:\bin\X.bat jessie /home/billy/debian-tools common-tests.tcl

exit /B

call C:\bin\X.bat jessie /home/billy/debian-tools E:/kbskit/kbskit-0.4.6/Linux64_kbsmk8.6-cli



