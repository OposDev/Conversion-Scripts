#!/usr/bin/env bash

directory=""
current_dir=""
prefix=false

spacer()
{
  echo ""
}

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

replace()
{
  dir_check="n"

  cd "$directory"
  current_dir="${PWD}/"  
  
  spacer; cyan "Current file path: $current_dir"
  spacer; cyan "Is this the correct file path? y/n:"
  spacer; read  -n 1 -p "Input:" dir_check; spacer
  
  if [[ $dir_check == "n" || $dir_check == "N" ]]; then
    spacer; yellow "WARNING: Incorrect file path! Exiting..."
    exit
  elif [[ $dir_check == "y" || $dir_check == "Y" ]]; then
    spacer; yellow "WARNING: Starting format process!"
  else
    spacer; red "ERROR: Unknown input! Exiting..."
    exit
  fi


  if [[ "$prefix" == false ]]; then
    # Remove "NA - " prefix from file names
    for filename in ./*; do mv "./$filename" "./$(echo "$filename" | sed -e 's/NA\ -\ //g')";  done
  else
    # Remove '[0-09][0-9] - ' prefix from file names
    for file in ??\ -\ *; do
      newname=$(echo "$file" | sed 's/^[0-9][0-9]\ -\ //')
      mv "$file" "$newname"
    done
  fi
  
  spacer; green "Finished processing!"
}

while getopts ":c:d:h" arg
do
  case "$arg" in
    "c")
        =$OPTARG
        ;;
    "d")
        directory=$OPTARG
        ;;
    "h")
        spacer
        cat << EOL
Options:
         -c: Change prefix (Default is NA, alt is XX)
         -d: Directory to format
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
  replace
}

main
