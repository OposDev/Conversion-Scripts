#!/usr/bin/env bash

links_location=""
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

# Function to check all user input flags
check_user_input()
{
  user_check=""

  if [[ -f "$links_location" ]]; then
    green "$links_location exists!"
  else
    spacer; red "$links_location does NOT exist! Please check your input..."
    exit 1
  fi
  if [[ -f "$RA_location" ]]; then
    green "$RA_location exists!"
  else
    spacer; red "$RA_location does NOT exist! Please check your input..."
    exit 1
  fi
  if [[ -f "$config_location" ]]; then
    green "$config_location exists!"
  else
    spacer; red "$config_location does NOT exist! Please check your input..."
    exit 1
  fi
  if [[ -d "$download_path" ]]; then
    green "$download_path exists!"
  else
    spacer; red "$download_path does NOT exist! Please check your input..."
    exit 1
  fi

  spacer; yellow "Current information registered: "
  yellow "- Links file: $links_location"
  yellow "- RedditArchiver file: $RA_location"
  yellow "- RedditArchiver config file: $config_location"
  yellow "- Download path: $download_path"
  spacer; cyan "Are these the correct input(s)? y/n:"
  read -n 1 -p "Input:" user_check; spacer 
  
  if [[ $user_check == "n" || $user_check == "N" ]]; then
    spacer; yellow "WARNING: Cancelled! Exiting..."
    exit 1
  elif [[ $user_check == "y" || $user_check == "Y" ]]; then
    spacer; yellow "WARNING: Starting download process!"
  else
    spacer; red "ERROR: Unknown input! Exiting..."
    exit 1
  fi
}

clear
green "Starting archiving process..."

while getopts ":i:l:c:d:h" arg
do
  case "$arg" in
    "i")
        links_location=$OPTARG
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
         -i: Location of .txt file containing reddit post links
         -l: Location of RA program
         -c: Location of config file for RA program
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