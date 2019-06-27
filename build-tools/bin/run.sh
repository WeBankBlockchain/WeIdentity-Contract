#!/bin/bash

wget https://github.com/FISCO-BCOS/fisco-solc/raw/master/fisco-solc-ubuntu
sudo cp fisco-solc-ubuntu /usr/bin/fisco-solc
sudo chmod +x /usr/bin/fisco-solc

java_source_code_dir=$(pwd)
current_path=$(pwd)
source_code_dir=$current_path
echo $source_code_dir
cd $source_code_dir
cp -r ./contracts build-tools/

if [ -d dist/ ];then
    rm -rf dist/
fi

mkdir dist
cp -r ./build-tools/* dist/

gradle build

chmod +x dist/bin/*.sh
dist/bin/setup.sh "com.webank.weid.contract" "$source_code_dir"

gradle clean assemble
