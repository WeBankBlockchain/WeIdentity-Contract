#!/bin/bash

if [ "$TRAVIS_BRANCH" = "master" ];then
    echo "This is a master branch PR, starting Sample CI pipeline.."
    # build weid-contract and generate jar package
    chmod +x build-tools/bin/*.sh
    build-tools/bin/run.sh

    # clone java-sdk repo
    rm -rf weid-java-sdk/
    git clone https://github.com/WeBankFinTech/weid-java-sdk.git

    # copy SDK jar to repo dependencies path and rename
    # requires repo to allow local dep first
    mkdir -p weid-java-sdk/dependencies
    cp dist/app/weid-contract-java-0.1.jar weid-java-sdk/dependencies/weid-contract-java-pipeline.jar

    # run repo ci scripts (no UT needed)
    # starting from now, we will be in weid-java-sdk/ directory
    cd weid-java-sdk/
    chmod +x ci/script/build-ci.sh
    ci/script/build-ci.sh

    # clone repo
    rm -rf weid-sample/
    git clone https://github.com/WeBankFinTech/weid-sample.git

    # construct SDK jar version and file name
    cat build.gradle | grep "version =" > temp.ver
    sed -e "s/version = \"//g" -i temp.ver
    sed -e "s/\"//g" -i temp.ver
    SDKVER=$(cat temp.ver)
    rm temp.ver
    SDKNAME='weid-java-sdk-'
    JAR='.jar'
    FILENAME="$SDKNAME$SDKVER$JAR"
    echo sdk jar filename: $FILENAME

    # copy SDK jar to repo dependencies path and rename
    # requires repo to allow local dep first
    mkdir -p weid-sample/dependencies
    cp dependencies/weid-contract-java-pipeline.jar weid-sample/dependencies/weid-contract-java-pipeline.jar
    cp dist/app/$FILENAME weid-sample/dependencies/weid-java-sdk-pipeline.jar

    # run repo ci scripts
    cd weid-sample/
    # gradle build -x test
else
    echo "This is not a master branch PR (commit omitted). CI skipped."
fi