#!/usr/bin/env bash

links_file=""
RA_location=""
config_location=""
download_path=""

# Adds color functionality to script
set +x
function red(){
    echo -e "\x1B[31m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[31m $($2) \x1B[0m"
    fi
}

function green(){
    echo -e "\x1B[32m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[32m $($2) \x1B[0m"
    fi
}

function yellow(){
    echo -e "\x1B[33m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[33m $($2) \x1B[0m"
    fi
}

function cyan(){
    echo -e "\x1B[36m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[36m $($2) \x1B[0m"
    fi
}

spacer()
{
  echo ""
}

clear
green "Starting archiving process..."

while getopts ":i:l:c:d:h" arg
do
  case "$arg" in
    "i")
        links_file=$OPTARG
        ;;
    "l")
        RA_location=$OPTARG
        ;;
    "c")
        config_location=$OPTARG
        ;;
    "d")
        download_path=$OPTARG
        ;;
    "h")
        spacer
        cat << EOL
Options:
         -i: Input for .txt file containing reddit post links
         -l: Location of RA program
         -c: Input for config file for RA program
         -d: Download path
         -h: Display help
EOL
        spacer
        exit
        ;;
    ":")
        echo "ERROR: No argument value for option $OPTARG"
        exit
        ;;
    "?")
        echo "ERROR: Unknown option $OPTARG"
        exit
        ;;
    "*")
        echo "ERROR: Unknown error while processing options"
        exit
        ;;
  esac
done

main()
{
  
}
main
