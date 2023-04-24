#!/usr/bin/env bash

iput_format=""
output_format=""
directory=""
current_dir=""

input_mkv_bool=false
input_mkv_flac_bool=false
input_mp4_bool=false
input_webm_bool=false
output_mkv_bool=false
output_mkv_flac_bool=false
output_mp4_bool=false
output_webm_bool=false

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

list_format()
{
  spacer
  cat << EOL
Available Formats:
                    - mkv
                    - mkv_flac
                    - mp4
                    - webm
EOL
  spacer
}

# Checks inputs of user
check_input()
{
  spacer; yellow "Checking input formats..."
  if [[ "$input_format" == "mkv" || "$input_format" == "MKV" ]]; then
    input_mkv_bool=true
    spacer; green "$input_format is a valid format, continuing..."
  elif [[ "$input_format" == "mkv_flac" || "$input_format" == "MKV_FLAC" ]]; then
    input_mkv_flac_bool=true
    spacer; green "$input_format is a valid format, continuing..."
  elif [[ "$input_format" == "mp4" || "$input_format" == "MP4" ]]; then
    input_mp4_bool=true
    spacer; green "$input_format is a valid format, continuing..."
  elif [[ "$input_format" == "webm" || "$input_format" == "WEBM" ]]; then
    input_webm_bool=true
    spacer; green "$input_format is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid input format! Exiting..."
    exit
  fi
}

# Checks outputs of user
check_output()
{
  spacer; yellow "Checking output formats..."
  if [[ "$output_format" == "mkv" || "$output_format" == "MKV" ]]; then
    output_mkv_bool=true
    spacer; green "$output_format is a valid format, continuing..."
  elif [[ "$output_format" == "mkv_flac" || "$output_format" == "MKV_FLAC" ]]; then
    output_mkv_flac_bool=true
    spacer; green "$output_format is a valid format, continuing..."
  elif [[ "$output_format" == "mp4" || "$output_format" == "MP4" ]]; then
    output_mp4_bool=true
    spacer; green "$output_format is a valid format, continuing..."
  elif [[ "$output_format" == "webm" || "$output_format" == "WEBM" ]]; then
    output_webm_bool=true
    spacer; green "$output_format is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid output format! Exiting..."
    exit
  fi
}

# Checks current selected dir
check_filepath()
{
  check="n"
  tmp_input_mkv_string=""
  tmp_input_mkv_flac_string=""
  tmp_input_mp4_string=""
  tmp_input_webm_string=""
  tmp_output_mkv_string=""
  tmp_output_mkv_flac_string=""
  tmp_output_mp4_string=""
  tmp_output_webm_string=""

  if [[ $input_mkv_bool == "true" ]]; then
    tmp_input_mkv_string=".MKV"
  elif [[ $input_mkv_flac_bool == "true" ]]; then
    tmp_input_mkv_flac_string=".MKV with FLAC"
  elif [[ $input_mp4_bool == "true" ]]; then
    tmp_input_mp4_string=".MP4"
  elif [[ $input_webm_bool == "true" ]]; then
    tmp_input_webm_string=".WEBM"
  fi
  
  if [[ $output_mkv_bool == "true" ]]; then
    tmp_output_mkv_string=".MKV"
  elif [[ $output_mkv_flac_bool == "true" ]]; then
    tmp_output_mkv_flac_string=".MKV with FLAC"
  elif [[ $output_mp4_bool == "true" ]]; then
    tmp_output_mp4_string=".MP4"
  elif [[ $output_webm_bool == "true" ]]; then
    tmp_output_webm_string=".WEBM"
  fi

  cd "$directory"
  current_dir="${PWD}/"  
 
  spacer; cyan "Selected Input Format: $tmp_input_mkv_string  |  $tmp_input_mkv_flac_string  |  $tmp_input_mp4_string  |  $tmp_input_webm_string"
  cyan "Selected Output Format: $tmp_output_mkv_string  |  $tmp_output_mkv_flac_string  |  $tmp_output_mp4_string  |  $tmp_output_webm_string"
  cyan "Current file path: $current_dir"
  spacer; cyan "Is the information that is currently displayed, correct? y/n:"
  spacer; read  -n 1 -p "Input:" check; spacer
  
  if [[ $check == "n" || $check == "N" ]]; then
    spacer; yellow "WARNING: Incorrect file path! Exiting..."
    exit
  elif [[ $check == "y" || $check == "Y" ]]; then
    spacer; yellow "WARNING: Starting format process!"
  else
    spacer; red "ERROR: Unknown input! Exiting..."
    exit
  fi
}

