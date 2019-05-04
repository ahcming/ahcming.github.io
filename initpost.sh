#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#
# Program: initpost.sh
# Author:  Vitor Britto
# Description: script to create an initial structure for my posts.
#
# Usage: ./initpost.sh [options] <post name>
#
# Options:
#   -h, --help        output instructions
#   -c, --create      create post
#
# Alias: alias ipost="bash ~/path/to/script/initpost.sh"
#
# Example:
#   ./initpost.sh -c How to replace strings with sed
#
# Important Notes:
#   - This script was created to generate new markdown files for my blog.
#
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# | VARIABLES                                                                  |
# ------------------------------------------------------------------------------

# CORE: Do not change these lines
# ----------------------------------------------------------------
POST_TITLE="${@:2:$(($#-1))}"
POST_NAME="$(echo ${@:2:$(($#-1))} | sed -e 's/ /-/g' | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/")"
CURRENT_DATE="$(date +'%Y-%m-%d')"
TIME=$(date +"%H:%M")
FILE_NAME="${CURRENT_DATE}-${POST_NAME}.md"
TAGS=""
# ----------------------------------------------------------------


# SETTINGS: your configuration goes here
# ---------------------------------------------------------------r

# Set your destination folder
BINPATH=$(cd `dirname $0`; pwd)
POSTPATH="${BINPATH}/_posts"
DIST_FOLDER="$POSTPATH"

# Set your blog URL
BLOG_URL="https://ahcming.github.io/"

# Set your assets URL
ASSETS_URL="assets/images/"
# ----------------------------------------------------------------

# ------------------------------------------------------------------------------
# | UTILS                                                                      |
# ------------------------------------------------------------------------------


# Header logging
e_header() {
    printf "$(tput setaf 38)→ %s$(tput sgr0)\n" "$@"
}

# Success logging
e_success() {
    printf "$(tput setaf 76)✔ %s$(tput sgr0)\n" "$@"
}

# Error logging
e_error() {
    printf "$(tput setaf 1)✖ %s$(tput sgr0)\n" "$@"
}

# Warning logging
e_warning() {
    printf "$(tput setaf 3)! %s$(tput sgr0)\n" "$@"
}


# ------------------------------------------------------------------------------
# | MAIN FUNCTIONS                                                             |
# ------------------------------------------------------------------------------

# Everybody needs some help
initpost_help() {

cat <<EOT
------------------------------------------------------------------------------
INIT POST - A shortcut to create an initial structure for my posts.
------------------------------------------------------------------------------
Usage: ./initpost.sh [options] <post name>
Options:
  -h, --help        output instructions
  -c, --create      create post
Example:
  ./initpost.sh -c How to replace strings with sed
Important Notes:
  - This script was created to generate new text files to my blog.
Copyright (c) Vitor Britto
Licensed under the MIT license.
------------------------------------------------------------------------------
EOT

}

# Initial content
initpost_content() {

echo "---"
echo "title        : \"${POST_TITLE}\""
echo "author       : ahcming"
echo "description  : "
echo "date         : ${CURRENT_DATE} ${TIME}"

echo "layout       : post"
echo "tag          : [${TAGS}]"
echo "blog         : true"
echo "---"

}

# Create file
initpost_file() {
    if [ ! -f "$FILE_NAME" ]; then
        e_header "Creating template..."
        initpost_content > "${DIST_FOLDER}/${FILE_NAME}"
        e_success "Initial post successfully created!"
        e_warning "${DIST_FOLDER}/${FILE_NAME}"
    else
        e_warning "File already exists."
        exit 1
    fi

}

FUNC_RET=""
FUNC_RETS=()

tag_choice() {
    #e_header "参数: $@" 
    load_succ=0
    tag=""

    level=$1

    declare  tags
    tag_desc=""

    cnt=0
    BIFS=$IFS
    for i in $@
    do
        if [ $cnt -ne 0 ]; then
            IFS=:
            ary=($i)
            #tags+=(${ary[1]})
            tags[${ary[0]}]=${ary[1]}
            tag_desc="${tag_desc} \n${ary[0]}: ${ary[1]}(${ary[2]})"
        fi

        let cnt++
    done
    IFS=$BIFS

    tag_desc="${tag_desc} \n------------------------------"

    while [ ${load_succ} -ne 1 ]
    do
        echo -e "请选择文章${level}标签${tag_desc} "
        read option
        echo ""
       
        if [[ ${option} -lt 0 ]]; then
            e_error "非法选项[${option}]"
        else
            tag=${tags[${option}]}
            if [ "${tag}" == "" ]; then
                e_error "没有选项[${option}]"
            else
                #e_warning "tag: ${tag}"
                load_succ=1
            fi
        fi
    done

    FUNC_RET="${tag}"
    unset tags
    return 0
}

