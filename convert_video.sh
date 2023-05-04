#!/usr/bin/env bash

select=""
directory=""
current_dir=""

declare -i num_cores="$(nproc)"
major_range=()
minor_range=()
declare -i total_lines=0
declare -i avg_load=0
m_filepaths="m_filepaths.txt"
remove=false

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
                    1 - mkv -> mp4
                    2 - mkv_flac -> mp4
                    3 - mp4 -> mkv
                    4 - webm -> mkv
EOL
  spacer
}

# Checks inputs of user
check_input()
{
  spacer; yellow "Checking input formats..."
  if [[ $select == "1" ]]; then
    spacer; green "$select is a valid format, continuing..."
  elif [[ $select == "2" ]]; then
    spacer; green "$select is a valid format, continuing..."
  elif [[ $select == "3" ]]; then
    spacer; green "$select is a valid format, continuing..."
  elif [[ $select == "4" ]]; then
    spacer; green "$select is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid input format! Exiting..."
    exit 1
  fi
}

# Checks current selected dir
check_filepath()
{
  check="n"

  cd "$directory"
  current_dir="${PWD}/"  
 
  cyan "Current selected option: $select"
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

# COMBINE BOTH MKV AND MKV_FLAC INTO ONE FUNCTION

distribute()
{
  input_format=""

  if [[ "$select" == "1" || "$select" == "2" ]]; then
    input_format="mkv"
  elif [[ "$select" == "3" ]]; then
    input_format="mp4"
  elif [[ "$select" == "4" ]]; then
    input_format="webm"
  else
    spacer; red "ERROR: Unknown! Line 116, review ASAP!"
    exit 1
  fi

  find "$directory" -type f -iname "*.$input_format" >> "$m_filepaths"
  total_lines=$(wc -l < $m_filepaths)
  avg_load=$(($total_lines/$num_cores))
  declare -i counter_distribution=$total_lines

  if (( $total_lines < $num_cores )); then
    num_cores=$(($total_lines))
  fi

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

process()
{
  # Convert MKV to MP4 with defualt subtitles 
  function mkv_to_mp4_default()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -vcodec copy -acodec copy -scodec mov_text "${path/%flac/mp4}" 
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert MKV with FLAC -> MP4 with default subititles
  function mkv_to_mp4_flac()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -map 0 -c:v copy -c:a aac -c:s mov_text "${path/%flac/mp4}" 
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert MP4 -> MKV
  function mp4_to_mkv_default()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -vcodec copy -acodec copy "${path/%flac/mkv}" 
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  # Convert WEBM -> MKV
  function webm_to_mkv_default()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      ffmpeg -i "$path" -c copy "${path/%flac/mkv}"
      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  if [[ "$select" == "1" || "$select" == "2" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (mkv_to_mp4_default "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "3" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (mp4_to_mkv_default "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  elif [[ "$select" == "4" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (webm_to_mkv_default "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}") & disown
    done
  else
    spacer; red "ERROR: Unknown! Line 116, review ASAP!"
    exit 1
  fi

  pids=$(pgrep -P $$)
  read -n1 -r -p "Press any key to stop all background processes..."

  kill $pids
}

clear

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
         -d: Directory to format ( WARNING: Directory is recursive! )
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

  check_input
  check_output
  check_filepath

  rm "$m_filepaths"
}

main
