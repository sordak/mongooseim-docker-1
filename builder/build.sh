#!/usr/bin/env bash

#set -x

# /builds is assumed to be a shared volume

BUILDS=${BUILDS:-/builds}
LOGFILE=${LOGFILE:-$BUILDS/build.log}
TIMESTAMP=$(date +%F_%H%M%S)

log () {
    echo \[$(date '+%F %H:%M:%S')\] $@
}

build () {
    local name=${1:-MongooseIM}
    local repo=${2:-https://github.com/esl/MongooseIM}
    local commit=${3:-master}
    log do_build: $name $commit $repo | tee -a $LOGFILE
    local workdir=/tmp/mongooseim
    local version_file=_build/prod/rel/mongooseim/version
    [ -d $workdir ] && rm -rf $workdir
    git clone $repo $workdir && \
        cd $workdir && \
        git checkout $commit && \
        tools/configure with-all && \
        make rel && \
        chmod +x rebar3 && \
        ./rebar3 compile && \
        echo "${name}-${commit}-${repo}" > ${version_file} && \
        git describe --always >> ${version_file}
    local build_success=$?
    local timestamp=$(date +%F_%H%M%S)
    local tarball="mongooseim-${name}-${commit}-${timestamp}.tar.gz"
    if [ $build_success = 0 ]; then
        cd _build/prod/rel && \
            tar cfzh ${BUILDS}/${tarball} mongooseim && \
            log "${BUILDS}/$tarball is ready" && \
            tar cfzh mongooseim.tar.gz mongooseim && \
            mv -v mongooseim.tar.gz /member/ && \
            log "tarball moved to /member" && \
            cd /git && \
            for i in `( set -o posix ; set ) | grep _REPO | awk -F'=' '{print $2}'` ; do git clone https://${GIT_CREDS}@${i} ; done
            cd /
            for i in `printenv | grep _CONFIG_TPL=g` ; do template_file=`echo $i | awk -F'=' '{print $2}'`; config_file=`echo $template_file | awk -F'.tpl' '{print $1}'` ; cp -v $template_file $config_file ; container=`echo $i | awk -F'_CONFIG_TPL' '{print $1}'`; for j in `printenv | grep "^$container" | awk -F'=' '{print $1'}`; do sed -i "s~$j~${!j}~g" $config_file ; done ; done
            for i in `printenv | grep _CONFIG_FILE=g` ; do config_file=`echo $i | awk -F'=' '{print $2}'` ; template_file=$config_file.tpl ; cp -v $config_file $template_file ; container=`echo $i | awk -F'_CONFIG_FILE' '{print $1}'`; for j in `printenv | grep "^$container" | awk -F'=' '{print $1'}`; do sed -i "s~$j~${!j}~g" $config_file ; done ; done
            log "DONE"
            exit 0
    else
        log "build failed"
        exit 1
    fi
    log "tarball generation failed"
    exit 2
}

build $@