# Convert MKV to MP4 with defualt subtitles 
mkv_to_mp4_default()
{
  spacer; yellow "Converting .MKV to .MP4..."
  for i in *.mkv; do ffmpeg -hwaccel cuda -i "$i" -vcodec copy -acodec copy -scodec mov_text "${i%.*}.mp4"; done
  spacer; green "Finished converting!"
}

# Convert MKV with FLAC -> MP4 with default subititles
mkv_to_mp4_flac()
{
  spacer; yellow "Converting .MKV to .MP4 with FLAC audio..."
  for i in *.mkv; do ffmpeg -hwaccel cuda -i "$i" -map 0 -c:v copy -c:a aac -c:s mov_text "${i%.*}.mp4"; done
  spacer; green "Finished converting!"
}

# Convert MP4 -> MKV
mp4_to_mkv_default()
{
  spacer; yellow "Converting .MP4 to .MKV..."
  for i in *.mp4; do ffmpeg -hwaccel cuda -i "$i" -vcodec copy -acodec copy "${i%.*}.mkv"; done
  spacer; green "Finished converting!"
}

# Convert WEBM -> MKV
webm_to_mkv_default()
{
  spacer; yellow "Converting .WebM to .MKV..."
  for i in *.webm; do ffmpeg -hwaccel cuda -i "$i" -c copy "${i%.*}.mkv"; done
  spacer; green "Finished converting!"
}

clear

while getopts ":i:o:d:lh" arg
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
        exit 1
        ;;
    "h")
        spacer
        cat << EOL
Options:
         -i: Input format
         -o: Output format
         -l: List format options
         -d: Directory to format ( WARNING: Directory is NOT recursive! )
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

clear
green "Starting program..."

main()
{
  check_input
  check_output
  check_filepath

  input_mkv_string=""
  input_mkv_flac_string=""
  input_mp4_string=""
  input_webm_string=""
  output_mkv_string=""
  output_mkv_flac_string=""
  output_mp4_string=""
  output_webm_string=""

  if [[ "$input_mkv_bool" == "true" && "$output_mkv_bool" == "true" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1
  elif [[ "$input_mkv_flac_bool" == "true" && "$output_mkv_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1 
  elif [[ "$input_mp4_bool" == "true" && "$output_mkv_bool" ]]; then
    spacer; yellow "WARNING: Processing videos! This may take a while..."
    mp4_to_mkv_default
    exit 1
  elif [[ "$input_webm_bool" == "true" && "$output_mkv_bool" ]]; then
    spacer; yellow "WARNING: Processing videos! This may take a while..."
    webm_to_mkv_default
    exit 1
  fi
  
  if [[ "$input_mkv_bool" == "true" && "$output_mkv_flac_bool" == "true" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1
  elif [[ "$input_mkv_flac_bool" == "true" && "$output_mkv_flac_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1 
  elif [[ "$input_mp4_bool" == "true" && "$output_mkv_flac_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1
  elif [[ "$input_webm_bool" == "true" && "$output_mkv_flac_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1
  fi
  
  if [[ "$input_mkv_bool" == "true" && "$output_mp4_bool" == "true" ]]; then
    spacer; yellow "WARNING: Processing videos! This may take a while..."
    mkv_to_mp4_default
    exit 1
  elif [[ "$input_mkv_flac_bool" == "true" && "$output_mp4_bool" ]]; then
    spacer; yellow "WARNING: Processing videos! This may take a while..." 
    mkv_to_mp4_flac
    exit 1
  elif [[ "$input_mp4_bool" == "true" && "$output_mp4_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1 
  elif [[ "$input_webm_bool" == "true" && "$output_mp4_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1
  fi

  if [[ "$input_mkv_bool" == "true" && "$output_webm_bool" == "true" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1 
  elif [[ "$input_mkv_flac_bool" == "true" && "$output_webm_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1 
  elif [[ "$input_mp4_bool" == "true" && "$output_webm_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1 
  elif [[ "$input_webm_bool" == "true" && "$output_webm_bool" ]]; then
    spacer; red "ERROR: Combination not currently available. Please select different options." 
    exit 1
  fi
}

main
