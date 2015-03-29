@echo off

set HOST=192.168.133.88
set PSCP=C:\bin\pscp.exe -l root -pw baixibao


%PSCP% import-packages-from.tcl %HOST%:/baixibao2/baixibao2_repo_root/scripts

REM %PSCP% compare-repo-with.tcl %HOST%:/baixibao2/baixibao2_repo_root/scripts
REM %PSCP% do-query-packages.tcl %HOST%:/baixibao2/baixibao2_repo_root/scripts
%PSCP% repo_util.tcl         %HOST%:/baixibao2/baixibao2_repo_root/scripts
%PSCP% common_util.tcl       %HOST%:/baixibao2/baixibao2_repo_root/scripts


exit /B

set HOST=192.168.133.126
set PSCP=C:\bin\pscp.exe -l httc -pw httc

%PSCP% update-source-packages.tcl           %HOST%:/disk4/baixibao_repo_root/tools

%PSCP% common_util.tcl                      %HOST%:/disk4/baixibao_repo_root/tools
%PSCP% repo_util.tcl                  %HOST%:/disk4/baixibao_repo_root/tools

%PSCP% README.txt                     %HOST%:/disk4/baixibao_repo_root/scripts/

exit /B


%PSCP% sync-with-ppc64-mirror.tcl             %HOST%:/disk4/baixibao_repo_root/tools

REM %PSCP% compare-repo.tcl                  %HOST%:/disk4/baixibao_repo_root/tools


%PSCP% reload-packages.tcl                  %HOST%:/disk4/baixibao_repo_root/tools
%PSCP% reload-packages-02.tcl                  %HOST%:/disk4/baixibao_repo_root/tools

%PSCP% import-packages-NEW.tcl        %HOST%:/disk4/baixibao_repo_root/tools
%PSCP% common_util.tcl                      %HOST%:/disk4/baixibao_repo_root/tools
%PSCP% repo_util.tcl                  %HOST%:/disk4/baixibao_repo_root/tools

%PSCP% repo-util-tests.tcl                  %HOST%:/disk4/baixibao_repo_root/tools

exit /B

%PSCP% check-packages-with.tcl    %HOST%:/disk4/baixibao_repo_root/tools
%PSCP% check-packages.tcl         %HOST%:/disk4/baixibao_repo_root/tools

exit /B


