#!/bin/bash

if [ "$TRAVIS_BRANCH" = "master" ];then
    echo "This is a master branch PR, starting build-tools CI pipeline.."
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
    rm -rf weid-build-tools/
    git clone https://github.com/WeBankFinTech/weid-build-tools.git

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

    # copy SDK and contract jar to repo dependencies path and rename
    mkdir -p weid-build-tools/dependencies
    cp dependencies/weid-contract-java-pipeline.jar weid-build-tools/dependencies/weid-contract-java-pipeline.jar
    cp dist/app/$FILENAME weid-build-tools/dependencies/weid-java-sdk-pipeline.jar

    # copy blockchain cfg files
    cp src/main/resources/ca.crt weid-build-tools/resources/
    cp src/main/resources/client.keystore weid-build-tools/resources/

    # run repo ci scripts
    cd weid-build-tools/
    sed -i -e '$a\org_id=test' run.config
    sed -i -e '$a\blockchain_address=$NODE_IP' run.config
    chmod +x *.sh
    ./compile.sh
    ./deploy.sh
else
    echo "This is not a master branch PR (commit omitted). CI skipped."
fi