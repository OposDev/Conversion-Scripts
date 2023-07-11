#!/usr/bin/env bash

input_select=""
output_select=""
directory=""
declare -i num_cores
num_cores="$(nproc)"
major_range=()
minor_range=()
declare -i total_lines=0
declare -i avg_load=0
m_filepaths="m_filepaths.txt"
remove=false
script_dir=$(pwd)

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
    if [ -n "${2}" ]; then
    echo -e "\x1B[31m $($2) \x1B[0m"
    fi
}

function green(){
    echo -e "\x1B[32m $1 \x1B[0m"
    if [ -n "${2}" ]; then
    echo -e "\x1B[32m $($2) \x1B[0m"
    fi
}

function yellow(){
    echo -e "\x1B[33m $1 \x1B[0m"
    if [ -n "${2}" ]; then
    echo -e "\x1B[33m $($2) \x1B[0m"
    fi
}

function cyan(){
    echo -e "\x1B[36m $1 \x1B[0m"
    if [ -n "${2}" ]; then
    echo -e "\x1B[36m $($2) \x1B[0m"
    fi
}

# Checks inputs of user
check_input()
{
  spacer; yellow "CHECKING SELECTED INPUT..."
  if [[ $input_select == "1" || "$input_select" == "2" || "$input_select" == "3" ]]; then
    green " > $input_select is a valid format, continuing..."
  else
    red " X - ERROR: Invalid input format! Exiting..."
    exit
  fi
}

# Checks outputs of user
check_output()
{
  spacer; yellow "CHECKING SELECTED OUTPUT..."
  if [[ $output_select == "1" || "$output_select" == "2" || "$output_select" == "3" ]]; then
    green " > $output_select is a valid format, continuing..."
  else
    red " X - ERROR: Invalid input format! Exiting..."
    exit
  fi
}

# Checks current selected dir & display selected information
check_filepath()
{
  spacer;
  check="n"
  tmp_dir=$(cd "$directory" && pwd)

  if ! [[ -d "$tmp_dir" ]]; then
    red " X - Selected directory dooes not exist! Exiting..."
    exit 1
  fi
  
  if [[ "$remove" == true ]]; then
    yellow " - WARNING: Remove flag set to: $remove!"
  else
    green " > Remove flag set to: $remove!"
  fi

  cyan " ? Current selected input: $input_select"
  cyan " ? Current selected output: $output_select" 
  cyan " ? Selected file path: $tmp_dir"
  cyan " ? Is the information that is currently displayed, correct? y/n:"
  read  -n 1 -p "Input:" check; spacer
  
  if [[ $check == "n" || $check == "N" ]]; then
    spacer; yellow " - WARNING: User selected 'no'! Exiting..."
    exit
  elif [[ $check == "y" || $check == "Y" ]]; then
    spacer; yellow " - WARNING: User selected 'yes'! Starting format process!"
    cd "$script_dir" || exit 1
  else
    spacer; red " X - ERROR: Unknown input! Exiting..."
    exit
  fi
}

# Gathers files with selected format -> distributes load across system CPUs
distribute()
{
  input_format=""

  if [[ "$input_select" == "1" ]]; then
    input_format="png"
  elif [[ "$input_select" == "2" ]]; then
    input_format="jpg"
  elif [[ "$input_select" == "3" ]]; then
    input_format="jpeg"
  else
    spacer; red "ERROR: Unknown! Check distribute(), review ASAP!"
    exit 1
  fi

  # Finds postfix with captital letters -> converts to lowercase for processing
  find "$directory" -type f -print0 | while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    extension="${filename##*.}"
    filename="${filename%.*}"
    mv "${filepath}" "$(dirname "${filepath}")/${filename}.${extension,,}" &> /dev/null
  done

  # Store data for processing
  find "$directory" -type f -iname "*.$input_format" >> "$m_filepaths"
  total_lines=$(wc -l < $m_filepaths)
  avg_load=$((total_lines/num_cores))
  declare -i counter_distribution=$((total_lines))

  if (( total_lines < num_cores )); then
    num_cores=$((total_lines))
  fi

  # Logic for distributing
  for (( i=0; i<num_cores; i++ )); do
    if (( i == 0 )); then
      major_range+=("$counter_distribution")
    else
      tmp_lines=$((counter_distribution-1)); major_range+=("$tmp_lines")
    fi

    ((counter_distribution -= avg_load))

    if (( i == (num_cores-1) )); then
      minor_range+=(1)
      break
    fi
    
    minor_range+=("$counter_distribution")
  done
}

# Light multithreading with mogrify -> processes distributed data
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
      tmp_i=$((i-1))
      (convert "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}" "png") & disown
    done
  elif [[ "$output_select" == "2" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$((i-1))
      (convert "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}" "jpg") & disown
    done
  elif [[ "$output_select" == "3" ]]; then
    for i in $(seq 1 $num_cores)
    do
      tmp_i=$((i-1))
      (convert "${major_range[$tmp_i]}" "${minor_range[$tmp_i]}" "jpeg") & disown
    done
  else
    spacer; red "ERROR: Unknown! Line 116, review ASAP!"
    exit 1
  fi

  pids=$(pgrep -P $$)
  read -n1 -r -p "Press any key to stop all background processes..."

  kill "$pids"
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
yellow "STARTING PROGRAM..."

main()
{
  if (( num_cores < 1 )); then
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