# 格式 level:parent:id:name:desc:has_sub
# level: 当前标签的等级
# parent: 父标签name
# id: 用来在交互中选项的ID
# name: 显示在文章中的标签名
# desc: 用来在交互中提示选择,助记用
# has_sub: 是否有子标签
tags_tree=(
    "0::0:work:工作:Y" 
        "1:work:0:note:笔记:Y"
            "2:note:0:mysql:MySQL:N"
            "2:note:1:git:Git:N"
            "2:note:2:spring:Spring:N"
            "2:note:3:ab:AB测试:N"
            "2:note:4:fiddle:Fiddle抓包:N"
            "2:note:5:rxjava:RxJava:N"
            "2:note:6:python:Python:N"
            "2:note:7:jvm:JVM:N"
            "2:note:8:java:Java:N"
            "2:note:9:design_pattern:设计模式:N"
            "2:note:10:shell:Shell脚本:N"
        "1:work:1:original:原创:Y"
            "2:original:0:mysql:MySQL:N"
            "2:original:1:git:Git:N"
            "2:original:2:spring:Spring:N"
            "2:original:3:ab:AB测试:N"
            "2:original:4:fiddle:Fiddle抓包:N"
            "2:original:5:rxjava:RxJava:N"
            "2:original:6:python:Python:N"
            "2:original:7:jvm:JVM:N"
            "2:original:8:java:Java:N"
            "2:original:9:design_pattern:设计模式:N"
            "2:original:10:shell:Shell脚本:N"
    "0::1:life:生活:Y"
        "1:life:0:tourism:游记:N"
        "1:life:1:other:其它:N"
)

lv_desc=("一级" "二级" "三级")

find_by_level() {
    BIFS=$IFS 
    IFS=:

    unset FUNC_RETS
    FUNC_RETS=()

    for op in "${tags_tree[@]}"
    do
        infos=($op)
        if [ ${infos[0]} == $1 ]; then
            if [ "$2" == "" -o "$2" == "${infos[1]}" ]; then
                FUNC_RETS+=("${infos[2]}:${infos[3]}:${infos[4]}")
            fi
        fi
    done

    IFS=$BIFS
    #echo "==> find level: $1, $2, ${FUNC_RETS[@]}"
    return 0
}

find_by_name() {
    BIFS=$IFS
    IFS=:
    
    for ops in "${tags_tree[@]}"
    do
        infos=($ops)
        if [ "${infos[3]}" == "$1" ]; then
            FUNC_RET=${ops}
            break
        fi
    done

    IFS=$BIFS
    #echo "==> ${FUNC_RET}"
    return 0
}

initpost_tags() {
    cur_level=0
    hasSub="Y"
    pTag=""

    while [ "${hasSub}" != "N" ]
    do
        # load current level tag options
        args=()
        args+=(${lv_desc[$cur_level]})

        find_by_level ${cur_level} ${pTag}
        args+=(${FUNC_RETS[@]})

        tag_choice ${args[@]}
        pTag=${FUNC_RET}

        if [ "${TAGS}" == "" ];then
            TAGS="\"${pTag//_/ }\""
        else
            TAGS="${TAGS}, \"${pTag//_/ }\""
        fi
        
        find_by_name ${FUNC_RET}
        if [ "${FUNC_RET##*:}" == "Y" ]; then
            let cur_level++
        else
            hasSub="N"
        fi

        unset args

    done

    e_success "tags select finish:${TAGS}"
}

# ------------------------------------------------------------------------------
# | INITIALIZE PROGRAM                                                         |
# ------------------------------------------------------------------------------

main() {

    # Show help
    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
        initpost_help ${1}
        exit
    fi

    # Create
    if [[ "${1}" == "-c" || "${1}" == "--create" ]]; then
        initpost_tags
        initpost_file $*
        exit
    fi

}

# Initialize
main $*
