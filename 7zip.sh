#!/usr/bin/env bash

file=""
file_path=""
file_name=""
output=""
script_dir=`pwd`
password=false

spacer()
{
  echo ""
}

format_inputs()
{
  file_path=`realpath "$file"`

  if [[ -z "$output" ]]; then
    output="./"
  fi
  
  if [[ "${file: -1}" == "/" ]]; then
    tmp_string="${file::-1}"
    file="$tmp_string"
  fi

  if ! [[ -z "$file_name" ]]; then
    file="$file_name"
  fi
}

7zip_default()
{
  cd "$output"
  7z a -bt -t7z -m0=zstd -mx=11 -mhe=on "$file".7z "$file_path"
  cd "$script_dir"
}

7zip_password()
{
  cd "$output"
  7z a -bt -t7z -m0=zstd -mx=11 -mhe=on -p "$file".7z "$file_path"
  cd "$script_dir"
}

while getopts ":i:o:n:ph" arg
do
  case "$arg" in
    "i")
        file=$OPTARG
        ;;
    "o")
        output=$OPTARG
        ;;
    "n")
      file_name=$OPTARG
        ;;
    "p")
        password=true
        ;;
    "h")
        spacer
        cat << EOL
Options:
         -i: File input
         -o: Output location
         -n: File name (OPTIONAL)
         -p: Enable password (Default: False)
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
  format_inputs
  
  if [[ $password == true ]]; then
    7zip_password
  else
    7zip_default
  fi
}
main
