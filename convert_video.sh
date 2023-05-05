#!/usr/bin/env bash

select=""
directory=""
current_dir=""
script_dir=`pwd`
declare -i num_cores="$(nproc)"
major_range=()
minor_range=()
declare -i total_lines=0
declare -i avg_load=0
m_filepaths="m_filepaths.txt"
ffmpeg_log="log.txt"
remove=false

spacer()
{
  echo ""
}

# Color functionality within terminal
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
                    1 - mkv -> mp4
                    2 - mp4 -> mkv
                    3 - webm -> mkv
                    4 - avi -> mkv
                    5 - flac -> mp3
                    6 - mov -> mkv
EOL
  spacer
}

# Checks inputs of user
check_input()
{
  spacer; yellow "Checking input formats..."
  if [[ "$select" == "1" || "$select" == "2" || "$select" == "3" || "$select" == "4" || "$select" == "5" || "$select" == "6" ]]; then
    spacer; green "$select is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid input format! Exiting..."
    exit 1
  fi
}

# Checks current selected dir & display selected information
check_filepath()
{
  check="n"
  tmp_dir=$(cd "$directory" && pwd)

  if ! [[ -d "$directory" ]]; then
    spacer; red "Selected directory dooes not exist! Exiting..."
    exit 1
  fi
  
  if [[ "$remove" == true ]]; then
    spacer; red "WARNING: Remove flag set to: $remove!"
  else
    spacer; green "Remove flag set to: $remove!"
  fi

  spacer; cyan "Current selected option: $select"
  spacer; cyan "Selected file path: $tmp_dir"
  spacer; cyan "Is the information that is currently displayed, correct? y/n:"
  spacer; read  -n 1 -p "Input:" check; spacer
  
  if [[ $check == "n" || $check == "N" ]]; then
    spacer; yellow "WARNING: Incorrect file path! Exiting..."
    exit
  elif [[ $check == "y" || $check == "Y" ]]; then
    spacer; yellow "WARNING: Starting format process!"
    cd "$script_dir"
  else
    spacer; red "ERROR: Unknown input! Exiting..."
    exit
  fi
}

# Gathers files with selected format -> distributes load across system CPUs
distribute()
{
  input_format=""
  bad_postfix=""

  if [[ "$select" == "1" ]]; then
    input_format="mkv"
    bad_postfix="MKV"
  elif [[ "$select" == "2" ]]; then
    input_format="mp4"
    bad_postfix="MP4"
  elif [[ "$select" == "3" ]]; then
    input_format="webm"
    bad_postfix="WEBM"
  elif [[ "$select" == "4" ]]; then
    input_format="avi"
    bad_postfix="AVI"
  elif [[ "$select" == "5" ]]; then
    input_format="flac"
    bad_postfix="FLAC"
  elif [[ "$select" == "6" ]]; then
    input_format="mov"
    bad_postfix="MOV" 
  else
    spacer; red "ERROR: Unknown! Check distribute(), review ASAP!"
    exit 1
  fi

  # Finds postfix with captital letters -> converts to lowercase for processing
  find "$directory" -type f -print0 | while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    extension="${filename##*.}"
    filename="${filename%.*}"
    mv "${filepath}" "$(dirname ${filepath})/${filename}.${extension,,}"  &> /dev/null
  done

  # Store data for processing
  find "$directory" -type f -iname "*.$input_format" >> "$m_filepaths"
  total_lines=$(wc -l < $m_filepaths)
  avg_load=$(($total_lines/$num_cores))
  declare -i counter_distribution=$(($total_lines))

  if (( $total_lines < $num_cores )); then
    num_cores=$(($total_lines))
  fi

  # Logic for distributing
  for (( i=0; i<$num_cores; i++ )); do
    if (( $i == 0 )); then
      major_range+=("$counter_distribution")
    else
      tmp_lines=$(($counter_distribution-1)); major_range+=("$tmp_lines")
    fi

    ((counter_distribution -= $avg_load))

    if (( $i == ($num_cores-1) )); then
      minor_range+=(1)
      break
    fi
    
    minor_range+=("$counter_distribution")
  done
}

# Light multithreading with ffmpeg -> processes distributioned data
process()
{
  # Convert MKV to MP4 with defualt subtitles 
  function mkv_to_mp4()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      audio_check=$(ffprobe -loglevel error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 "$path")
      
      if echo "$audio_check" | grep -q "truehd"; then
        # Convert MKV with TrueHD -> MP4 with default subititles
        ffmpeg -i "$path" -map 0 -c:v copy -c:a aac -c:s mov_text "${path/%mkv/mp4}" 2>> "$ffmpeg_log"
      else
        # Convert MKV with ACC/AC-3 -> MP4 with default subititles
        ffmpeg -i "$path" -vcodec copy -acodec copy -scodec mov_text "${path/%mkv/mp4}" 2>> "$ffmpeg_log"
      fi
      
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert MP4 -> MKV
  function mp4_to_mkv()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -vcodec copy -acodec copy "${path/%mp4/mkv}" 2>> "$ffmpeg_log"
      
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert WEBM -> MKV
  function webm_to_mkv()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -c copy "${path/%webm/mkv}" 2>> "$ffmpeg_log"
      
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert AVI -> MKV
  function avi_to_mkv()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -c:v ffv1 -level 3 -g 1 -c:a flac "${path/%avi/mkv}" 2>> "$ffmpeg_log"
      
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert FLAC -> MP3
  function flac_to_mp3()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -c:a libmp3lame -q:a 0 "${path/%flac/mp3}" 2>> "$ffmpeg_log"
      
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert MOV -> MKV
  function mov_to_mkv()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -c:v copy -c:a copy "${path/%mov/mkv}" 2>> "$ffmpeg_log"
      
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  if [[ "$select" == "1" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (mkv_to_mp4 "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "2" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (mp4_to_mkv "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "3" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (webm_to_mkv "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "4" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (avi_to_mkv "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "5" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (flac_to_mp3 "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "6" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (mov_to_mkv "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done  
  else
    spacer; red "ERROR: Unknown! Line 116, review ASAP!"
    exit 1
  fi

  pids=$(pgrep -P $$)
  read -n1 -r -p "Press any key to stop all background processes..."

  kill $pids
}

while getopts ":s:d:rlh" arg
do
  case "$arg" in
    "s")
        select=$OPTARG
        ;;
    "d")
        directory=$OPTARG
        ;;
    "l")
        list_format
        exit 1
        ;;
    "r")
        remove=true
        ;;
    "h")
        spacer
        cat << EOL
Options:
         -l: List processing options
         -s: Select processing option
         -d: Directory to format ( WARNING: Directory search is recursive! )
         -r: Remove old files after processing ( Default is: false! )
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
  if (( $num_cores < 1 )); then
    spacer; red "No CPU cores detected! Something is wrong, ending program..."
    exit 1
  fi

  if [[ -f "$m_filepaths" ]]; then
    rm "$m_filepaths"; touch "$m_filepaths"
  else
    touch "$m_filepaths"
  fi

  if ! [[ -f "$ffmpeg_log" ]]; then
    touch "$ffmpeg_log"
  fi

  check_input
  check_filepath
  distribute
  process

  rm "$m_filepaths"
}

main
