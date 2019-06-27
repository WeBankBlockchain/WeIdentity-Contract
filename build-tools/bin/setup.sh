#!/bin/bash

SOLC=$(which fisco-solc)
WEB3J="dist/bin/web3sdk.sh"
java_source_code_dir=$2
temp_file=$(date +%s)".temp"

for jar_file in ${java_source_code_dir}/dist/lib/*.jar
do
CLASSPATH=${CLASSPATH}:${jar_file}
done

function check_jdk()
{
    # Determine the Java command to use to start the JVM.
    if [ -n "$JAVA_HOME" ] ; then
        if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
            # IBM's JDK on AIX uses strange locations for the executables
            JAVACMD="$JAVA_HOME/jre/sh/java"
        else
            JAVACMD="$JAVA_HOME/bin/java"
		fi
    if [ ! -x "$JAVACMD" ] ; then
        echo "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME
             Please set the JAVA_HOME variable in your environment to match the
             location of your Java installation."
    fi
    else
        JAVACMD="java"
        which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

    Please set the JAVA_HOME variable in your environment to match the
    location of your Java installation."
    fi
}


function compile_contract() 
{ 
    package="com.webank.weid.contract"
    output_dir="${java_source_code_dir}/dist/output"
    echo "output_dir is $output_dir"
    local files=$(ls dist/contracts/*.sol)
    for itemfile in ${files}
    do
        local item=$(basename ${itemfile} ".sol")
        ${SOLC} --abi --bin -o ${output_dir} ${itemfile} --overwrite
        echo "${output_dir}/${item}.bin, ${output_dir}, ${package} "
        ${WEB3J} solidity generate ${output_dir}"/"${item}".bin" ${output_dir}"/"${item}".abi" -o ${output_dir} -p ${package} 
    done
}


function replace_java_contract()
{
    #override new java contract code
    cd ${java_source_code_dir}/
    cp -r dist/output/com src/main/java/

}

function clean_config()
{
    echo "begin to clean config..."
    cd ${java_source_code_dir}/dist
    if [ -d bin/ ];then
    	rm -rf bin/
    fi
    if [ -d contracts/ ];then
    	rm -rf contracts/
    fi
    if [ -d output/ ];then
    	rm -rf output/
    fi
    echo "clean finished..."
}

function main()
{
    compile_contract ${1} ${2} ../output/
    replace_java_contract
    clean_config
}

main
