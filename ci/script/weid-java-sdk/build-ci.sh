#!/bin/bash

if [ "$TRAVIS_BRANCH" = "master" ];then
    echo "This is a master branch PR, starting build-tools CI pipeline.."
    # build weid-contract and generate jar package
    chmod +x build-tools/bin/*.sh
    build-tools/bin/run.sh

    # clone repo
    rm -rf weid-java-sdk/
    git clone https://github.com/WeBankFinTech/weid-java-sdk.git

    # copy SDK jar to repo dependencies path and rename
    # requires repo to allow local dep first
    mkdir -p weid-java-sdk/dependencies
    cp dist/app/weid-contract-java-0.1.jar weid-java-sdk/dependencies/weid-contract-java-pipeline.jar

    # run repo ci scripts
    cd weid-java-sdk/
    gradle wrapper
    chmod +x ci/script/build-ci.sh
    ci/script/build-ci.sh
    gradle check
else
    echo "This is not a master branch PR (commit omitted). CI skipped."
fi
