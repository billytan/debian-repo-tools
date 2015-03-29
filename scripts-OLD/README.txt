
scripts/show-updated-packages.sh

    把 /disk4/baixibao_repo_root/debian 包库，与下载的 Debiab PPC64 port 包库比较（/disk2/debian_mirror_ppc64/debian）；

    在当前目录下，生成一个 updated-packages-list.txt 列表文件；

scripts/with-gpg-agent.sh

    涉及包入库，到需要 gpg secret key；这个脚本会自动启动 gpg-agent，会设置口令；
    

scripts/package-import-test.sh
    测试 base-files 软件包的入库；会调用 with-gpg-agent.sh ；




