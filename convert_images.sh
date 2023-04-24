#!/usr/bin/env bash

iput_format=""
output_format=""
directory=""
current_dir=""
remove_bool=false

spacer()
{
  echo ""
}

list_format()
{
  spacer
  cat << EOL
Available Formats:
                    - png
                    - jpg
                    - jpeg
EOL
  spacer
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

# Checks inputs of user
check_input()
{
  spacer; yellow "Checking input formats..."
  if [[ $input_format == "jpg" || $input_format == "JPG" ]]; then
    spacer; green "$input_format is a valid format, continuing..."
  elif [[ $input_format == "jpeg" || $input_format == "JPEG" ]]; then
    spacer; green "$input_format is a valid format, continuing..."
  elif [[ $input_format == "png" || $input_format == "PNG" ]]; then
    spacer; green "$input_format is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid input format! Exiting..."
    exit
  fi
}

# Checks inputs of user
check_output()
{
  spacer; yellow "Checking output formats..."
  if [[ $output_format == "jpg" || $output_format == "JPG" ]]; then
    spacer; green "$output_format is a valid format, continuing..."
  elif [[ $output_format == "jpeg" || $output_format == "JPEG" ]]; then
    spacer; green "$output_format is a valid format, continuing..."
  elif [[ $output_format == "png" || $output_format == "PNG" ]]; then
    spacer; green "$output_format is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid output format! Exiting..."
    exit
  fi
}

# Checks selected dir then continues towards data processing
convert()
{
  dir_check="n"

  cd "$directory"
  current_dir="${PWD}/"  
 
  if [[ "$remove_bool" == true ]]; then
    spacer; red "WARNING: Remove flag set to: $remove_bool!"
  else
    spacer; green "Remove flag set to: $remove_bool!"
  fi
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

  # Creates a copy of all jpg and jpeg images, then converts to png
  find . -name "*.${input_format}" -exec mogrify -format ${output_format} {} \;
  spacer; green "Finished processing!"
}

# Checks args for deletion
delete()
{
  if [[ $remove_bool == "false" ]]; then
    spacer; yellow "WARNING: Not removing anything! Exiting..."
    exit
  elif [[ $remove_bool == "true" ]]; then
    spacer; yellow "WARNING: Removing files!"
  else
    spacer; red "ERROR: Unknown input! Exiting..."
    exit
  fi
  
  find . -name "*.${input_format}" -exec rm {} \;
  spacer; green "Finished removing!"
}

clear

while getopts ":i:o:d:lrh" arg
do
  case "$arg" in
    "i")
        input_format=$OPTARG
        ;;
    "o")
        output_format=$OPTARG
        ;;
    "d")
        directory=$OPTARG
        ;;
    "l")
        list_format
        exit
        ;;
    "r")
        remove_bool=true
        ;;
    "h")
        spacer
        cat << EOL
Options:
         -i: Input format
         -o: Output Format
         -d: Directory to format ( WARNING: Directory is RECURSIVE )
         -l: List format options
         -r: Set 'True' to remove files after process (DEFAULT IS FALSE)
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
  check_input
  check_output
  convert
  delete
}

main
