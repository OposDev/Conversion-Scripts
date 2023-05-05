#!/usr/bin/env bash

input_select=""
output_select=""
directory=""
declare -i num_cores="$(nproc)"
major_range=()
minor_range=()
declare -i total_lines=0
declare -i avg_load=0
m_filepaths="m_filepaths.txt"
remove=false
script_dir=`pwd`

spacer()
{
  echo ""
}

list_format()
{
  spacer
  cat << EOL
Available Options:
                    1 - png
                    2 - jpg
                    3 - jpeg
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
  spacer; yellow "Checking selected input..."
  if [[ $input_select == "1" || "$input_select" == "2" || "$input_select" == "3" ]]; then
    spacer; green "$input_select is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid input format! Exiting..."
    exit
  fi
}

# Checks outputs of user
check_output()
{
  spacer; yellow "Checking selected output..."
  if [[ $output_select == "1" || "$output_select" == "2" || "$output_select" == "3" ]]; then
    spacer; green "$output_select is a valid format, continuing..."
  else
    spacer; red "ERROR: Invalid input format! Exiting..."
    exit
  fi
}

# Checks current selected dir & display selected information
check_filepath()
{
  check="n"
  tmp_dir=$(cd $directory && pwd)

  if ! [[ -d "$tmp_dir" ]]; then
    spacer; red "Selected directory dooes not exist! Exiting..."
    exit 1
  fi
  
  if [[ "$remove" == true ]]; then
    spacer; red "WARNING: Remove flag set to: $remove!"
  else
    spacer; green "Remove flag set to: $remove!"
  fi

  spacer; cyan "Current selected input: $input_select"
  spacer; cyan "Current selected output: $output_select" 
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
  in_bad_postfix=""
  output_format=""
  out_bad_postfix=""

  if [[ "$input_select" == "1" ]]; then
    input_format="png"
    in_bad_postfix="PNG"
  elif [[ "$input_select" == "2" ]]; then
    input_format="jpg"
    in_bad_postfix="JPG"
  elif [[ "$input_select" == "3" ]]; then
    input_format="jpeg"
    in_bad_postfix="JPEG"
  else
    spacer; red "ERROR: Unknown! Check distribute(), review ASAP!"
    exit 1
  fi
  
  if [[ "$output_select" == "1" ]]; then
    output_format="png"
    out_bad_postfix="PNG"
  elif [[ "$output_select" == "2" ]]; then
    output_format="jpg"
    out_bad_postfix="JPG"
  elif [[ "$output_select" == "3" ]]; then
    output_format="jpeg"
    out_bad_postfix="JPEG"
  else
    spacer; red "ERROR: Unknown! Check distribute(), review ASAP!"
    exit 1
  fi

  # Finds postfix with captital letters -> converts to lowercase for processing
  find "$directory" -type f -print0 | while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    extension="${filename##*.}"
    filename="${filename%.*}"
    mv "${filepath}" "$(dirname ${filepath})/${filename}.${extension,,}" &> /dev/null
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

# Light multithreading with mogrify -> processes distributioned data
process()
{
  # Convert files
  function convert()
  {
    for (( j=$2; j<=$1; j++ )); do
      path=$(sed -n "${j}p" "$m_filepaths")
      mogrify -format "$3" "$path"

      if [[ "$remove" == true ]]; then
        rm "$path"
      fi
    done
  }

  if [[ "$output_select" == "1" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (convert "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}" "png") & disown
    done
  elif [[ "$output_select" == "2" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (convert "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}" "jpg") & disown
    done
  elif [[ "$output_select" == "3" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$(($i-1))
      (convert "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}" "jpeg") & disown
    done
  else
    spacer; red "ERROR: Unknown! Line 116, review ASAP!"
    exit 1
  fi

  pids=$(pgrep -P $$)
  read -n1 -r -p "Press any key to stop all background processes..."

  kill $pids
}

while getopts ":i:o:d:lrh" arg
do
  case "$arg" in
    "i")
        input_select=$OPTARG
        ;;
    "o")
        output_select=$OPTARG
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
         -i: Select input processing option
         -o: Select output processing option
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
  
  check_input
  check_output
  check_filepath
  distribute
  process

  rm "$m_filepaths"
}

main
